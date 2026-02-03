from flask import Flask, render_template, request, redirect, url_for ,session
from werkzeug.security import generate_password_hash, check_password_hash
from db import get_db_connection
import os

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY")

@app.route("/")
def home():
    return redirect(url_for("login"))

#Signup
@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        name = request.form["name"]
        email = request.form["email"]
        phone = request.form["phone"]
        role = request.form["role"]
        password = generate_password_hash(request.form["password"])

        conn = get_db_connection()
        cur = conn.cursor()

        cur.execute(
            """
            INSERT INTO users (name, email, phone, role, password)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (name, email, phone, role, password)
        )

        conn.commit()
        cur.close()
        conn.close()

        return redirect(url_for("login"))

    return render_template("signup.html")

#Login
@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form["email"]
        password = request.form["password"]

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id, password, role, name FROM users WHERE email = %s", (email,))
        user = cur.fetchone()
        cur.close()
        conn.close()

        if user and check_password_hash(user[1], password):
            session["user_id"] = user[0]
            session["role"] = user[2]
            session["name"] = user[3]

            if user[2] == "admin":
                return redirect(url_for("adminBoard"))
            elif user[2] == "camp_manager":
                return redirect(url_for("campBoard"))
            elif user[2] == "driver":
                return redirect(url_for("driverBoard"))
            else:
                return "Invalid role"

        return "Invalid credentials"

    return render_template("login.html")

@app.route("/admin/dashboard")
def adminBoard():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
        COUNT(*) AS total_camps,
        COUNT(*) FILTER (WHERE urgency_score >= 0.7) AS critical_camps,
        COUNT(*) FILTER (WHERE urgency_score >= 0.4 AND urgency_score < 0.7) AS moderate_camps,
        ROUND(AVG(urgency_score)::numeric, 2) AS avg_urgency
    FROM camps
    """)

    stats = cur.fetchone()
    cur.close()
    conn.close()

    return render_template(
        "dashboard/admin.html",
        total_camps=stats[0],
        critical_camps=stats[1],
        moderate_camps=stats[2],
        avg_urgency=stats[3] or 0
    )


@app.route("/camp/dashboard")
def campBoard():
    if session.get("role") != "camp_manager":
        return redirect(url_for("login"))
    return render_template("dashboard/camp_manager.html")


@app.route("/driver/dashboard")
def driverBoard():
    if session.get("role") != "driver":
        return redirect(url_for("login"))
    return render_template("dashboard/driver.html")

@app.route("/camps")
def view_camps():
    if "role" not in session:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT 
            c.camp_id,
            c.name,
            c.cord_x,
            c.cord_y,
            c.total_population,
            c.injured_population,
            c.urgency_score,
            c.status,
            c.created_at,
            u.id AS manager_id,
            u.name AS manager_name
        FROM camps c
        LEFT JOIN users u ON c.manager_id = u.id
        ORDER BY c.urgency_score DESC
    """)

    camps = cur.fetchall()
    cur.close()
    conn.close()

    return render_template("Camp/view_camps.html", camps=camps)

#Add Camp by Camp Managers
@app.route("/camp/add", methods=["GET", "POST"])
def add_camp():
    if session.get("role") != "camp_manager":
        return redirect(url_for("login"))

    if request.method == "POST":
        name = request.form["name"]
        x = int(request.form["x"])
        y = int(request.form["y"])
        total_pop = int(request.form["total_population"])
        injured_pop = int(request.form["injured_population"])

        urgency = calculate_urgency(total_pop, injured_pop)

        conn = get_db_connection()
        cur = conn.cursor()

        try:
            cur.execute(
                """
                INSERT INTO camps
                (name, cord_x, cord_y,
                 total_population, injured_population,
                 urgency_score, manager_id)
                VALUES (%s,%s,%s,%s,%s,%s,%s)
                """,
                (
                    name, x, y,
                    total_pop, injured_pop,
                    urgency, session["user_id"]
                )
            )
            conn.commit()

        except Exception as e:
            conn.rollback()
            return "Camp name or coordinates already exist"

        finally:
            cur.close()
            conn.close()

        return redirect(url_for("campBoard"))

    return render_template("Camp/add_camp.html")

@app.route("/api/camps")
def api_camps():
    if "role" not in session:
        return {"error": "unauthorized"}, 401

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT name, cord_x, cord_y, urgency_score
        FROM camps
    """)

    rows = cur.fetchall()
    cur.close()
    conn.close()

    camps = []
    for r in rows:
        camps.append({
            "name": r[0],
            "lat": r[1],   # cord_x → latitude
            "lng": r[2],   # cord_y → longitude
            "urgency": r[3]
        })

    return {"camps": camps}

@app.route("/warehouse")
def warehouse_view():
    if session.get("role") not in ["admin", "camp_manager"]:
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT item_name, item_type, quantity, unit, low_stock_threshold
        FROM warehouse_inventory
        ORDER BY item_name
    """)

    items = cur.fetchall()
    cur.close()
    conn.close()

    return render_template("warehouse/view_inventory.html", items=items)


@app.route("/warehouse/add", methods=["GET", "POST"])
def add_warehouse_stock():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    if request.method == "POST":
        item_type = request.form["item_type"]
        unit = request.form["unit"]
        quantity = int(request.form["quantity"])
        threshold = int(request.form["low_stock_threshold"])

        item_name = request.form.get("item_name")
        if item_name == "":
            item_name = None

        conn = get_db_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                INSERT INTO warehouse_inventory
                (item_name, item_type, quantity, unit, low_stock_threshold)
                VALUES (%s, %s, %s, %s, %s)
                ON CONFLICT (item_type, unit)
                DO UPDATE SET
                    quantity = warehouse_inventory.quantity + EXCLUDED.quantity,
                    updated_at = CURRENT_TIMESTAMP
            """, (item_name, item_type, quantity, unit, threshold))

            conn.commit()

        except Exception as e:
            conn.rollback()
            print("WAREHOUSE ERROR:", e)
            return str(e)

        finally:
            cur.close()
            conn.close()

        return redirect(url_for("warehouse_view"))

    return render_template("warehouse/add_inventory.html")

@app.route("/requests/new", methods=["GET", "POST"])
def create_request():
    if session.get("role") != "camp_manager":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    # get camps managed by this manager
    cur.execute("""
        SELECT camp_id, name, urgency_score
        FROM camps
        WHERE manager_id = %s
    """, (session["user_id"],))

    camps = cur.fetchall()

    if request.method == "POST":
        camp_id = request.form["camp_id"]
        item_type = request.form["item_type"]
        quantity = int(request.form["quantity_needed"])
        priority_override = request.form.get("priority")

        # get urgency score
        cur.execute(
            "SELECT urgency_score FROM camps WHERE camp_id = %s",
            (camp_id,)
        )
        urgency = cur.fetchone()[0]

        # auto priority
        if urgency >= 0.75:
            auto_priority = "critical"
        elif urgency >= 0.5:
            auto_priority = "high"
        elif urgency >= 0.3:
            auto_priority = "medium"
        else:
            auto_priority = "low"

        priority = priority_override if priority_override else auto_priority

        cur.execute("""
            INSERT INTO requests
            (camp_id, item_type, quantity_needed, priority)
            VALUES (%s, %s, %s, %s)
        """, (camp_id, item_type, quantity, priority))

        conn.commit()
        cur.close()
        conn.close()

        return redirect(url_for("campBoard"))

    cur.close()
    conn.close()
    return render_template("requests/create_request.html", camps=camps)


def calculate_urgency(total_population, injured_population):
    if total_population == 0:
        return 0.0

    score = (
        (injured_population / total_population) * 0.7
        + (total_population / 1000) * 0.3
    )

    return round(min(score, 1.0), 2)

#Logout
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(debug=True)
