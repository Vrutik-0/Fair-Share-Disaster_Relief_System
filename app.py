from dataclasses import field
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

@app.route("/admin/requests")
def admin_requests():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    #Fetch requests
    cur.execute("""
        SELECT
            r.request_id,
            c.name AS camp_name,
            r.item_type,
            r.quantity_needed,
            r.fulfilled_quantity,
            r.priority
        FROM requests r
        JOIN camps c ON r.camp_id = c.camp_id
        WHERE r.status IN ('pending', 'partially_approved')
        ORDER BY
            CASE r.priority
                WHEN 'critical' THEN 1
                WHEN 'high' THEN 2
                WHEN 'medium' THEN 3
                ELSE 4
            END,
            r.request_date
    """)

    rows = cur.fetchall()

    # Convert to list of dicts
    requests = []
    for r in rows:
        requests.append({
            "request_id": r[0],
            "camp_name": r[1],
            "item_type": r[2],
            "quantity_needed": r[3],
            "fulfilled_quantity": r[4],
            "priority": r[5],
            "suggested_qty": 0 
        })

    PRIORITY_WEIGHT = {
        "critical": 4,
        "high": 3,
        "medium": 2,
        "low": 1
    }

    # group by item type
    from collections import defaultdict
    grouped = defaultdict(list)

    for r in requests:
        grouped[r["item_type"]].append(r)

    for item_type, reqs in grouped.items():

        # get warehouse stock for this item
        cur.execute(
            "SELECT quantity FROM warehouse_inventory WHERE item_type = %s",
            (item_type,)
        )
        stock_row = cur.fetchone()
        stock = stock_row[0] if stock_row else 0

        # compute total weighted demand
        total_weight = 0
        for r in reqs:
            remaining = r["quantity_needed"] - r["fulfilled_quantity"]
            total_weight += PRIORITY_WEIGHT[r["priority"]] * remaining

        # compute allocation for each request
        for r in reqs:
            remaining = r["quantity_needed"] - r["fulfilled_quantity"]
            if total_weight == 0 or remaining <= 0:
                r["suggested_qty"] = 0
            else:
                weight = PRIORITY_WEIGHT[r["priority"]] * remaining
                suggested = int(stock * (weight / total_weight))
                r["suggested_qty"] = min(suggested, remaining)

    cur.close()
    conn.close()

    return render_template(
        "requests/admin_requests.html",
        requests=requests
    )


@app.route("/admin/requests/approve", methods=["POST"])
def approve_request():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    request_id = int(request.form["request_id"])
    approve_qty = int(request.form["allocated_quantity"])

    conn = get_db_connection()
    cur = conn.cursor()

    # get request info
    cur.execute("""
        SELECT item_type, quantity_needed, fulfilled_quantity
        FROM requests
        WHERE request_id = %s
    """, (request_id,))

    item_type, needed, fulfilled = cur.fetchone()
    remaining = needed - fulfilled

    # get warehouse
    cur.execute("""
        SELECT quantity
        FROM warehouse_inventory
        WHERE item_type = %s
    """, (item_type,))

    stock = cur.fetchone()[0]

    alloc = min(approve_qty, remaining, stock)

    if alloc <= 0:
        cur.close()
        conn.close()
        return redirect(url_for("admin_requests"))

    # insert allocation
    cur.execute("""
        INSERT INTO allocations (request_id, allocated_quantity)
        VALUES (%s, %s)
    """, (request_id, alloc))

    # update warehouse
    cur.execute("""
        UPDATE warehouse_inventory
        SET quantity = quantity - %s,
            updated_at = CURRENT_TIMESTAMP
        WHERE item_type = %s
    """, (alloc, item_type))

    # update request
    new_fulfilled = fulfilled + alloc
    new_status = (
        "approved" if new_fulfilled >= needed else "partially_approved"
    )

    cur.execute("""
        UPDATE requests
        SET fulfilled_quantity = %s,
            status = %s
        WHERE request_id = %s
    """, (new_fulfilled, new_status, request_id))

    conn.commit()
    cur.close()
    conn.close()

    return redirect(url_for("admin_requests"))

@app.route("/admin/requests/auto-approve", methods=["POST"])
def auto_approve_request():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    request_id = int(request.form["request_id"])

    conn = get_db_connection()
    cur = conn.cursor()

    auto_approve_logic(request_id, cur)

    conn.commit()
    cur.close()
    conn.close()

    return redirect(url_for("admin_requests"))

@app.route("/admin/requests/discard", methods=["POST"])
def discard_request():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    raw_id = request.form.get("request_id", "").strip()
    note = request.form.get("admin_note", "").strip()

    if not raw_id.isdigit() or not note:
        return redirect(url_for("admin_requests"))

    request_id = int(raw_id)

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        UPDATE requests
        SET status = 'discarded',
            admin_note = %s,
            last_updated = CURRENT_TIMESTAMP
        WHERE request_id = %s
    """, (note, request_id))

    conn.commit()
    cur.close()
    conn.close()

    return redirect(url_for("admin_requests"))


@app.route("/admin/requests/approve-all", methods=["POST"])
def approve_all_requests():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT request_id, item_type, quantity_needed, fulfilled_quantity
        FROM requests
        WHERE status IN ('pending', 'partially_approved')
    """)

    requests = cur.fetchall()

    for r in requests:
        request_id, item_type, needed, fulfilled = r
        field = f"alloc_{request_id}"
        raw_value = request.form.get(field, "").strip()
        alloc = int(raw_value) if raw_value.isdigit() else 0


        if alloc <= 0:
            continue

        # check warehouse stock
        cur.execute(
            "SELECT quantity FROM warehouse_inventory WHERE item_type=%s",
            (item_type,)
        )
        stock = cur.fetchone()[0]

        alloc = min(alloc, stock, needed - fulfilled)
        if alloc <= 0:
            continue

        # allocation record
        cur.execute("""
            INSERT INTO allocations (request_id, allocated_quantity)
            VALUES (%s, %s)
        """, (request_id, alloc))

        # update warehouse
        cur.execute("""
            UPDATE warehouse_inventory
            SET quantity = quantity - %s
            WHERE item_type = %s
        """, (alloc, item_type))

        new_fulfilled = fulfilled + alloc
        new_status = "approved" if new_fulfilled >= needed else "partially_approved"

        cur.execute("""
            UPDATE requests
            SET fulfilled_quantity=%s,
                status=%s,
                admin_note='Approved in bulk allocation',
                last_updated=CURRENT_TIMESTAMP
            WHERE request_id=%s
        """, (new_fulfilled, new_status, request_id))

    conn.commit()
    cur.close()
    conn.close()

    return redirect(url_for("admin_requests"))

@app.route("/requests/mine")
def view_my_requests():
    if session.get("role") != "camp_manager":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
    SELECT
        r.item_type,
        r.quantity_needed,
        r.fulfilled_quantity,
        r.status,
        r.admin_note
        FROM requests r
        JOIN camps c ON r.camp_id = c.camp_id
        WHERE c.manager_id = %s
        ORDER BY r.request_date DESC
        """, (session["user_id"],))


    data = cur.fetchall()
    cur.close()
    conn.close()

    return render_template("requests/my_requests.html", requests=data)

def auto_approve_logic(request_id, cur):
    # get request info
    cur.execute("""
        SELECT item_type, quantity_needed, fulfilled_quantity, status
        FROM requests
        WHERE request_id = %s
    """, (request_id,))

    row = cur.fetchone()
    if not row:
        return

    item_type, needed, fulfilled, current_status = row
    remaining = needed - fulfilled

    # get warehouse stock
    cur.execute("""
        SELECT quantity
        FROM warehouse_inventory
        WHERE item_type = %s
    """, (item_type,))

    stock_row = cur.fetchone()
    stock = stock_row[0] if stock_row else 0

    # calculate allocation
    alloc = min(stock, remaining)

    # Empty Stock
    if alloc <= 0:
        cur.execute("""
            UPDATE requests
            SET status = 'pending',
                admin_note = 'Insufficient warehouse stock',
                last_updated = CURRENT_TIMESTAMP
            WHERE request_id = %s
        """, (request_id,))
        return
    
    #Parrtial or Full

    # record allocation
    cur.execute("""
        INSERT INTO allocations (request_id, allocated_quantity)
        VALUES (%s, %s)
    """, (request_id, alloc))

    # update warehouse stock
    cur.execute("""
        UPDATE warehouse_inventory
        SET quantity = quantity - %s,
            updated_at = CURRENT_TIMESTAMP
        WHERE item_type = %s
    """, (alloc, item_type))

    new_fulfilled = fulfilled + alloc

    # determine correct status
    if new_fulfilled >= needed:
        new_status = "approved"
        note = "Request fully approved"
    else:
        new_status = "partially_approved"
        note = "Request partially approved due to limited stock"

    # update request
    cur.execute("""
        UPDATE requests
        SET fulfilled_quantity = %s,
            status = %s,
            admin_note = %s,
            last_updated = CURRENT_TIMESTAMP
        WHERE request_id = %s
    """, (new_fulfilled, new_status, note, request_id))


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
