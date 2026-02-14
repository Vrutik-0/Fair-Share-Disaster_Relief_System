from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from db import get_db_connection
import os
from collections import defaultdict
from Algo.clustering import cluster_camps
from Algo.priority import rank_camps_greedy
from Algo.knapsack import knapsack
from Algo.routes import greedy_route
from Algo.model import predict_next_day

#NGO Base Coord
DEPOT_X = 500
DEPOT_Y = 190

def auto_approve_logic(request_id, cur):

    # get request info - what , how much , etc
    cur.execute("""
        SELECT item_type, quantity_needed, fulfilled_quantity, status
        FROM requests WHERE request_id = %s
        """, (request_id,))

    row = cur.fetchone()
    if not row:
        return

    item_type, needed, fulfilled, current_status = row
    
    # Don't process if already approved, delivered, or discarded
    if current_status not in ('pending', 'partially_approved'):
        return
    
    remaining = needed - fulfilled

    # get warehouse stock
    cur.execute("""
        SELECT quantity FROM warehouse_inventory WHERE item_type = %s
        """, (item_type,))

    stock_row = cur.fetchone()
    stock = stock_row[0] if stock_row else 0

    # allocation
    alloc = min(stock, remaining)

    # Empty Stock
    if alloc <= 0:
        cur.execute("""
            UPDATE requests
            SET status = 'pending', admin_note = 'Insufficient stock',
            last_updated = CURRENT_TIMESTAMP WHERE request_id = %s
            """, (request_id,))
        return
    
    # Partial or Full

    # record allocation
    cur.execute("""
        INSERT INTO allocations (request_id, allocated_quantity) VALUES (%s, %s)
        """, (request_id, alloc))

    # update warehouse stock
    cur.execute("""
        UPDATE warehouse_inventory SET quantity = quantity - %s,
        updated_at = CURRENT_TIMESTAMP WHERE item_type = %s
        """, (alloc, item_type))

    new_fulfilled = fulfilled + alloc

    # determine correct status
    if new_fulfilled >= needed:
        new_status = "approved"
        msg = "Request fully approved"
    else:
        new_status = "partially_approved"
        msg = "Request partially approved due to limited stock"

    # update request
    cur.execute("""
        UPDATE requests
        SET fulfilled_quantity = %s,
        status = %s,
        admin_note = %s,
        last_updated = CURRENT_TIMESTAMP
        WHERE request_id = %s
    """, (new_fulfilled, new_status, msg, request_id))


def calculate_urgency(total_population, injured_population):
    if total_population == 0:
        return 0.0

    score = (
        (injured_population / total_population) * 0.7
        + (total_population / 1000) * 0.3 )

    return round(min(score, 1.0), 2)

def execution_locked():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT is_execution_live FROM system_state WHERE id = 1")
    chk = cur.fetchone()[0]
    cur.close()
    conn.close()
    return chk

#Insert a notification for a specific user.
def notify(user_id, message, level='info', cur=None):
    
    if cur:
        cur.execute(
            "INSERT INTO notifications (user_id, message, level) VALUES (%s, %s, %s)",
            (user_id, message, level)
        )
    else:
        conn = get_db_connection()
        c = conn.cursor()
        c.execute(
            "INSERT INTO notifications (user_id, message, level) VALUES (%s, %s, %s)",
            (user_id, message, level)
        )
        conn.commit()
        c.close()
        conn.close()

# Notification for all users at same level/role
def notify_role(role, message, level='info', cur=None):
    if cur:
        cur.execute("SELECT id FROM users WHERE role = %s", (role,))
        for row in cur.fetchall():
            cur.execute(
                "INSERT INTO notifications (user_id, message, level) VALUES (%s, %s, %s)",
                (row[0], message, level)
            )
    else:
        conn = get_db_connection()
        c = conn.cursor()
        c.execute("SELECT id FROM users WHERE role = %s", (role,))
        for row in c.fetchall():
            c.execute(
                "INSERT INTO notifications (user_id, message, level) VALUES (%s, %s, %s)",
                (row[0], message, level)
            )

        conn.commit()
        c.close()
        conn.close()

# Check for low stock items and notify admin
def check_low_stock(cur):
    cur.execute("""
        SELECT item_type, quantity, low_stock_threshold
        FROM warehouse_inventory
        WHERE quantity <= low_stock_threshold AND low_stock_threshold > 0
    """)
    low_items = cur.fetchall()
    for item_type, qty, threshold in low_items:
        notify_role('admin', f" Low stock: {item_type} is at {qty} (threshold: {threshold})", 'danger', cur)


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

        try:
            cur.execute(
                """
                INSERT INTO users (name, email, phone, role, password)
                VALUES (%s, %s, %s, %s, %s)
                """,(name, email, phone, role, password)
            )

            conn.commit()
            return redirect(url_for("login", msg="Account created successfully! Please login."))
            
        except Exception as e:
            conn.rollback()
            flash(f"Registration failed: {str(e)}", "error")
            return render_template("signup.html")
            
        finally:
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
        
        try:
            cur.execute("SELECT id, password, role, name FROM users WHERE email = %s", (email,))
            user = cur.fetchone()
            
            if user and check_password_hash(user[1], password):
                session["user_id"] = user[0]
                session["role"] = user[2]
                session["name"] = user[3]

                if user[2] == "admin":
                    return redirect(url_for("adminBoard"))
                elif user[2] == "camp_manager":
                    return redirect(url_for("campBoard"))
                elif user[2] == "driver":
                    return redirect(url_for("driver_dashboard"))
                else:
                    flash("Invalid role", "error")
                    return redirect(url_for("login"))
            
            return redirect(url_for("login", error="Invalid email or password"))
            
        except Exception as e:
            return redirect(url_for("login", error=f"Login error: {str(e)}"))
            
        finally:
            cur.close()
            conn.close()

    error = request.args.get("error")
    msg = request.args.get("msg")
    return render_template("login.html", error=error, msg=msg)

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
        ROUND(AVG(urgency_score)::numeric, 2) AS avg_urgency FROM camps
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

# Provide camp data for map visualizations
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

    #dicts to JSON
    camps = []
    for r in rows:
        camps.append({
            "name": r[0],
            "x": r[1],   # x-coordinate
            "y": r[2],   # y-coordinate  
            "lat": r[2], # lat = y (vertical) - converted to real coords on frontend
            "lng": r[1], # lng = x (horizontal) - converted to real coords on frontend
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
        FROM warehouse_inventory ORDER BY item_name
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
        item_name = request.form.get("item_name", "").strip() or None
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
            (camp_id, item_type, item_name, quantity_needed, priority)
            VALUES (%s, %s, %s, %s, %s)
        """, (camp_id, item_type, item_name, quantity, priority))

        # Get camp name for notification
        cur.execute("SELECT name FROM camps WHERE camp_id = %s", (camp_id,))
        camp_name = cur.fetchone()[0]
        notify_role('admin', f" New {priority} request: {quantity} {item_type} from {camp_name}", 'info', cur)

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
            r.priority,
            r.item_name
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
    pending_reqs = []
    for r in rows:
        display_type = r[2]
        if r[2] == 'other' and r[6]:
            display_type = f"other ({r[6]})"
        pending_reqs.append({
            "request_id": r[0],
            "camp_name": r[1],
            "item_type": display_type,
            "raw_item_type": r[2],
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
    grouped = defaultdict(list)

    for r in pending_reqs:
        grouped[r["raw_item_type"]].append(r)

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

        # compute allocation using largest-remainder method
        # (avoids int() truncation losing stock when individual shares < 1)
        alloc_data = []
        for r in reqs:
            remaining = r["quantity_needed"] - r["fulfilled_quantity"]
            if total_weight == 0 or remaining <= 0 or stock <= 0:
                alloc_data.append((r, 0, 0.0, remaining))
            else:
                weight = PRIORITY_WEIGHT[r["priority"]] * remaining
                exact = stock * (weight / total_weight)
                floor_val = int(exact)
                alloc_data.append((r, floor_val, exact - floor_val, remaining))

        total_floor = sum(a[1] for a in alloc_data)
        leftover = stock - total_floor

        # sort by fractional part descending to distribute leftovers
        alloc_data.sort(key=lambda x: x[2], reverse=True)

        for i, (r, floor_val, frac, remaining) in enumerate(alloc_data):
            if i < leftover and remaining > floor_val:
                r["suggested_qty"] = min(floor_val + 1, remaining)
            else:
                r["suggested_qty"] = min(floor_val, remaining)

    cur.close()
    conn.close()

    return render_template(
        "requests/admin_requests.html",
        requests=pending_reqs
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

    # Notify the camp manager who owns this request
    cur.execute("""
        SELECT c.manager_id, c.name, r.item_type
        FROM requests r JOIN camps c ON r.camp_id = c.camp_id
        WHERE r.request_id = %s
    """, (request_id,))
    row = cur.fetchone()
    if row and row[0]:
        if new_status == 'approved':
            notify(row[0], f"Request fully approved: {alloc} {row[2]} for {row[1]}", 'success', cur)
        else:
            notify(row[0], f"Request partially approved: {alloc}/{needed} {row[2]} for {row[1]}", 'warning', cur)
    check_low_stock(cur)

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

    print("DISCARD FORM DATA:", request.form)

    raw_id = request.form.get("request_id", "").strip()
    msg = request.form.get("admin_note", "").strip()

    if not raw_id.isdigit() or not msg:
        print("INVALID DISCARD INPUT")
        return redirect(url_for("admin_requests"))

    request_id = int(raw_id)

    conn = get_db_connection()
    cur = conn.cursor()

    # Get camp info for notification before discarding
    cur.execute("""
        SELECT c.manager_id, c.name, r.item_type, r.quantity_needed
        FROM requests r JOIN camps c ON r.camp_id = c.camp_id
        WHERE r.request_id = %s
    """, (request_id,))
    info = cur.fetchone()

    cur.execute("""
        UPDATE requests
        SET status = 'discarded',
            admin_note = %s,
            last_updated = CURRENT_TIMESTAMP
        WHERE request_id = %s
    """, (msg, request_id))

    # Notify camp manager about discard
    if info and info[0]:
        notify(info[0], f"Request discarded: {info[3]} {info[2]} for {info[1]} — Reason: {msg}", 'danger', cur)

    conn.commit()
    cur.close()
    conn.close()

    print("REQUEST DISCARDED:", request_id)

    return redirect(url_for("admin_requests"))



@app.route("/admin/requests/approve-all", methods=["POST"])
def approve_all_requests():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    print("APPROVE ALL - Form data:", dict(request.form))

    conn = get_db_connection()
    cur = conn.cursor()

    # Get all pending/partially approved requests
    cur.execute("""
        SELECT request_id, item_type, quantity_needed, fulfilled_quantity
        FROM requests
        WHERE status IN ('pending', 'partially_approved')
    """)

    pending_requests = cur.fetchall()
    
    approved_count = 0
    total_allocated = 0

    # Pre-fetch all warehouse stock into memory for accurate tracking
    cur.execute("SELECT item_type, quantity FROM warehouse_inventory")
    stock_tracker = {row[0]: row[1] for row in cur.fetchall()}

    for r in pending_requests:
        request_id, item_type, needed, fulfilled = r
        field = f"alloc_{request_id}"
        raw_value = request.form.get(field, "0").strip()

        # Parse allocation amount - handle empty or non-numeric values
        try:
            alloc = int(raw_value) if raw_value else 0
        except ValueError:
            alloc = 0

        if alloc <= 0:
            continue

        # Use tracked stock (reflects earlier allocations in this batch)
        stock = stock_tracker.get(item_type, 0)

        # Calculate actual allocation (limited by stock and remaining need)
        remaining = needed - fulfilled
        actual_alloc = min(alloc, stock, remaining)
        
        if actual_alloc <= 0:
            continue

        # Create allocation record
        cur.execute("""
            INSERT INTO allocations (request_id, allocated_quantity)
            VALUES (%s, %s)
        """, (request_id, actual_alloc))

        # Update warehouse stock
        cur.execute("""
            UPDATE warehouse_inventory
            SET quantity = quantity - %s,
                updated_at = CURRENT_TIMESTAMP
            WHERE item_type = %s
        """, (actual_alloc, item_type))

        # Track stock locally for subsequent iterations
        stock_tracker[item_type] = stock - actual_alloc

        # Update request status
        new_fulfilled = fulfilled + actual_alloc
        new_status = "approved" if new_fulfilled >= needed else "partially_approved"

        cur.execute("""
            UPDATE requests
            SET fulfilled_quantity = %s,
                status = %s,
                admin_note = 'Approved in bulk allocation',
                last_updated = CURRENT_TIMESTAMP
            WHERE request_id = %s
        """, (new_fulfilled, new_status, request_id))
        
        # Notify camp manager about approval
        cur.execute("""
            SELECT c.manager_id, c.name
            FROM requests r JOIN camps c ON r.camp_id = c.camp_id
            WHERE r.request_id = %s
        """, (request_id,))
        mgr_row = cur.fetchone()
        if mgr_row and mgr_row[0]:
            if new_status == 'approved':
                notify(mgr_row[0], f"Request fully approved: {actual_alloc} {item_type} for {mgr_row[1]}", 'success', cur)
            else:
                notify(mgr_row[0], f" Request partially approved: {actual_alloc}/{needed} {item_type} for {mgr_row[1]}", 'warning', cur)

        print(f"    ALLOCATED: request_id={request_id}, qty={actual_alloc}, status={new_status}")
        approved_count += 1
        total_allocated += actual_alloc

    check_low_stock(cur)
    conn.commit()
    cur.close()
    conn.close()


    if approved_count > 0:
        flash(f"Successfully approved {approved_count} requests (total: {total_allocated} units)", "success")
    else:
        flash("No requests were approved. Check quantities and stock.", "warning")

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
        r.admin_note,
        r.item_name
        FROM requests r
        JOIN camps c ON r.camp_id = c.camp_id
        WHERE c.manager_id = %s
        ORDER BY r.request_date DESC
        """, (session["user_id"],))


    data = cur.fetchall()

    # Build display data with item_name merged
    display_data = []
    for row in data:
        item_display = row[0]
        if row[0] == 'other' and row[5]:
            item_display = f"other ({row[5]})"
        display_data.append((item_display, row[1], row[2], row[3], row[4]))

    cur.close()
    conn.close()

    return render_template("requests/my_requests.html", requests=display_data)

#----------------------------------------------------------------------------------------------------------
@app.route("/admin/assign-trucks", methods=["POST"])
def assign_trucks():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    # Fetch only camps that have Approevd allocations
    cur.execute("""
        SELECT DISTINCT c.camp_id, c.name, c.cord_x, c.cord_y
        FROM camps c
        JOIN requests r ON r.camp_id = c.camp_id
        JOIN allocations a ON a.request_id = r.request_id
        WHERE a.delivery_status = 'scheduled'
    """)
    rows = cur.fetchall()

    camps = [{
        "camp_id": r[0],
        "name": r[1],
        "x": float(r[2]),
        "y": float(r[3])
    } for r in rows]

    # Fetch available trucks
    cur.execute("""
        SELECT truck_id
        FROM trucks
        WHERE status = 'available'
        ORDER BY truck_id
    """)
    trucks = [r[0] for r in cur.fetchall()]

    if not camps or not trucks:
        flash("No camps with scheduled deliveries or no available trucks.", "warning")
        cur.close()
        conn.close()
        return redirect(url_for("adminBoard"))

    #clustering
    from Algo.clustering import cluster_camps
    clusters = cluster_camps(camps, trucks)

    #Clear old assignments
    cur.execute("DELETE FROM truck_assignments")

    # truck mapping
    assigned_truck_ids = []
    for i, camp_list in clusters.items():
        if i >= len(trucks):
            print(f"  WARNING: Cluster {i} but only {len(trucks)} trucks available!")
            continue
        truck_id = trucks[i]
        assigned_truck_ids.append(truck_id)

        for camp in camp_list:
            cur.execute("""
                INSERT INTO truck_assignments (truck_id, camp_id)
                VALUES (%s, %s)
            """, (truck_id, camp["camp_id"]))
    
    # Assign available drivers to the trucks we just assigned
    cur.execute("""
        SELECT id FROM users
        WHERE role = 'driver'
        ORDER BY id """)
    all_drivers = [r[0] for r in cur.fetchall()]

    # Assign drivers to the trucks that have camp assignments
    for idx, truck_id in enumerate(assigned_truck_ids):
        if idx < len(all_drivers):
            driver_id = all_drivers[idx]
            cur.execute("""
                UPDATE trucks
                SET driver_id = %s
                WHERE truck_id = %s
            """, (driver_id, truck_id))

            # Notify the driver about assignment
            cur.execute("SELECT truck_number FROM trucks WHERE truck_id = %s", (truck_id,))
            t_num = cur.fetchone()[0]
            cur.execute("""
                SELECT c.name FROM truck_assignments ta
                JOIN camps c ON ta.camp_id = c.camp_id
                WHERE ta.truck_id = %s
            """, (truck_id,))
            camp_names = [r[0] for r in cur.fetchall()]
            notify(driver_id, f"You are assigned to {t_num} — Camps: {', '.join(camp_names)}", 'info', cur)

    conn.commit()
    cur.close()
    conn.close()

    flash(f"Assigned {len(clusters)} trucks to {len(camps)} camps across {len(clusters)} clusters.", "success")

    return redirect(url_for("adminBoard"))

#========================================================================================================

@app.route("/admin/greedy-prioritization", methods=["POST"])
def greedy_prioritization():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    #Get trucks
    cur.execute("""
        SELECT DISTINCT truck_id
        FROM truck_assignments
    """)
    truck_ids = [r[0] for r in cur.fetchall()]

    from Algo.priority import rank_camps_greedy

    for truck_id in truck_ids:

        # Get camps assigned to this truck
        cur.execute("""
             SELECT
        c.camp_id,
        (c.total_population + c.injured_population) AS population,
        c.urgency_score,
        COALESCE(SUM(a.allocated_quantity), 0) AS current_supply
    FROM truck_assignments ta
    JOIN camps c ON ta.camp_id = c.camp_id
    LEFT JOIN allocations a
        ON a.request_id IN (
            SELECT request_id
            FROM requests
            WHERE camp_id = c.camp_id
        )
    WHERE ta.truck_id = %s
    GROUP BY
        c.camp_id,
        c.total_population,
        c.injured_population,
        c.urgency_score
        """, (truck_id,))

        rows = cur.fetchall()

        camps = []
        for r in rows:
            camps.append({
                "camp_id": r[0],
                "population": r[1],
                "urgency": (
                    "critical" if r[2] >= 0.75 else
                    "high" if r[2] >= 0.5 else
                    "medium" if r[2] >= 0.25 else
                    "low"
                ),
                "current_supply": max(r[3], 1)  # avoid divide by zero
            })


        # Greedy sort
        ordered = rank_camps_greedy(camps)

        # visit order
        for idx, camp in enumerate(ordered, start=1):
            cur.execute("""
                UPDATE truck_assignments
                SET visit_order = %s
                WHERE truck_id = %s AND camp_id = %s
            """, (idx, truck_id, camp["camp_id"]))

    conn.commit()
    cur.close()
    conn.close()

    flash("Greedy prioritization applied - camps ordered by urgency within each cluster.", "success")

    return redirect(url_for("adminBoard"))


#==========================================================================================================

@app.route("/admin/load-trucks", methods=["POST"])
def load_trucks():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    ITEM_WEIGHTS = {
        "food": 1.0,
        "water": 1.0,
        "medicine-kit": 0.5
    }

    from Algo.knapsack import knapsack

    conn = get_db_connection()
    cur = conn.cursor()

    #Get trucks with assignments
    cur.execute("""
        SELECT DISTINCT t.truck_id, t.capacity_kg
        FROM truck_assignments ta
        JOIN trucks t ON ta.truck_id = t.truck_id
    """)
    trucks = cur.fetchall()

    for truck_id, capacity in trucks:

        # Get allocatable 
        cur.execute("""
            SELECT
                a.allocation_id,
                r.item_type,
                a.allocated_quantity,
                COALESCE(a.item_weight, 0),
                c.urgency_score
            FROM allocations a
            JOIN requests r ON a.request_id = r.request_id
            JOIN camps c ON r.camp_id = c.camp_id
            JOIN truck_assignments ta ON ta.camp_id = c.camp_id
            WHERE ta.truck_id = %s
              AND a.delivery_status = 'scheduled'
        """, (truck_id,))

        rows = cur.fetchall()
        if not rows:
            continue

        items = []
        for r in rows:
            alloc_id, item_type, qty, custom_weight, urgency = r

            weight = (
                custom_weight if item_type == "other"
                else ITEM_WEIGHTS.get(item_type, 1.0) * qty
            )

            value = int(urgency * 100)  # higher urgency = higher value

            items.append({
                "allocation_id": alloc_id,
                "weight": int(weight),
                "value": value
            })

        # 0/1 Knapsack
        selected = knapsack(items, int(capacity))

        # Load selected items
        total_load = 0
        for item in selected:
            total_load += item["weight"]

            cur.execute("""
                UPDATE allocations
                SET delivery_status = 'in_transit',
                    truck_id = %s
                WHERE allocation_id = %s
            """, (truck_id, item["allocation_id"],))

        # Update truck load and status
        cur.execute("""
            UPDATE trucks
            SET current_load_kg = %s,
                status = 'loading'
            WHERE truck_id = %s
        """, (total_load, truck_id))

    conn.commit()
    cur.close()
    conn.close()

    flash("Trucks loaded using knapsack optimization - ready for execution.", "success")

    return redirect(url_for("adminBoard"))


#=============================================================================================================

@app.route("/api/truck-routes")
def get_truck_routes():
    conn = get_db_connection()
    cur = conn.cursor()

    # Get camps with urgency, ordered by visit_order
    cur.execute("""
        SELECT
            ta.truck_id,
            c.camp_id,
            c.name,
            c.cord_x,
            c.cord_y,
            c.urgency_score,
            ta.visit_order
        FROM truck_assignments ta
        JOIN camps c ON ta.camp_id = c.camp_id
        ORDER BY ta.truck_id, ta.visit_order NULLS LAST, c.urgency_score DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    # Group camps by truck (already ordered by visit_order)
    trucks = {}
    for r in rows:
        truck_id = r[0]
        if truck_id not in trucks:
            trucks[truck_id] = []
        trucks[truck_id].append({
            "camp_id": r[1],
            "name": r[2],
            "x": float(r[3]),
            "y": float(r[4]),
            "urgency": float(r[5]),
            "visit_order": r[6]
        })

    depot = {"x": DEPOT_X, "y": DEPOT_Y}

    routes = []

    # Build routes - camps are already in visit_order from SQL
    for truck_id, camp_list in trucks.items():
        if not camp_list:
            continue

        edges = []
        
        # Build a line from depot through camps
        route_points = [[DEPOT_Y, DEPOT_X]]  # Start with depot [y, x] - converted on frontend
        
        for camp in camp_list:
            route_points.append([camp["y"], camp["x"]])
        
        # Create edges for each segment
        for i in range(len(route_points) - 1):
            edges.append([route_points[i], route_points[i + 1]])

        routes.append({
            "truck_id": truck_id,
            "edges": edges,
            "route_points": route_points,  # Full polyline for easier drawing
            "camps": [{"name": c["name"], "urgency": c["urgency"], "order": c["visit_order"], "x": c["x"], "y": c["y"]} for c in camp_list]
        })

    return {"routes": routes, "depot": {"x": DEPOT_X, "y": DEPOT_Y}}

#=============================================================================================================

@app.route("/admin/execute-plan", methods=["POST"])
def execute_delivery_plan():
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    # Check if execution is already live
    if execution_locked():
        flash("Delivery plan is already being executed!", "warning")
        return redirect(url_for("adminBoard"))

    conn = get_db_connection()
    cur = conn.cursor()

    # Check if there are any trucks ready (with in_transit allocations from load_trucks)
    cur.execute("""
        SELECT COUNT(DISTINCT truck_id)
        FROM allocations
        WHERE delivery_status = 'in_transit'
          AND truck_id IS NOT NULL
    """)
    ready_count = cur.fetchone()[0]
    
    if ready_count == 0:
        flash("No trucks are loaded. Please complete steps 1-3 first.", "warning")
        cur.close()
        conn.close()
        return redirect(url_for("adminBoard"))

    # Update truck status to in_transit
    cur.execute("""
        UPDATE trucks
        SET status = 'in_transit'
        WHERE truck_id IN (
            SELECT DISTINCT truck_id
            FROM allocations
            WHERE delivery_status = 'in_transit'
              AND truck_id IS NOT NULL
        )
    """)

    # Set execution lock
    cur.execute("""
        UPDATE system_state
        SET is_execution_live = TRUE,
            executed_at = CURRENT_TIMESTAMP
        WHERE id = 1
    """)

    conn.commit()
    cur.close()
    conn.close()

    flash("Delivery plan executed! Trucks are now in transit.", "success")
    return redirect(url_for("adminBoard"))



#=============================================================================================================


#----------------------------------------------------------------------------------------------------------

@app.route("/driver/dashboard")
def driver_dashboard():
    if session.get("role") != "driver":
        return redirect(url_for("login"))

    driver_id = session.get("user_id")

    conn = get_db_connection()
    cur = conn.cursor()

    # Get truck
    cur.execute("""
        SELECT truck_id, truck_number, status
        FROM trucks
        WHERE driver_id = %s
    """, (driver_id,))
    truck = cur.fetchone()

    if not truck:
        cur.close()
        conn.close()
        return render_template("dashboard/driver.html", 
                               deliveries=[], 
                               camps=[],
                               truck_number=None,
                               truck_status=None)

    truck_id, truck_number, truck_status = truck

    # Get assigned camps with visit order and their deliveries
    cur.execute("""
        SELECT 
            c.camp_id,
            c.name AS camp_name,
            c.cord_x,
            c.cord_y,
            c.urgency_score,
            ta.visit_order
        FROM truck_assignments ta
        JOIN camps c ON ta.camp_id = c.camp_id
        WHERE ta.truck_id = %s
        ORDER BY ta.visit_order NULLS LAST, c.urgency_score DESC
    """, (truck_id,))
    
    camps_data = cur.fetchall()
    
    # Also build camps list with their deliveries
    camps = []
    for camp_row in camps_data:
        camp_id, camp_name, cord_x, cord_y, urgency, visit_order = camp_row
        
        # Get deliveries for this camp - check both via truck_id and via truck_assignments
        cur.execute("""
            SELECT 
                r.item_type,
                a.allocated_quantity,
                a.delivery_status
            FROM allocations a
            JOIN requests r ON a.request_id = r.request_id
            WHERE r.camp_id = %s 
              AND (a.truck_id = %s OR a.truck_id IS NULL)
              AND a.delivery_status != 'delivered'
            ORDER BY r.item_type
        """, (camp_id, truck_id))
        
        items = cur.fetchall()
        
        # Check if all items for this camp are delivered
        cur.execute("""
            SELECT COUNT(*)
            FROM allocations a
            JOIN requests r ON a.request_id = r.request_id
            WHERE r.camp_id = %s 
              AND (a.truck_id = %s OR a.truck_id IS NULL)
              AND a.delivery_status != 'delivered'
        """, (camp_id, truck_id))
        pending_count = cur.fetchone()[0]
        
        camps.append({
            "camp_id": camp_id,
            "name": camp_name,
            "cord_x": cord_x,
            "cord_y": cord_y,
            "urgency": urgency,
            "visit_order": visit_order or 0,
            "delivery_items": [{"type": i[0], "quantity": i[1], "status": i[2]} for i in items],
            "is_delivered": pending_count == 0 and len(items) == 0
        })
    
    # Also get flat deliveries list for backward compatibility
    cur.execute("""
        SELECT
            c.name AS camp_name,
            r.item_type,
            a.allocated_quantity
        FROM allocations a
        JOIN requests r ON a.request_id = r.request_id
        JOIN camps c ON r.camp_id = c.camp_id
        JOIN truck_assignments ta ON ta.camp_id = c.camp_id AND ta.truck_id = a.truck_id
        WHERE a.truck_id = %s
          AND a.delivery_status != 'delivered'
        ORDER BY ta.visit_order NULLS LAST, c.name, r.item_type
    """, (truck_id,))

    deliveries = cur.fetchall()

    cur.close()
    conn.close()

    return render_template(
        "dashboard/driver.html",
        deliveries=deliveries,
        camps=camps,
        truck_number=truck_number,
        truck_status=truck_status
    )




@app.route("/api/driver-route")
def driver_route():
    if session.get("role") != "driver":
        return {"points": [], "camps": []}

    driver_id = session.get("user_id")

    conn = get_db_connection()
    cur = conn.cursor()

    # Get driver's truck
    cur.execute("""
        SELECT truck_id
        FROM trucks
        WHERE driver_id = %s
    """, (driver_id,))
    truck_row = cur.fetchone()
    
    if not truck_row:
        cur.close()
        conn.close()
        return {"points": [], "camps": []}
    
    truck_id = truck_row[0]

    # Get camps in visit order
    cur.execute("""
        SELECT
            c.camp_id,
            c.name,
            c.cord_x,
            c.cord_y,
            c.urgency_score,
            ta.visit_order
        FROM truck_assignments ta
        JOIN camps c ON ta.camp_id = c.camp_id
        WHERE ta.truck_id = %s
        ORDER BY ta.visit_order NULLS LAST, c.urgency_score DESC
    """, (truck_id,))

    camps = cur.fetchall()
    cur.close()
    conn.close()

    # Build route from NGO depot
    # [y, x] grid coords - converted to real lat/lng on frontend
    points = [[DEPOT_Y, DEPOT_X]]  # Base at (500, 0)
    
    camp_info = []
    for idx, camp in enumerate(camps):
        camp_id, name, cord_x, cord_y, urgency, visit_order = camp
        points.append([cord_y, cord_x])  # [y, x] grid coords
        camp_info.append({
            "camp_id": camp_id,
            "name": name,
            "x": cord_x,
            "y": cord_y,
            "urgency": urgency,
            "stop_number": idx + 1
        })

    return {
        "points": points,
        "camps": camp_info,
        "depot": {"x": DEPOT_X, "y": DEPOT_Y}
    }


@app.route("/driver/delivered", methods=["POST"])
def mark_delivered():
    if session.get("role") != "driver":
        return redirect(url_for("login"))

    driver_id = session.get("user_id")

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        UPDATE allocations
        SET delivery_status = 'delivered',
            delivery_datetime = CURRENT_TIMESTAMP
        WHERE truck_id = (
            SELECT truck_id FROM trucks WHERE driver_id = %s
        )
    """, (driver_id,))

    conn.commit()
    cur.close()
    conn.close()

    return redirect(url_for("driver_dashboard"))

@app.route("/driver/mark-camp-delivered/<int:camp_id>", methods=["POST"])
def mark_camp_delivered(camp_id):
    if session.get("role") != "driver":
        return redirect(url_for("login"))

    driver_id = session.get("user_id")

    conn = get_db_connection()
    cur = conn.cursor()

    # 1️⃣ Get driver's truck
    cur.execute("""
        SELECT truck_id
        FROM trucks
        WHERE driver_id = %s
    """, (driver_id,))
    row = cur.fetchone()

    if not row:
        cur.close()
        conn.close()
        return redirect(url_for("driver_dashboard"))

    truck_id = row[0]

    # Mark allocations for camp as delivered
    cur.execute("""
        UPDATE allocations a
        SET delivery_status = 'delivered',
            delivery_datetime = CURRENT_TIMESTAMP
        FROM requests r
        WHERE a.request_id = r.request_id
          AND r.camp_id = %s
          AND a.truck_id = %s
    """, (camp_id, truck_id))

    # Update request status
    cur.execute("""
        UPDATE requests
        SET status = 'delivered',
            last_updated = CURRENT_TIMESTAMP
        WHERE camp_id = %s
          AND request_id IN (
              SELECT request_id
              FROM allocations
              WHERE truck_id = %s
                AND delivery_status = 'delivered'
          )
    """, (camp_id, truck_id))

    # Notify admin and camp manager about delivery
    cur.execute("SELECT name, manager_id FROM camps WHERE camp_id = %s", (camp_id,))
    camp_row = cur.fetchone()
    cur.execute("SELECT truck_number FROM trucks WHERE truck_id = %s", (truck_id,))
    t_num = cur.fetchone()[0]
    driver_name = session.get('name', 'Driver')
    if camp_row:
        notify_role('admin', f"  Delivery completed: {driver_name} delivered to {camp_row[0]} ({t_num})", 'success', cur)
        if camp_row[1]:
            notify(camp_row[1], f"  Delivery arrived at {camp_row[0]} via {t_num}", 'success', cur)

    # Check if all camps for this truck are delivered
    cur.execute("""
        SELECT COUNT(*)
        FROM allocations
        WHERE truck_id = %s
          AND delivery_status != 'delivered'
    """, (truck_id,))
    remaining = cur.fetchone()[0]

    # Update truck status
    if remaining == 0:
        cur.execute("""
            UPDATE trucks
            SET status = 'available',
                current_load_kg = 0
            WHERE truck_id = %s
        """, (truck_id,))
        
        # Check if ALL trucks are done to reset execution lock
        cur.execute("""
            SELECT COUNT(*)
            FROM trucks
            WHERE status = 'in_transit'
        """)
        active_trucks = cur.fetchone()[0]
        
        if active_trucks == 0:
            cur.execute("""
                UPDATE system_state
                SET is_execution_live = FALSE
                WHERE id = 1
            """)
    else:
        cur.execute("""
            UPDATE trucks
            SET status = 'in_transit'
            WHERE truck_id = %s
        """, (truck_id,))

    conn.commit()
    cur.close()
    conn.close()

    return redirect(url_for("driver_dashboard"))


@app.route("/admin/reset-execution", methods=["POST"])
def reset_execution():
    """Admin can manually reset the execution lock and clear completed deliveries"""
    if session.get("role") != "admin":
        return redirect(url_for("login"))

    conn = get_db_connection()
    cur = conn.cursor()

    # Reset execution lock
    cur.execute("""
        UPDATE system_state
        SET is_execution_live = FALSE
        WHERE id = 1
    """)

    # Reset all trucks to available
    cur.execute("""
        UPDATE trucks
        SET status = 'available',
            current_load_kg = 0
    """)

    # Clear truck assignments for next round
    cur.execute("DELETE FROM truck_assignments")

    conn.commit()
    cur.close()
    conn.close()

    flash("System reset complete. Ready for new delivery cycle.", "success")
    return redirect(url_for("adminBoard"))


@app.route("/api/notifications")
def api_notifications():
    """Get all notifications for current user (latest 50)."""
    if "user_id" not in session:
        return jsonify([]), 401

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT notif_id, message, level, is_read, created_at
        FROM notifications
        WHERE user_id = %s
        ORDER BY created_at DESC
        LIMIT 50
    """, (session["user_id"],))
    rows = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify([{
        "id": r[0],
        "message": r[1],
        "level": r[2],
        "is_read": r[3],
        "time": r[4].strftime("%b %d, %H:%M")
    } for r in rows])


@app.route("/api/notifications/unread-count")
def api_unread_count():
    """Get count of unread notifications for current user."""
    if "user_id" not in session:
        return jsonify({"count": 0}), 401

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT COUNT(*) FROM notifications
        WHERE user_id = %s AND is_read = FALSE
    """, (session["user_id"],))
    count = cur.fetchone()[0]
    cur.close()
    conn.close()

    return jsonify({"count": count})


@app.route("/api/notifications/mark-read", methods=["POST"])
def api_mark_read():
    """Mark all notifications as read for current user."""
    if "user_id" not in session:
        return jsonify({"ok": False}), 401

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE notifications SET is_read = TRUE
        WHERE user_id = %s AND is_read = FALSE
    """, (session["user_id"],))
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"ok": True})


# ===== N-Day Prediction Page =====
@app.route("/admin/nday")
def nday_page():
    if session.get("role") != "admin":
        return redirect(url_for("login"))
    return render_template("dashboard/nday.html")


@app.route("/admin/nday/predict", methods=["POST"])
def nday_predict():
    if session.get("role") != "admin":
        return jsonify({"ok": False, "message": "Unauthorized"}), 401

    result = predict_next_day()
    return jsonify(result)


#Logout
@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(debug=True)
