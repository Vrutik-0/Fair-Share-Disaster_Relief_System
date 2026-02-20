import pandas as pd
from xgboost import XGBRegressor
from db import get_db_connection

minDays = 9

def fetch_daily_demand():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT
        DATE(request_date) AS req_date, item_type,
        SUM(quantity_needed) AS total_needed FROM requests
        GROUP BY DATE(request_date), item_type ORDER BY req_date
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    df = pd.DataFrame(rows, columns=["date", "item_type", "total_needed"])
    df["date"] = pd.to_datetime(df["date"])
    return df


def fetch_camp_stats():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT
            COUNT(*) AS num_camps,
            COALESCE(SUM(total_population), 0) AS total_pop,
            COALESCE(SUM(injured_population), 0) AS total_injured,
            COALESCE(AVG(urgency_score), 0) AS avg_urgency FROM camps
    """)
    row = cur.fetchone()
    cur.close()
    conn.close()
    return {
        "num_camps": row[0],
        "total_pop": row[1],
        "total_injured": row[2],
        "avg_urgency": float(row[3]),
    }


def build_features(series):
    df = series.to_frame(name="demand")
    df["day_of_week"] = df.index.dayofweek
    first_day = df.index.min()
    df["day_number"] = (df.index - first_day).days

    for lag in [1, 2, 3]:
        df[f"lag_{lag}"] = df["demand"].shift(lag)

    df["roll_3"] = df["demand"].rolling(3, min_periods=1).mean()
    df["roll_5"] = df["demand"].rolling(5, min_periods=1).mean()
    df["roll_7"] = df["demand"].rolling(7, min_periods=1).mean()

    df = df.dropna()

    y = df["demand"].values
    X = df.drop(columns=["demand"])
    return X, y


def predict_next_day():
    raw = fetch_daily_demand()

    if raw.empty:
        return {
            "ok": False,
            "message": "No request data found. Cannot predict.",
            "days_of_data": 0,
        }

    unique_days = raw["date"].nunique()

    if unique_days <  minDays:
        return {
            "ok": False,
            "message": (
                f"Insufficient data to predict. "
                f"Need at least { minDays} days of request history, "
                f"but only {unique_days} day(s) found."
            ),
            "days_of_data": unique_days,
        }

    camp_stats = fetch_camp_stats()

    # Date range for filling gaps
    all_dates = pd.date_range(raw["date"].min(), raw["date"].max(), freq="D")

    item_types = raw["item_type"].unique()
    predictions = []

    for itype in item_types:
        sub = raw[raw["item_type"] == itype].set_index("date")["total_needed"]
        # Reindex to fill missing days with 0
        sub = sub.reindex(all_dates, fill_value=0)
        sub.index.name = "date"

        X, y = build_features(sub)

        if len(X) < 3:
            # Not enough rows
            predictions.append({
                "item_type": itype,
                "predicted_qty": 0,
                "trend": "unknown",
            })
            continue

        model = XGBRegressor(
            n_estimators=100,
            max_depth=4,
            learning_rate=0.1,
            objective="reg:squarederror",
            random_state=42,
            verbosity=0,
        )
        model.fit(X, y)

        # Build feature row for tomorrow
        last_date = sub.index.max()
        tomorrow = last_date + pd.Timedelta(days=1)

        feat = {
            "day_of_week": tomorrow.dayofweek,
            "day_number": (tomorrow - sub.index.min()).days,
            "lag_1": sub.iloc[-1],
            "lag_2": sub.iloc[-2],
            "lag_3": sub.iloc[-3],
            "roll_3": sub.iloc[-3:].mean(),
            "roll_5": sub.iloc[-5:].mean(),
            "roll_7": sub.iloc[-7:].mean(),
        }
        X_pred = pd.DataFrame([feat])

        pred = model.predict(X_pred)[0]
        pred = max(0, round(float(pred)))

        # Simple trend: compare last 3-day avg vs prior 3
        recent_avg = sub.iloc[-3:].mean()
        prior_avg = sub.iloc[-6:-3].mean() if len(sub) >= 6 else recent_avg
        if recent_avg > prior_avg * 1.15:
            trend = "increasing"
        elif recent_avg < prior_avg * 0.85:
            trend = "decreasing"
        else:
            trend = "stable"

        predictions.append({
            "item_type": itype,
            "predicted_qty": pred,
            "trend": trend,
        })

    return {
        "ok": True,
        "predictions": predictions,
        "stats": camp_stats,
        "days_of_data": unique_days,
    }