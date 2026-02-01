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

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

if __name__ == "__main__":
    app.run(debug=True)
