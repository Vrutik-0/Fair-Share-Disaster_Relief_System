# Fair Share Disaster Relief System

A comprehensive disaster management system designed to optimize the allocation of resources, prioritize relief camps based on urgency, and plan efficient delivery routes. This application leverages various algorithms to ensure fair and timely aid distribution.

## 🚀 Features

- **Resource Allocation:** Optimizes the packing of relief supplies using the Knapsack algorithm to maximize value within weight constraints.
- **Camp Prioritization:** Ranks relief camps based on population, injury severity, and current supply levels using a weighted scoring system.
- **Route Optimization:** Calculates efficient delivery routes for trucks using a greedy algorithm that balances urgency and distance.
- **Camp Clustering:** Groups relief camps into clusters using K-Means to assign them to specific delivery trucks.
- **Automated Approval:** Automatically processes and approves resource requests based on warehouse inventory.
- **Real-time Notifications:** Alerts users about request statuses and system updates.

## 🛠️ Tech Stack

- **Backend:** Python (Flask)
- **Database:** PostgreSQL
- **Frontend:** HTML, CSS, JavaScript
- **Algorithms:** Scikit-learn (K-Means), Custom implementations for Knapsack & Greedy Search
- **Database Driver:** Psycopg2

## 🧠 Algorithms Used

The system employs several algorithms to solve logistical challenges:

1.  **K-Means Clustering (`Algo/clustering.py`):**
    Groups scattered relief camps into clusters to be served by specific trucks, reducing overall travel time.

2.  **0/1 Knapsack Problem (`Algo/knapsack.py`):**
    Determines the optimal combination of relief items to load onto a truck to maximize the "value" of aid (e.g., medical kits have higher value) without exceeding the truck's weight capacity.

3.  **Greedy Priority Ranking (`Algo/priority.py`):**
    Calculates a priority score for each camp:
    `Score = (Population * Urgency_Weight) / Current_Supply`
    This ensures that camps with critical needs and low supplies are served first.

4.  **Greedy Routing (`Algo/routes.py`):**
    Constructs a delivery path by iteratively selecting the next destination based on urgency and proximity to the current location.

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
      # Optional: load synthetic data
      psql -U your_username -d your_database -f syndata.sql
      ```

4.  **Environment Configuration**
    Create a `.env` file in the root directory and add your database credentials:
    ```env
    DB_HOST=localhost
    DB_NAME=your_database_name
    DB_USER=your_username
    DB_PASSWORD=your_password
    ```

5.  **Run the Application**
    ```bash
    python app.py
    ```
    The application will start (usually at `http://127.0.0.1:5000`).

## 📂 Project Structure

- `app.py`: Main Flask application file handling routes and logic.
- `db.py`: Database connection handler.
- `Algo/`: Directory containing the core algorithms.
  - `clustering.py`: Camp clustering logic.
  - `knapsack.py`: Resource packing optimization.
  - `priority.py`: Logic for ranking camp urgency.
  - `routes.py`: Route planning algorithms.
- `templates/`: HTML templates for the web interface.
- `static/`: CSS, JavaScript, and other static assets.
- `data.sql`: Database schema and initial data.
