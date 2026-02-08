# 🏥 Fair Share — Disaster Relief System

A full-stack web application for **fair and optimized disaster relief distribution**. The system manages relief camps, warehouse inventory, resource requests, truck dispatching, and delivery routing — powered by algorithmic optimization to ensure equitable aid allocation.

![Python](https://img.shields.io/badge/Python-3.x-blue?logo=python)
![Flask](https://img.shields.io/badge/Flask-Web_Framework-lightgrey?logo=flask)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue?logo=postgresql)
![License](https://img.shields.io/badge/License-MIT-green)


## Overview

During disaster scenarios, distributing relief supplies fairly and efficiently is a critical challenge. **Fair Share** solves this by combining role-based management with algorithmic optimization:

- **Camp managers** submit resource requests based on ground-level needs.
- **Admins** oversee warehouse inventory, approve/reject requests, manage trucks, and execute optimized delivery plans.
- **Drivers** view their assigned routes and update delivery statuses in real time.
- **Algorithms** ensure camps are clustered geographically, prioritized by urgency, loaded optimally onto trucks, and routed efficiently.

---

## Features

### 🔐 Authentication & Role-Based Access
- Secure signup/login with hashed passwords (Werkzeug)
- Three distinct roles: **Admin**, **Camp Manager**, **Driver**
- Session-based access control

### 🏕️ Camp Management
- Register and manage relief camps on a 1000×1000 coordinate grid
- Track total & injured population per camp
- Auto-calculated **urgency scores** (0.0 – 1.0) based on population and injury ratio
- Status classification: `critical`, `moderate`, `stable`

### 📦 Warehouse Inventory
- Central warehouse with stock tracking for **food**, **water**, **medicine-kits**, and **other** items
- Low-stock threshold alerts
- Real-time stock deduction on request approval

### 📝 Resource Request Pipeline
- Camp managers submit requests specifying item type and quantity
- **Auto-approval logic**: Automatically allocates stock when available (full or partial)
- Request lifecycle: `pending` → `partially_approved` / `approved` → `dispatched` → `delivered`
- Admin override with notes

### 🚚 Truck & Driver Management
- Register trucks with capacity limits
- Assign drivers to trucks
- Track truck status: `available`, `loading`, `in_transit`, `maintenance`

### 🧠 Algorithmic Delivery Execution
- One-click **Execute Deliveries** pipeline that runs:
  1. **K-Means Clustering** — Groups camps geographically for truck assignment
  2. **Greedy Priority Ranking** — Ranks camps within clusters by urgency
  3. **0/1 Knapsack** — Optimally loads each truck within weight capacity
  4. **Greedy Routing** — Plans delivery routes prioritizing urgency, breaking ties by proximity
- Execution lock prevents concurrent delivery runs

### 🔔 Notifications
- In-app notification system for all users
- Alerts for request status changes, delivery updates, and system events
- Severity levels: `info`, `success`, `warning`, `danger`

### 📊 Dashboards
- **Admin Dashboard**: System overview, camp statuses, warehouse stock, pending requests
- **Camp Manager Dashboard**: Camp details, request history, delivery tracking
- **Driver Dashboard**: Assigned routes, delivery status updates

---

## Tech Stack

| Layer        | Technology                          |
|-------------|--------------------------------------|
| **Backend**  | Python 3, Flask                     |
| **Frontend** | HTML, CSS, JavaScript (Jinja2 templates) |
| **Database** | PostgreSQL with psycopg2            |
| **Auth**     | Werkzeug password hashing           |

---

