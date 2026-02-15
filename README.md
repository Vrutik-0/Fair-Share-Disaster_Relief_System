# Fair Share Disaster Relief System

A comprehensive disaster management system designed to optimize the allocation of resources, prioritize relief camps based on urgency, and plan efficient delivery routes. This application leverages various algorithms to ensure fair and timely aid distribution.

## 🚀 Features

- **Resource Allocation:** Optimizes the packing of relief supplies using the Knapsack algorithm to maximize value within weight constraints.
- **Camp Prioritization:** Ranks relief camps based on population, injury severity, and current supply levels using a weighted scoring system.
- **Route Optimization:** Calculates efficient delivery routes for trucks using a greedy algorithm that balances urgency and distance.
- **Camp Clustering:** Groups relief camps into clusters using K-Means to assign them to specific delivery trucks.
- **N-Day Demand Prediction:** XGBoost ML model predicts next-day resource needs per item type using historical request patterns, with trend indicators (increasing/decreasing/stable).
- **Real-time Notifications:** Alerts users about request statuses and system updates.
- **Interactive Map Visualization:** Displays camps, truck routes, and the NGO depot on a TomTom-based map with urgency color coding.
- **Fair Allocation Engine:** Uses weighted largest-remainder method to fairly distribute limited supplies across competing requests based on priority.
- **Data Visualization:** Uses python matplotlib libary to display the data over dashboards .

## 🛠️ Tech Stack

- **Backend:** Python (Flask)
- **Database:** PostgreSQL
- **Frontend:** HTML, CSS, JavaScript
- **Mapping:** TomTom Maps SDK (interactive map)
- **ML / Algorithms:** XGBoost (demand forecasting), Scikit-learn (K-Means clustering), custom Knapsack & Greedy Search
- **Database Driver:** Psycopg2
- **Authentication:** Werkzeug (password hashing)

## 👥 User Roles & Dashboards

The system supports three distinct user roles, each with a dedicated dashboard and specific capabilities:

### 1. 🛡️ Admin Dashboard (`/admin/dashboard`)

The admin has full control over the disaster relief pipeline. The dashboard displays real-time statistics including:
- **Total Camps** registered in the system
- **Critical Camps** (urgency score ≥ 0.7)
- **Moderate Camps** (urgency score between 0.4 and 0.7)
- **Average Urgency** across all camps

**Admin Delivery Pipeline (4-Step Process):**
1. **Step 1 — Assign Trucks:** Clusters camps geographically and assigns trucks + drivers
2. **Step 2 — Prioritize:** Applies greedy prioritization to order camps by urgency within clusters
3. **Step 3 — Load Trucks:** Uses knapsack optimization to load items within truck capacity
4. **Step 4 — Execute:** Launches the delivery plan and locks the system until deliveries complete

**N-Day Prediction Page (`/admin/nday`):**
- Uses an XGBoost regression model trained on historical daily request data
- Predicts next-day demand for each resource type (food, water, medicine-kit)
- Displays prediction cards with quantity and trend indicators
- Requires minimum 9 days of request history; shows an insufficient-data message otherwise
- Features engineered: day-of-week, day-number, lag-1/2/3, rolling 3/5/7-day averages
  
<img width="1919" height="914" alt="Screenshot 2026-02-15 165801" src="https://github.com/user-attachments/assets/60702157-e5d6-433e-b37e-778bcd6d5a3f" />

<img width="1506" height="912" alt="Screenshot 2026-02-15 165818" src="https://github.com/user-attachments/assets/5846cee1-87b8-4379-94d5-b13cd0616f75" />

<img width="1919" height="829" alt="Screenshot 2026-02-15 165839" src="https://github.com/user-attachments/assets/35b35e2f-e1e3-4b23-8ab8-5ab6aa1d9843" />

### 2. 🏕️ Camp Manager Dashboard (`/camp/dashboard`)

Camp managers register and manage relief camps, then submit resource requests.

**Camp Manager Features:**

| Feature | Route | Description |
|---------|-------|-------------|
| **Add Camp** | `/camp/add` | Register a new camp with name, coordinates (0–1000 grid), total population, and injured population. Urgency score is auto-calculated |
| **View All Camps** | `/camps` | Browse all registered camps with urgency scores, statuses, and assigned managers |
| **Create Request** | `/requests/new` | Submit a resource request (food, water, medicine-kit, or other) for a managed camp. Priority is auto-assigned based on camp urgency |
| **My Requests** | `/requests/mine` | Track all submitted requests with status (pending, partially approved, approved, delivered, discarded) and admin notes |
| **Warehouse Inventory** | `/warehouse` | View current warehouse stock levels to plan requests accordingly |

**Urgency Score Calculation:**
Score = (injured_population / total_population) × 0.7 + (total_population / 1000) × 0.3

Code
The score is capped at 1.0 and is computed automatically when a camp is added. It determines auto-priority assignment:
- **Critical:** urgency ≥ 0.75
- **High:** urgency ≥ 0.5
- **Medium:** urgency ≥ 0.3
- **Low:** urgency < 0.3


<img width="1919" height="893" alt="Screenshot 2026-02-15 165907" src="https://github.com/user-attachments/assets/eb0e7bd5-a4eb-40b6-9162-1d464a890100" />


### 3. 🚛 Driver Dashboard (`/driver/dashboard`)

Drivers see their assigned truck, delivery route, and camp-by-camp delivery checklist.

**Driver Features:**

| Feature | Route | Description |
|---------|-------|-------------|
| **View Assigned Truck** | Dashboard | Displays assigned truck number and current status (available, loading, in_transit) |
| **Camp Delivery List** | Dashboard | Shows all assigned camps in visit order with delivery items (type, quantity, status) |
| **Interactive Route Map** | Dashboard map | TomTom map showing the driver's specific route from the NGO depot through each camp |
| **Mark Camp Delivered** | `/driver/mark-camp-delivered/<camp_id>` | Mark deliveries for a single camp as complete — updates allocation and request statuses |
| **Mark All Delivered** | `/driver/delivered` | Mark all assigned deliveries as delivered at once |

When all deliveries for a truck are completed, the truck status resets to `available`. When all trucks finish, the system-wide execution lock is automatically released.

<img width="1919" height="905" alt="Screenshot 2026-02-15 170845" src="https://github.com/user-attachments/assets/d95d3e43-92d5-4d56-ab3b-f26bd52d60ae" />

## 🧠 Algorithms Used

The system employs several algorithms to solve logistical challenges:

1.  **K-Means Clustering (`Algo/clustering.py`):**
    Groups scattered relief camps into clusters to be served by specific trucks, reducing overall travel time.

2.  **0/1 Knapsack Problem (`Algo/knapsack.py`):**
    Determines the optimal combination of relief items to load onto a truck to maximize the "value" of aid (e.g., medical kits have higher value) without exceeding the truck's weight capacity.

3.  **Greedy Priority Ranking (`Algo/priority.py`):**
    Calculates a priority score for each camp:
    `Score = (Population × Urgency_Weight) / Current_Supply`
    This ensures that camps with critical needs and low supplies are served first.

4.  **Greedy Routing (`Algo/routes.py`):**
    Constructs a delivery path by iteratively selecting the next destination based on urgency and proximity to the current location.

5.  **Weighted Largest-Remainder Allocation (in `app.py`):**
    When warehouse stock is insufficient to fulfill all requests, the system fairly distributes available stock using priority-weighted proportional allocation with the largest-remainder method to avoid rounding losses.

6.  **XGBoost Demand Forecasting (`Algo/model.py`):**
    Trains an XGBoost regression model per resource type on daily aggregated request history. Engineered features include day-of-week, ordinal day number, lag-1/2/3 demand, and 3/5/7-day rolling averages. Predicts next-day demand and computes trend direction (increasing, decreasing, or stable) by comparing recent vs. prior 3-day averages.

## 🗄️ Database Schema

The PostgreSQL database consists of 9 tables and 5 monitoring views:

| Table | Description |
|-------|-------------|
| `users` | System users with roles (admin, camp_manager, driver) and hashed passwords |
| `camps` | Relief camps with coordinates on a 1000×1000 grid, population data, and urgency scores |
| `warehouse_inventory` | Central stock with item types (food, water, medicine-kit, other), quantities, and low-stock thresholds |
| `requests` | Resource requests from camps with priority levels and fulfillment tracking |
| `trucks` | Delivery vehicles with capacity, current load, status, and driver assignment |
| `allocations` | Links approved requests to deliveries with status tracking (scheduled → in_transit → delivered) |
| `truck_assignments` | Maps trucks to camps with visit order (result of clustering + prioritization) |
| `system_state` | Global execution lock to prevent duplicate delivery runs |
| `notifications` | In-app alerts with user targeting, severity levels, and read status |

**Database Views:**
- `v_truck_assignments` — Current truck-to-camp assignments with driver info
- `v_pending_requests` — Summary of all pending/partially approved requests
- `v_allocations_status` — Allocation tracking with delivery status
- `v_warehouse_stock` — Stock levels with LOW STOCK / WARNING indicators
- `v_camps_overview` — Camp details with pending request counts

## ⚙️ Installation & Setup

### Prerequisites

- Python 3.x
- PostgreSQL

### Steps

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/Vrutik-0/Fair-Share-Disaster_Relief_System.git
    ```
    ```bash
    cd Fair-Share-Disaster_Relief_System
    ```

2.  **Install Dependencies**
    Ensure you have the required Python packages installed. You may need to create a virtual environment first.
    ```bash
    pip install -r requirements.txt
    ```

3.  **Database Setup**
    - Create a PostgreSQL database.
    - Run the provided SQL scripts to set up the schema and seed initial data:
      ```bash
      psql -U your_username -d your_database -f data.sql
      # Optional: load synthetic data (2-day demo)
      psql -U your_username -d your_database -f syndata.sql
      # Optional: load 14-day ML training data (replaces syndata requests)
      psql -U your_username -d your_database -f ml_data.sql
      ```

4.  **Environment Configuration**
    Create a `.env` file in the root directory and add your database credentials:
    ```env
    DB_HOST=localhost
    DB_NAME=your_database_name
    DB_USER=your_username
    DB_PASSWORD=your_password
    SECRET_KEY=your_secret_key
    ```

5.  **Run the Application**
    ```bash
    python app.py
    ```
    The application will start (usually at `http://127.0.0.1:5000`).
