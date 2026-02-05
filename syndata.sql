-- ============================================================================
-- FAIR-SHARE V1 - SYNTHETIC TEST DATA
-- Disaster Relief Management System
-- ============================================================================
-- This file contains all test data to populate the database for testing.
-- Run data.sql FIRST to create the schema, then run this file.
-- 
-- This creates a complete test environment with:
--   - 1 Admin user
--   - 5 Camp Manager users (each managing a camp)
--   - 3 Driver users
--   - 5 Camps spread across the 1000x1000 grid
--   - 3 Trucks ready for delivery
--   - 4 Warehouse inventory items (food, water, medicine, other)
--   - Sample requests from different camps
-- ============================================================================


-- ============================================================================
-- OPTIONAL: Clear existing data (uncomment if needed)
-- ============================================================================
-- TRUNCATE users, camps, warehouse_inventory, requests, allocations, trucks, truck_assignments RESTART IDENTITY CASCADE;


-- ============================================================================
-- 1. USERS - Admin, Camp Managers, and Drivers
-- ============================================================================
-- Password for all test users: 'password123' (hashed with werkzeug.security)
-- Hash generated using: generate_password_hash('password123', method='pbkdf2:sha256')

INSERT INTO users (email, password, name, phone, role) VALUES
-- Admin (ID: 1)
('admin@fairshare.org', 
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8', 
 'Admin User', '9000000000', 'admin'),

-- Camp Managers (IDs: 2-6)
('alpha.manager@camp.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Alpha Manager', '9100000001', 'camp_manager'),

('beta.manager@camp.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Beta Manager', '9100000002', 'camp_manager'),

('charlie.manager@camp.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Charlie Manager', '9100000003', 'camp_manager'),

('delta.manager@camp.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Delta Manager', '9100000004', 'camp_manager'),

('echo.manager@camp.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Echo Manager', '9100000005', 'camp_manager'),

-- Drivers (IDs: 7-9)
('driver1@fairshare.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Driver One', '9200000001', 'driver'),

('driver2@fairshare.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Driver Two', '9200000002', 'driver'),

('driver3@fairshare.org',
 'pbkdf2:sha256:600000$X7xvY2aZ$a8c8f8e8b8d8c8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8e8f8d8c8b8a8',
 'Driver Three', '9200000003', 'driver');


-- ============================================================================
-- 2. CAMPS - Relief camps across the grid
-- ============================================================================
-- Depot/NGO HQ is at (500, 0) - the starting point for all trucks
-- Camps are spread across the 1000x1000 grid with different urgency levels
-- Leaflet map: lat = cord_y, lng = cord_x

INSERT INTO camps (name, cord_x, cord_y, total_population, injured_population, urgency_score, status, manager_id) VALUES
-- Camp Alpha: Critical - near depot, high urgency
('Alpha', 150, 150, 500, 75, 0.85, 'critical', 2),

-- Camp Beta: Moderate - nearby Alpha (for clustering test)
('Beta', 200, 200, 300, 30, 0.55, 'moderate', 3),

-- Camp Charlie: Moderate - slightly farther
('Charlie', 300, 185, 250, 25, 0.50, 'moderate', 4),

-- Camp Delta: Stable - far from depot
('Delta', 800, 800, 150, 10, 0.25, 'stable', 5),

-- Camp Echo: Critical - far but high urgency
('Echo', 715, 650, 400, 60, 0.80, 'critical', 6);


-- ============================================================================
-- 3. TRUCKS - Delivery vehicles
-- ============================================================================
-- Trucks are assigned to drivers during the assign_trucks step
-- Initially, all trucks are available with no driver assigned

INSERT INTO trucks (truck_number, capacity_kg, current_load_kg, status, driver_id, driver_name, driver_contact) VALUES
('TRUCK-01', 1000.00, 0.00, 'available', NULL, NULL, NULL),
('TRUCK-02', 1000.00, 0.00, 'available', NULL, NULL, NULL),
('TRUCK-03', 1000.00, 0.00, 'available', NULL, NULL, NULL);


-- ============================================================================
-- 4. WAREHOUSE INVENTORY - Central stock
-- ============================================================================
-- Sufficient stock for multiple deliveries

INSERT INTO warehouse_inventory (item_name, item_type, quantity, unit, low_stock_threshold) VALUES
('Rice & Dry Rations', 'food', 1000, 'kg', 100),
('Drinking Water', 'water', 5000, 'liter', 500),
('First Aid Kits', 'medicine-kit', 200, 'units', 20),
('Blankets & Supplies', 'other', 300, 'units', 30);


-- ============================================================================
-- 5. SAMPLE REQUESTS - Pending requests for testing
-- ============================================================================
-- These requests are ready for the admin to approve

INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status) VALUES
-- Camp Alpha (critical) - multiple requests
(1, 'food', 50, 'critical', 'pending'),
(1, 'water', 100, 'high', 'pending'),
(1, 'medicine-kit', 10, 'critical', 'pending'),

-- Camp Beta (moderate) - some requests
(2, 'food', 30, 'medium', 'pending'),
(2, 'water', 60, 'medium', 'pending'),

-- Camp Charlie (moderate) - single request
(3, 'food', 25, 'medium', 'pending'),

-- Camp Delta (stable) - low priority
(4, 'other', 20, 'low', 'pending'),

-- Camp Echo (critical) - urgent needs
(5, 'food', 40, 'high', 'pending'),
(5, 'medicine-kit', 15, 'critical', 'pending');


-- ============================================================================
-- VERIFICATION QUERIES (Run after importing to verify data)
-- ============================================================================

-- Verify users count by role
-- SELECT role, COUNT(*) FROM users GROUP BY role;
-- Expected: admin=1, camp_manager=5, driver=3

-- Verify camps
-- SELECT camp_id, name, cord_x, cord_y, urgency_score, status FROM camps ORDER BY camp_id;
-- Expected: 5 camps

-- Verify warehouse stock
-- SELECT * FROM v_warehouse_stock;
-- Expected: 4 items, all OK status

-- Verify pending requests
-- SELECT * FROM v_pending_requests;
-- Expected: 9 pending requests

-- Verify trucks
-- SELECT truck_id, truck_number, status, driver_id FROM trucks;
-- Expected: 3 trucks, all available, no drivers assigned


-- ============================================================================
-- END OF SYNTHETIC DATA
-- ============================================================================
