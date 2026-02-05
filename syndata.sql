/*TRUNCATE TABLE
    allocations,
    requests,
    truck_assignments,
    warehouse_inventory,
    trucks,
    camps,
	users
RESTART IDENTITY CASCADE;*/
----------------------------------------------------------------------------

SELECT id, name, role FROM users ORDER BY id;

-----------------------------------------------------------------------------

INSERT INTO warehouse_inventory
(item_name, item_type, quantity, unit, low_stock_threshold)
VALUES
('Rice', 'food', 2000, 'kg', 500),
('Drinking Water', 'water', 5000, 'liter', 1000),
('Basic Medicine Kit', 'medicine-kit', 800, 'units', 200),
('Blankets', 'other', 300, 'units', 100);

-------------------------------------------------------------------------------

INSERT INTO requests
(camp_id, item_type, quantity_needed, priority, request_date)
VALUES
-- Charlie (high urgency)
(3, 'food', 600, 'critical', NOW() - INTERVAL '5 days'),
(3, 'water', 1200, 'critical', NOW() - INTERVAL '3 days'),
(3, 'medicine-kit', 180, 'high', NOW() - INTERVAL '1 day'),

-- Echo
(4, 'food', 520, 'high', NOW() - INTERVAL '4 days'),
(4, 'water', 900, 'high', NOW() - INTERVAL '2 days'),
(4, 'medicine-kit', 150, 'high', NOW() - INTERVAL '1 day'),

-- Beta
(2, 'food', 400, 'medium', NOW() - INTERVAL '6 days'),
(2, 'water', 700, 'medium', NOW() - INTERVAL '4 days'),

-- Alpha
(1, 'food', 350, 'medium', NOW() - INTERVAL '5 days'),
(1, 'water', 600, 'medium', NOW() - INTERVAL '3 days'),

-- Jogo (low urgency)
(5, 'food', 150, 'low', NOW() - INTERVAL '6 days'),
(5, 'water', 300, 'low', NOW() - INTERVAL '4 days');

/*UPDATE requests
SET
    fulfilled_quantity = quantity_needed - 50,
    status = 'partially_approved',
    admin_note = 'Partial due to limited stock'
WHERE priority IN ('critical', 'high');*/

---------------------------------------------------------------------------------------------------

INSERT INTO trucks
(truck_number, capacity_kg, driver_id, driver_name, driver_contact)
VALUES	
('TRUCK-01', 1200, 4, 'Driver A', '900000001'),
('TRUCK-02', 1000, 5, 'Driver B', '900000002'),
('TRUCK-03', 1500, 6, 'Driver C', '900000003');
------------------------------------------------------------------------------------

SELECT truck_id, truck_number, driver_id
FROM trucks;



--------------------------------------------------------------------------------


