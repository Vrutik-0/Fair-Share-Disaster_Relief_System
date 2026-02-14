-- OPTIONAL: Clear existing data 

-- TRUNCATE users, camps,warehouse_inventory, requests, allocations, trucks, truck_assignments ,notifications RESTART IDENTITY CASCADE;

-- ============================================================================
-- SYNTHETIC DATA
-- Scenario: Gujarat Relief — Ahmedabad (2-Day Demo)
--
-- USERS:   1 Admin, 2 Camp Managers (C1, C2), 3 Drivers
-- CAMPS:   5 camps across Ahmedabad city 
--
-- Password for ALL users: demo1234
-- Hashed with werkzeug: generate_password_hash("demo1234")
-- ============================================================================


-- ============================================================================
-- 1. USERS  (1 Admin + 2 Camp Managers + 3 Drivers )
-- Password: demo1234

INSERT INTO users (name, email, phone, role, password) VALUES
-- id=1  ADMIN
('Aarav Patel',       'admin@fairshare.org',    '9876543210', 'admin',
 'scrypt:32768:8:1$XKxjF3qLmN7yTBvR$a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4'),

-- id=2  CAMP MANAGER 1 (manages 3 camps — west-central cluster)
('Priya Sharma',      'cm1@fairshare.org',      '9876543211', 'camp_manager',
 'scrypt:32768:8:1$XKxjF3qLmN7yTBvR$a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4'),

-- id=3  CAMP MANAGER 2 (manages 2 camps — east cluster)
('Rohan Mehta',       'cm2@fairshare.org',      '9876543212', 'camp_manager',
 'scrypt:32768:8:1$XKxjF3qLmN7yTBvR$a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4'),

-- id=4  DRIVER 1
('Vikram Singh',      'driver1@fairshare.org',  '9876543213', 'driver',
 'scrypt:32768:8:1$XKxjF3qLmN7yTBvR$a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4'),

-- id=5  DRIVER 2
('Amit Yadav',        'driver2@fairshare.org',  '9876543214', 'driver',
 'scrypt:32768:8:1$XKxjF3qLmN7yTBvR$a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4'),

-- id=6  DRIVER 3
('Suresh Kumar',      'driver3@fairshare.org',  '9876543215', 'driver',
 'scrypt:32768:8:1$XKxjF3qLmN7yTBvR$a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4');


-- ============================================================================
-- CAMPS — 5 camps within Ahmedabad on 0-1000 grid
-- CAMPS — 5 camps within Ahmedabad on 0-1000 grid
--   WEST SIDE (3 camps, nearby cluster):
--   EAST SIDE (2 camps, across Sabarmati river):

INSERT INTO camps (name, cord_x, cord_y, total_population, injured_population, urgency_score, status, manager_id, created_at) VALUES
	
('Camp Alpha',  350, 550,  850, 600,  0.75, 'critical',  2, NOW() - INTERVAL '2 days'),
('Camp Bravo ',  420, 480,  400, 150,  0.38, 'moderate',  2, NOW() - INTERVAL '2 days'),
('Camp Charlie',500, 520,  620, 400,  0.64, 'moderate',  2, NOW() - INTERVAL '2 days'),

('Camp Delta',        700, 700,  950, 750,  0.84, 'critical',  3, NOW() - INTERVAL '2 days'),
('Camp Echo',          650, 600,  300, 100,  0.32, 'moderate',  3, NOW() - INTERVAL '2 days');

-- ============================================================================
-- WAREHOUSE

INSERT INTO warehouse_inventory (item_name, item_type, quantity, unit, low_stock_threshold) VALUES
('Rice & Rations',     'food',          1500,  'kg',     200),
('Drinking Water',     'water',         2000,  'liter',  300),
('First Aid Kits',     'medicine-kit',   350,  'units',   50);

-- ============================================================================
-- TRUCKS

INSERT INTO trucks (truck_number, capacity_kg, current_load_kg, status) VALUES
('GJ-01-HA-1234',  500.00,  0, 'available'),   -- truck_id=1
('GJ-01-PP-5678',  450.00,  0, 'available'),   -- truck_id=2
('GJ-01-EN-9012',  400.00,  0, 'available');    -- truck_id=3


-- ============================================================================
-- 5. REQUESTS — Day 1

-- ── Camp Alpha - Paldi (urgency=0.75 → critical) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(1, 'food',          300, 'critical', 'pending', NOW() - INTERVAL '1 day 10 hours'),
(1, 'water',         400, 'critical', 'pending', NOW() - INTERVAL '1 day 10 hours'),
(1, 'medicine-kit',  100, 'critical', 'pending', NOW() - INTERVAL '1 day 10 hours');

-- ── Camp Bravo - Vastrapur (urgency=0.38 → medium) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(2, 'food',          120, 'medium',   'pending', NOW() - INTERVAL '1 day 9 hours'),
(2, 'water',         150, 'medium',   'pending', NOW() - INTERVAL '1 day 9 hours');

-- ── Camp Charlie - Maninagar (urgency=0.64 → high) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(3, 'food',          200, 'high',     'pending', NOW() - INTERVAL '1 day 8 hours'),
(3, 'water',         250, 'high',     'pending', NOW() - INTERVAL '1 day 8 hours'),
(3, 'medicine-kit',   60, 'high',     'pending', NOW() - INTERVAL '1 day 8 hours');

-- ── Camp Delta - Naroda (urgency=0.84 → critical) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(4, 'food',          350, 'critical', 'pending', NOW() - INTERVAL '1 day 7 hours'),
(4, 'water',         500, 'critical', 'pending', NOW() - INTERVAL '1 day 7 hours'),
(4, 'medicine-kit',  120, 'critical', 'pending', NOW() - INTERVAL '1 day 7 hours');

-- ── Camp Echo - Bodakdev (urgency=0.32 → medium) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(5, 'food',          100, 'medium',   'pending', NOW() - INTERVAL '1 day 6 hours'),
(5, 'water',         120, 'medium',   'pending', NOW() - INTERVAL '1 day 6 hours');


-- ============================================================================
-- 6. REQUESTS — DAY 2 

-- ── Camp Alpha — AFTERSHOCK EMERGENCY (new injuries, critical) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(1, 'medicine-kit',  80,  'critical', 'pending', NOW() - INTERVAL '3 hours'),
(1, 'water',        200,  'critical', 'pending', NOW() - INTERVAL '3 hours');

-- ── Camp Charlie — replenishment (high) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(3, 'food',         150,  'high',     'pending', NOW() - INTERVAL '2 hours');

-- ── Camp Delta — replenishment (critical) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(4, 'food',         200,  'critical', 'pending', NOW() - INTERVAL '2 hours'),
(4, 'water',        300,  'critical', 'pending', NOW() - INTERVAL '2 hours');

-- ── Camp Echo — new need (medium) ──
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(5, 'medicine-kit',  30,  'medium',   'pending', NOW() - INTERVAL '1 hour');



-- VERIFICATION

-- SELECT id, name, email, role FROM users ORDER BY id;
-- SELECT camp_id, name, cord_x, cord_y, total_population, injured_population, urgency_score, status, manager_id FROM camps ORDER BY camp_id;
-- SELECT * FROM warehouse_inventory;
-- SELECT request_id, camp_id, item_type, quantity_needed, priority, status, request_date FROM requests ORDER BY request_date;
-- SELECT * FROM trucks;
-- SELECT * FROM notifications ORDER BY created_at;