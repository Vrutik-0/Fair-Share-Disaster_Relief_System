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
    return render_template("dashboard/admin.html")


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
        SELECT camp_id, name, cord_x, cord_y,
               total_population, injured_population,
               urgency_score, status, created_at
        FROM camps
        ORDER BY urgency_score DESC
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
            "x": r[1],
            "y": r[2],
            "urgency": r[3]
        })

    return {"camps": camps}


#Calculate Urgency Score
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
