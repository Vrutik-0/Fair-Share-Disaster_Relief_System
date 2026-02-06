-- This file contains all table definitions, constraints, triggers, and views.
-- Run this file FIRST to set up the database structure.
-- Then run syndata.sql to populate with test data.


-- ============================================================================
-- 1. USERS TABLE
-- Stores all system users: admins, camp managers, and drivers
-- ============================================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,           -- Hashed password (werkzeug)
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL                 -- 'admin', 'camp_manager', 'driver'
        CHECK (role IN ('admin', 'camp_manager', 'driver')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 2. CAMPS TABLE
-- Relief camps with location coordinates (0-1000 grid) and urgency scores
-- ============================================================================
CREATE TABLE camps (
    camp_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    cord_x INTEGER NOT NULL                   -- X coordinate on 1000x1000 grid
        CHECK (cord_x BETWEEN 0 AND 1000),
    cord_y INTEGER NOT NULL                   -- Y coordinate on 1000x1000 grid
        CHECK (cord_y BETWEEN 0 AND 1000),
    total_population INTEGER DEFAULT 0
        CHECK (total_population >= 0),
    injured_population INTEGER DEFAULT 0
        CHECK (injured_population >= 0),
    urgency_score FLOAT DEFAULT 0.0           -- Calculated: 0.0 (low) to 1.0 (critical)
        CHECK (urgency_score BETWEEN 0 AND 1),
    status VARCHAR(20) DEFAULT 'moderate'     -- 'critical', 'moderate', 'stable'
        CHECK (status IN ('critical', 'moderate', 'stable')),
    manager_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_coordinates UNIQUE (cord_x, cord_y)
);

-- Auto-update timestamp trigger for camps
CREATE OR REPLACE FUNCTION update_camps_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_camps
BEFORE UPDATE ON camps
FOR EACH ROW
EXECUTE FUNCTION update_camps_timestamp();


-- ============================================================================
-- 3. WAREHOUSE INVENTORY TABLE
-- Central warehouse stock management
-- ============================================================================
CREATE TABLE warehouse_inventory (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(50),                   
    item_type VARCHAR(30) NOT NULL            -- Category: food, water, medicine-kit, other
        CHECK (item_type IN ('food', 'water', 'medicine-kit', 'other')),
    quantity INTEGER NOT NULL DEFAULT 0
        CHECK (quantity >= 0),
    unit VARCHAR(20) NOT NULL                 -- kg, liter, units
        CHECK (unit IN ('kg', 'liter', 'units')),
    low_stock_threshold INTEGER NOT NULL DEFAULT 0
        CHECK (low_stock_threshold >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_item_type_unit UNIQUE (item_type, unit)
);


-- ============================================================================
-- 4. REQUESTS TABLE
-- Resource requests from camps to central warehouse
-- ============================================================================
CREATE TABLE requests (
    request_id SERIAL PRIMARY KEY,
    camp_id INTEGER NOT NULL REFERENCES camps(camp_id) ON DELETE CASCADE,
    item_type VARCHAR(30) NOT NULL
        CHECK (item_type IN ('food', 'water', 'medicine-kit', 'other')),
    quantity_needed INTEGER NOT NULL
        CHECK (quantity_needed > 0),
    fulfilled_quantity INTEGER DEFAULT 0
        CHECK (fulfilled_quantity >= 0),
    priority VARCHAR(20) DEFAULT 'medium'     -- Auto-calculated or manually set
        CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN (
            'pending',
            'partially_approved',
            'approved',
            'dispatched',
            'delivered',
            'discarded'
        )),
    admin_note TEXT,                          -- Notes from admin (approval/rejection reason)
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 5. TRUCKS TABLE
-- Delivery vehicles with capacity and driver assignment
-- ============================================================================
CREATE TABLE trucks (
    truck_id SERIAL PRIMARY KEY,
    truck_number VARCHAR(20) UNIQUE NOT NULL,
    capacity_kg NUMERIC(10,2) NOT NULL        -- Maximum load capacity in kg
        CHECK (capacity_kg > 0),
    current_load_kg NUMERIC(10,2) DEFAULT 0
        CHECK (current_load_kg >= 0),
    status VARCHAR(30) DEFAULT 'available'
        CHECK (status IN (
            'available',
            'loading',
            'in_transit',
            'maintenance'
        )),
    driver_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    driver_name VARCHAR(100),                 -- Cached for quick access
    driver_contact VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================================
-- 6. ALLOCATIONS TABLE
-- Links approved requests to delivery assignments
-- ============================================================================
CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES requests(request_id) ON DELETE CASCADE,
    allocated_quantity INTEGER NOT NULL
        CHECK (allocated_quantity > 0),
    item_weight NUMERIC(10,2),                -- Weight for knapsack optimization
    allocation_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_status VARCHAR(30) DEFAULT 'scheduled'
        CHECK (delivery_status IN (
            'scheduled',
            'in_transit',
            'delivered',
            'failed'
        )),
    delivery_datetime TIMESTAMP,              -- When delivery was completed
    truck_id INTEGER REFERENCES trucks(truck_id) ON DELETE SET NULL
);


-- ============================================================================
-- 7. TRUCK ASSIGNMENTS TABLE
-- Maps trucks to camps they need to visit (clustering result)
-- ============================================================================
CREATE TABLE truck_assignments (
    assignment_id SERIAL PRIMARY KEY,
    truck_id INTEGER NOT NULL REFERENCES trucks(truck_id) ON DELETE CASCADE,
    camp_id INTEGER NOT NULL REFERENCES camps(camp_id) ON DELETE CASCADE,
    visit_order INTEGER,                      -- Order of visit (greedy prioritization result)
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (truck_id, camp_id)
);


-- ============================================================================
-- 8. SYSTEM STATE TABLE
-- Global system flags for delivery execution lock
-- ============================================================================
CREATE TABLE system_state (
    id SERIAL PRIMARY KEY,
    is_execution_live BOOLEAN DEFAULT FALSE,  -- TRUE when deliveries are in progress
    executed_at TIMESTAMP                     -- When execution started
);

-- Initialize system state (required for app to work)
INSERT INTO system_state (is_execution_live) VALUES (FALSE);


-- ============================================================================
-- USEFUL VIEWS FOR MONITORING
-- ============================================================================

-- View: Current truck assignments with camp details
CREATE OR REPLACE VIEW v_truck_assignments AS
SELECT 
    t.truck_id,
    t.truck_number,
    t.status AS truck_status,
    c.camp_id,
    c.name AS camp_name,
    c.urgency_score,
    ta.visit_order,
    u.name AS driver_name
FROM truck_assignments ta
JOIN trucks t ON ta.truck_id = t.truck_id
JOIN camps c ON ta.camp_id = c.camp_id
LEFT JOIN users u ON t.driver_id = u.id
ORDER BY t.truck_id, ta.visit_order;

-- View: Pending requests summary
CREATE OR REPLACE VIEW v_pending_requests AS
SELECT 
    r.request_id,
    c.name AS camp_name,
    r.item_type,
    r.quantity_needed,
    r.fulfilled_quantity,
    (r.quantity_needed - r.fulfilled_quantity) AS remaining,
    r.priority,
    r.status,
    c.urgency_score
FROM requests r
JOIN camps c ON r.camp_id = c.camp_id
WHERE r.status IN ('pending', 'partially_approved')
ORDER BY 
    CASE r.priority 
        WHEN 'critical' THEN 1 
        WHEN 'high' THEN 2 
        WHEN 'medium' THEN 3 
        ELSE 4 
    END;

-- View: Allocation status with delivery info
CREATE OR REPLACE VIEW v_allocations_status AS
SELECT 
    a.allocation_id,
    c.name AS camp_name,
    r.item_type,
    a.allocated_quantity,
    a.delivery_status,
    t.truck_number,
    u.name AS driver_name
FROM allocations a
JOIN requests r ON a.request_id = r.request_id
JOIN camps c ON r.camp_id = c.camp_id
LEFT JOIN trucks t ON a.truck_id = t.truck_id
LEFT JOIN users u ON t.driver_id = u.id
ORDER BY a.allocation_datetime DESC;

-- View: Warehouse stock summary
CREATE OR REPLACE VIEW v_warehouse_stock AS
SELECT 
    item_type,
    item_name,
    quantity,
    unit,
    low_stock_threshold,
    CASE 
        WHEN quantity <= low_stock_threshold THEN 'LOW STOCK'
        WHEN quantity <= low_stock_threshold * 2 THEN 'WARNING'
        ELSE 'OK'
    END AS stock_status
FROM warehouse_inventory
ORDER BY item_type;

-- View: Camp overview with urgency
CREATE OR REPLACE VIEW v_camps_overview AS
SELECT 
    c.camp_id,
    c.name,
    c.cord_x,
    c.cord_y,
    c.total_population,
    c.injured_population,
    c.urgency_score,
    c.status,
    u.name AS manager_name,
    (SELECT COUNT(*) FROM requests r WHERE r.camp_id = c.camp_id AND r.status = 'pending') AS pending_requests
FROM camps c
LEFT JOIN users u ON c.manager_id = u.id
ORDER BY c.urgency_score DESC;


-- ============================================================================
-- USEFUL QUERIES FOR DEBUGGING (Uncomment to use)
-- ============================================================================

-- Check all users:
-- SELECT id, name, email, role FROM users ORDER BY id;

-- Check camp urgency distribution:
-- SELECT status, COUNT(*), ROUND(AVG(urgency_score)::numeric, 2) as avg_urgency 
-- FROM camps GROUP BY status;

-- Check warehouse stock:
-- SELECT * FROM v_warehouse_stock;

-- Check pending requests:
-- SELECT * FROM v_pending_requests;

-- Check truck assignments:
-- SELECT * FROM v_truck_assignments;

-- Check allocation status:
-- SELECT * FROM v_allocations_status;

-- Check camps overview:
-- SELECT * FROM v_camps_overview;

-- Check truck-allocation relationship:
-- SELECT
--     a.allocation_id,
--     a.truck_id,
--     r.camp_id,
--     t.truck_number,
--     t.driver_id
-- FROM allocations a
-- JOIN requests r ON a.request_id = r.request_id
-- JOIN trucks t ON a.truck_id = t.truck_id;