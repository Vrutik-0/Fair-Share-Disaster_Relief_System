---

# 📦 Fair-Share Disaster Relief System

**Fair-Share** is an intelligent disaster relief management system that optimizes resource allocation and distribution to relief camps using advanced algorithms and real-time coordination.

## 🎯 Overview

Fair-Share streamlines disaster relief operations by:
- **Managing multiple relief camps** with location-based tracking
- **Automating resource allocation** from a central warehouse
- **Optimizing delivery routes** using clustering and priority algorithms
- **Coordinating drivers** with real-time assignment and tracking
- **Providing role-based dashboards** for admins, camp managers, and drivers

## ✨ Key Features

### 🏕️ **Camp Management**
- Register and manage relief camps on a 1000×1000 coordinate grid
- Auto-calculate urgency scores based on population and injury data
- Track camp status (critical, moderate, stable)
- Real-time camp visualization with interactive maps

### 📊 **Smart Resource Allocation**
- Centralized warehouse inventory management
- Automated approval system for resource requests
- Priority-based allocation using greedy algorithms
- Support for multiple resource types: food, water, medicine kits, and more

### 🚚 **Intelligent Distribution**
- **K-Means Clustering**: Groups camps by geographical proximity
- **Knapsack Algorithm**: Optimizes truck loading within capacity constraints
- **Greedy Routing**: Prioritizes urgent camps while minimizing travel distance
- Real-time truck status tracking (available, loading, in-transit)

### 👥 **Role-Based Access Control**
- **Admin**: Approve requests, manage warehouse, execute distribution workflow
- **Camp Manager**: Create camps, submit resource requests, track deliveries
- **Driver**: View assigned routes, mark deliveries complete

### 🔔 **Real-Time Notifications**
- In-app toast notifications for all user roles
- Request status updates (pending, approved, delivered)
- Low stock alerts for warehouse items

## 🛠️ Tech Stack

### **Backend**
- **Flask** - Python web framework
- **PostgreSQL** - Relational database
- **psycopg2** - PostgreSQL adapter

### **Frontend**
- HTML5, CSS3, JavaScript
- **Leaflet.js** - Interactive mapping
- Responsive design with custom CSS

### **Algorithms**
- **Clustering** (`Algo/clustering.py`) - K-Means for camp grouping
- **Priority Ranking** (`Algo/priority.py`) - Greedy algorithm for camp prioritization
- **Knapsack** (`Algo/knapsack.py`) - Dynamic programming for truck loading
- **Route Optimization** (`Algo/routes.py`) - Greedy nearest-neighbor routing

## 📂 Project Structure

```
Fair-Share-Disaster_Relief_System/
├── app.py                  # Main Flask application
├── db.py                   # Database connection configuration
├── data.sql                # Database schema (tables, triggers, views)
├── syndata.sql             # Sample test data
├── Algo/
│   ├── clustering.py       # K-Means clustering algorithm
│   ├── priority.py         # Priority scoring and ranking
│   ├── knapsack.py         # Truck loading optimization
│   └── routes.py           # Route generation algorithm
├── templates/
│   ├── login.html
│   ├── dashboard/          # Role-specific dashboards
│   ├── Camp/               # Camp management views
│   ├── warehouse/          # Inventory management
│   └── requests/           # Request handling views
└── static/
    ├── style.css           # Global styles
    └── script.js           # Client-side JavaScript
```

## 🚀 Getting Started

### **Prerequisites**
- Python 3.8+
- PostgreSQL 12+
- pip (Python package manager)

### **Installation**

1. **Clone the repository**
```bash
git clone https://github.com/Vrutik-0/Fair-Share-Disaster_Relief_System.git
cd Fair-Share-Disaster_Relief_System
```

2. **Install dependencies**
```bash
pip install flask psycopg2-binary werkzeug scikit-learn
```

3. **Set up PostgreSQL database**
```bash
# Create database
createdb fairshare_db

# Run schema creation
psql -d fairshare_db -f data.sql

# (Optional) Load test data
psql -d fairshare_db -f syndata.sql
```

4. **Configure database connection**

Update `db.py` with your PostgreSQL credentials:
```python
def get_db_connection():
    return psycopg2.connect(
        dbname="fairshare_db",
        user="your_username",
        password="your_password",
        host="localhost",
        port="5432"
    )
```

5. **Run the application**
```bash
python app.py
```

6. **Access the application**
- Open browser: `http://localhost:5000`
- Test credentials (if using syndata.sql):
  - **Admin**: `admin@fairshare.org` / `password123`
  - **Camp Manager**: `alpha.manager@camp.org` / `password123`

## 📖 How It Works

### **Urgency Score Calculation**
```python
urgency_score = (injured_population / total_population) × 0.7 + (total_population / 1000) × 0.3
```
- Range: 0.0 (low) to 1.0 (critical)
- Weighs injury ratio (70%) and population size (30%)

### **Priority Scoring**
```python
priority = (population × urgency_weight) / current_supply
```
- Higher priority = more urgent need
- Urgency weights: critical (4), high (3), medium (2), low (1)

### **Distribution Workflow**
1. **Cluster**: Group camps geographically using K-Means
2. **Allocate**: Assign trucks to clusters
3. **Optimize**: Pack trucks using knapsack algorithm
4. **Route**: Generate delivery sequence prioritizing urgent camps
5. **Execute**: Drivers complete deliveries and confirm

## 🗄️ Database Schema

### **Core Tables**
- `users` - Admin, camp managers, drivers
- `camps` - Relief camp locations and status
- `warehouse_inventory` - Central stock management
- `requests` - Resource requests from camps
- `allocations` - Approved resource allocations
- `trucks` - Delivery vehicle management
- `truck_assignments` - Route assignments per truck
- `notifications` - User notification system
- `system_state` - Application state management

## 🎨 User Interfaces

### **Admin Dashboard**
- View all camps on map with color-coded urgency
- Execute 5-step distribution workflow
- Approve/discard resource requests
- Manage warehouse inventory

### **Camp Manager Dashboard**
- Register new camps
- Submit resource requests
- Track request status
- View assigned camps on map

### **Driver Dashboard**
- View assigned route and stops
- See delivery priority and cargo details
- Mark deliveries complete
- Track truck status
