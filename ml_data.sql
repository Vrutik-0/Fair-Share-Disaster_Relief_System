-- ML TRAINING DATA — 14 Days
-- Scenario: Gujarat Relief — Ahmedabad
--
-- Uses 5 camps: Alpha, Bravo, Charlie, Delta, Echo
-- ALL requests are 'delivered' — no pending or partially_approved remain
--
-- RUN AFTER: data.sql and syndata.sql
-- ============================================================================


-- STEP 0: Clear old request data & restock warehouse for 14-day scenario
DELETE FROM allocations;
DELETE FROM requests;

-- Restock warehouse with large quantities for 14-day operation
UPDATE warehouse_inventory SET quantity = 50000 WHERE item_type = 'food';
UPDATE warehouse_inventory SET quantity = 70000 WHERE item_type = 'water';
UPDATE warehouse_inventory SET quantity = 15000 WHERE item_type = 'medicine-kit';


-- ============================================================================
-- DAY 1

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',          1200, 1200, 'critical', 'delivered', 'Emergency dispatch',    NOW() - INTERVAL '14 days'),
(1, 'water',         1800, 1800, 'critical', 'delivered', 'Emergency dispatch',    NOW() - INTERVAL '14 days'),
(1, 'medicine-kit',  1500, 1500, 'critical', 'delivered', 'Emergency dispatch',    NOW() - INTERVAL '14 days'),
(2, 'food',           600, 600,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '14 days'),
(2, 'water',          800, 800,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '14 days'),
(3, 'food',           900, 900,  'high',     'delivered', 'Delivered',             NOW() - INTERVAL '14 days'),
(3, 'water',         1200, 1200, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '14 days'),
(3, 'medicine-kit',   800, 800,  'high',     'delivered', 'Delivered',             NOW() - INTERVAL '14 days'),
(4, 'food',          1500, 1500, 'critical', 'delivered', 'Emergency dispatch',    NOW() - INTERVAL '14 days'),
(4, 'water',         2200, 2200, 'critical', 'delivered', 'Emergency dispatch',    NOW() - INTERVAL '14 days'),
(4, 'medicine-kit',  1800, 1800, 'critical', 'delivered', 'Emergency dispatch',    NOW() - INTERVAL '14 days'),
(5, 'food',           400, 400,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '14 days'),
(5, 'water',          500, 500,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '14 days');


-- ============================================================================
-- DAY 2

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',          1100, 1100, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(1, 'water',         1600, 1600, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(1, 'medicine-kit',  2000, 2000, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(2, 'food',           500, 500,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(2, 'water',          700, 700,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(3, 'food',           850, 850,  'high',     'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(3, 'water',         1100, 1100, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(3, 'medicine-kit',  1000, 1000, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(4, 'food',          1600, 1600, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(4, 'water',         2500, 2500, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(4, 'medicine-kit',  2200, 2200, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(5, 'food',           350, 350,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(5, 'water',          450, 450,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '13 days'),
(5, 'medicine-kit',   200, 200,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '13 days');


-- ============================================================================
-- DAY 3

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',          1300, 1300, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(1, 'water',         1900, 1900, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(1, 'medicine-kit',  2500, 2500, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(2, 'food',           550, 550,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '12 days'),
(2, 'water',          750, 750,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '12 days'),
(2, 'medicine-kit',   300, 300,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '12 days'),
(3, 'food',          1000, 1000, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(3, 'water',         1300, 1300, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(3, 'medicine-kit',  1200, 1200, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(4, 'food',          1800, 1800, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(4, 'water',         2800, 2800, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(4, 'medicine-kit',  2500, 2500, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '12 days'),
(5, 'food',           400, 400,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '12 days'),
(5, 'water',          500, 500,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '12 days'),
(5, 'medicine-kit',   250, 250,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '12 days');


-- ============================================================================
-- DAY 4

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',          1100, 1100, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(1, 'water',         1700, 1700, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(1, 'medicine-kit',  2000, 2000, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(2, 'food',           500, 500,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(2, 'water',          650, 650,  'medium',   'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(3, 'food',           900, 900,  'high',     'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(3, 'water',         1200, 1200, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(3, 'medicine-kit',  1100, 1100, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(4, 'food',          1500, 1500, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(4, 'water',         2400, 2400, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(4, 'medicine-kit',  2000, 2000, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(5, 'food',           380, 380,  'low',      'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(5, 'water',          480, 480,  'low',      'delivered', 'Delivered',             NOW() - INTERVAL '11 days'),
(5, 'medicine-kit',   220, 220,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '11 days');


-- ============================================================================
-- DAY 5

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',          1000, 1000, 'high',     'delivered', 'Delivered on time',     NOW() - INTERVAL '10 days'),
(1, 'water',         1500, 1500, 'high',     'delivered', 'Delivered',             NOW() - INTERVAL '10 days'),
(1, 'medicine-kit',  1800, 1800, 'critical', 'delivered', 'Full delivery',         NOW() - INTERVAL '10 days'),
(2, 'food',           450, 450,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '10 days'),
(2, 'water',          600, 600,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '10 days'),
(3, 'food',           800, 800,  'high',     'delivered', 'OK',                    NOW() - INTERVAL '10 days'),
(3, 'water',         1100, 1100, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '10 days'),
(3, 'medicine-kit',   900, 900,  'high',     'delivered', 'Full',                  NOW() - INTERVAL '10 days'),
(4, 'food',          1400, 1400, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '10 days'),
(4, 'water',         2200, 2200, 'critical', 'delivered', 'Delivered',             NOW() - INTERVAL '10 days'),
(4, 'medicine-kit',  1800, 1800, 'critical', 'delivered', 'Full',                  NOW() - INTERVAL '10 days'),
(5, 'food',           350, 350,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '10 days'),
(5, 'water',          450, 450,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '10 days');


-- ============================================================================
-- DAY 6

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           950, 950,  'high',     'delivered', 'Routine delivery',      NOW() - INTERVAL '9 days'),
(1, 'water',         1400, 1400, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(1, 'medicine-kit',  1500, 1500, 'high',     'delivered', 'Injury rate declining', NOW() - INTERVAL '9 days'),
(2, 'food',           400, 400,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(2, 'water',          550, 550,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(3, 'food',           750, 750,  'high',     'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(3, 'water',         1000, 1000, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(3, 'medicine-kit',   700, 700,  'medium',   'delivered', 'Downgraded priority',   NOW() - INTERVAL '9 days'),
(4, 'food',          1300, 1300, 'critical', 'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(4, 'water',         2000, 2000, 'critical', 'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(4, 'medicine-kit',  1500, 1500, 'high',     'delivered', 'Priority lowered',      NOW() - INTERVAL '9 days'),
(5, 'food',           300, 300,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '9 days'),
(5, 'water',          400, 400,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '9 days');


-- ============================================================================
-- DAY 7

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           900, 900,  'high',     'delivered', 'Steady',                NOW() - INTERVAL '8 days'),
(1, 'water',         1300, 1300, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '8 days'),
(1, 'medicine-kit',  1200, 1200, 'high',     'delivered', 'Treatment ongoing',     NOW() - INTERVAL '8 days'),
(2, 'food',           420, 420,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '8 days'),
(2, 'water',          580, 580,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '8 days'),
(2, 'medicine-kit',   200, 200,  'low',      'delivered', 'Routine',               NOW() - INTERVAL '8 days'),
(3, 'food',           700, 700,  'medium',   'delivered', 'Priority lowered',      NOW() - INTERVAL '8 days'),
(3, 'water',          950, 950,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '8 days'),
(3, 'medicine-kit',   600, 600,  'medium',   'delivered', 'Stable',                NOW() - INTERVAL '8 days'),
(4, 'food',          1200, 1200, 'high',     'delivered', 'Improving',             NOW() - INTERVAL '8 days'),
(4, 'water',         1800, 1800, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '8 days'),
(4, 'medicine-kit',  1300, 1300, 'high',     'delivered', 'High injury load',      NOW() - INTERVAL '8 days'),
(5, 'food',           320, 320,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '8 days'),
(5, 'water',          420, 420,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '8 days'),
(5, 'medicine-kit',   150, 150,  'low',      'delivered', 'Routine',               NOW() - INTERVAL '8 days');


-- ============================================================================
-- DAY 8 — Rain event, water surge

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           880, 880,  'high',     'delivered', 'OK',                    NOW() - INTERVAL '7 days'),
(1, 'water',         1600, 1600, 'critical', 'delivered', 'Rain surge — delivered', NOW() - INTERVAL '7 days'),
(1, 'medicine-kit',  1100, 1100, 'medium',   'delivered', 'Declining need',        NOW() - INTERVAL '7 days'),
(2, 'food',           400, 400,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '7 days'),
(2, 'water',          800, 800,  'high',     'delivered', 'Rain stockpile — delivered', NOW() - INTERVAL '7 days'),
(3, 'food',           680, 680,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '7 days'),
(3, 'water',         1200, 1200, 'high',     'delivered', 'Rain prep — delivered', NOW() - INTERVAL '7 days'),
(3, 'medicine-kit',   550, 550,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '7 days'),
(4, 'food',          1150, 1150, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '7 days'),
(4, 'water',         2200, 2200, 'critical', 'delivered', 'Rain surge — delivered', NOW() - INTERVAL '7 days'),
(4, 'medicine-kit',  1200, 1200, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '7 days'),
(5, 'food',           300, 300,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '7 days'),
(5, 'water',          600, 600,  'medium',   'delivered', 'Rain prep — delivered', NOW() - INTERVAL '7 days'),
(5, 'medicine-kit',   130, 130,  'low',      'delivered', 'Routine',               NOW() - INTERVAL '7 days');


-- ============================================================================
-- DAY 9 — Post-rain illness spike

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           850, 850,  'medium',   'delivered', 'Declining trend',       NOW() - INTERVAL '6 days'),
(1, 'water',         1300, 1300, 'high',     'delivered', 'Back to normal',        NOW() - INTERVAL '6 days'),
(1, 'medicine-kit',  1300, 1300, 'high',     'delivered', 'Illness — delivered',   NOW() - INTERVAL '6 days'),
(2, 'food',           380, 380,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '6 days'),
(2, 'water',          560, 560,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '6 days'),
(2, 'medicine-kit',   250, 250,  'medium',   'delivered', 'Illness prevention',    NOW() - INTERVAL '6 days'),
(3, 'food',           650, 650,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '6 days'),
(3, 'water',          920, 920,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '6 days'),
(3, 'medicine-kit',   700, 700,  'high',     'delivered', 'Post-rain — delivered', NOW() - INTERVAL '6 days'),
(4, 'food',          1100, 1100, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '6 days'),
(4, 'water',         1700, 1700, 'high',     'delivered', 'Normalized',            NOW() - INTERVAL '6 days'),
(4, 'medicine-kit',  1500, 1500, 'critical', 'delivered', 'Outbreak — delivered',  NOW() - INTERVAL '6 days'),
(5, 'food',           280, 280,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '6 days'),
(5, 'water',          400, 400,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '6 days'),
(5, 'medicine-kit',   180, 180,  'medium',   'delivered', 'Prevention kits',       NOW() - INTERVAL '6 days');


-- ============================================================================
-- DAY 10

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           800, 800,  'medium',   'delivered', 'Recovery mode',         NOW() - INTERVAL '5 days'),
(1, 'water',         1200, 1200, 'medium',   'delivered', 'Stable',                NOW() - INTERVAL '5 days'),
(1, 'medicine-kit',  1100, 1100, 'high',     'delivered', 'Illness treatment',     NOW() - INTERVAL '5 days'),
(2, 'food',           350, 350,  'low',      'delivered', 'Baseline',              NOW() - INTERVAL '5 days'),
(2, 'water',          500, 500,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '5 days'),
(2, 'medicine-kit',   200, 200,  'low',      'delivered', 'Routine',               NOW() - INTERVAL '5 days'),
(3, 'food',           620, 620,  'medium',   'delivered', 'Declining',             NOW() - INTERVAL '5 days'),
(3, 'water',          880, 880,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '5 days'),
(3, 'medicine-kit',   600, 600,  'medium',   'delivered', 'Illness contained',     NOW() - INTERVAL '5 days'),
(4, 'food',          1050, 1050, 'high',     'delivered', 'Improving',             NOW() - INTERVAL '5 days'),
(4, 'water',         1600, 1600, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '5 days'),
(4, 'medicine-kit',  1300, 1300, 'high',     'delivered', 'Still treating',        NOW() - INTERVAL '5 days'),
(5, 'food',           260, 260,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '5 days'),
(5, 'water',          380, 380,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '5 days'),
(5, 'medicine-kit',   160, 160,  'low',      'delivered', 'Routine',               NOW() - INTERVAL '5 days');


-- ============================================================================
-- DAY 11

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           750, 750,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(1, 'water',         1100, 1100, 'medium',   'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(1, 'medicine-kit',   900, 900,  'medium',   'delivered', 'Winding down',          NOW() - INTERVAL '4 days'),
(2, 'food',           330, 330,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(2, 'water',          480, 480,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(3, 'food',           600, 600,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(3, 'water',          850, 850,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(3, 'medicine-kit',   500, 500,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(4, 'food',          1000, 1000, 'high',     'delivered', 'Still high pop',        NOW() - INTERVAL '4 days'),
(4, 'water',         1500, 1500, 'high',     'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(4, 'medicine-kit',  1100, 1100, 'high',     'delivered', 'Ongoing treatment',     NOW() - INTERVAL '4 days'),
(5, 'food',           250, 250,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(5, 'water',          360, 360,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '4 days'),
(5, 'medicine-kit',   140, 140,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '4 days');


-- ============================================================================
-- DAY 12

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           700, 700,  'medium',   'delivered', 'Near baseline',         NOW() - INTERVAL '3 days'),
(1, 'water',         1050, 1050, 'medium',   'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(1, 'medicine-kit',   750, 750,  'medium',   'delivered', 'Declining',             NOW() - INTERVAL '3 days'),
(2, 'food',           320, 320,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(2, 'water',          460, 460,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(2, 'medicine-kit',   150, 150,  'low',      'delivered', 'Routine',               NOW() - INTERVAL '3 days'),
(3, 'food',           580, 580,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(3, 'water',          800, 800,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(3, 'medicine-kit',   450, 450,  'low',      'delivered', 'Near baseline',         NOW() - INTERVAL '3 days'),
(4, 'food',           950, 950,  'medium',   'delivered', 'Declining',             NOW() - INTERVAL '3 days'),
(4, 'water',         1400, 1400, 'medium',   'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(4, 'medicine-kit',   900, 900,  'medium',   'delivered', 'Improving',             NOW() - INTERVAL '3 days'),
(5, 'food',           240, 240,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(5, 'water',          340, 340,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '3 days'),
(5, 'medicine-kit',   120, 120,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '3 days');


-- ============================================================================
-- DAY 13 — Evacuee spike at Delta, handled same day

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           680, 680,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(1, 'water',         1000, 1000, 'medium',   'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(1, 'medicine-kit',   650, 650,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(2, 'food',           310, 310,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(2, 'water',          440, 440,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(3, 'food',           560, 560,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(3, 'water',          780, 780,  'medium',   'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(3, 'medicine-kit',   400, 400,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(4, 'food',          1400, 1400, 'critical', 'delivered', 'Evacuee surge — emergency dispatch', NOW() - INTERVAL '2 days'),
(4, 'water',         2000, 2000, 'critical', 'delivered', 'Urgent — fully met',    NOW() - INTERVAL '2 days'),
(4, 'medicine-kit',  1200, 1200, 'critical', 'delivered', 'Evacuee medical — full', NOW() - INTERVAL '2 days'),
(5, 'food',           230, 230,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(5, 'water',          330, 330,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '2 days'),
(5, 'medicine-kit',   110, 110,  'low',      'delivered', 'OK',                    NOW() - INTERVAL '2 days');


-- ============================================================================
-- DAY 14 — All caught up. NO pending requests.

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           650, 650,  'medium',   'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(1, 'water',          980, 980,  'medium',   'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(1, 'medicine-kit',   600, 600,  'medium',   'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(2, 'food',           300, 300,  'low',      'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(2, 'water',          430, 430,  'low',      'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(2, 'medicine-kit',   130, 130,  'low',      'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(3, 'food',           550, 550,  'medium',   'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(3, 'water',          760, 760,  'medium',   'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(3, 'medicine-kit',   380, 380,  'low',      'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(4, 'food',          1200, 1200, 'high',     'delivered', 'Evacuee load stabilized', NOW() - INTERVAL '1 day'),
(4, 'water',         1800, 1800, 'high',     'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(4, 'medicine-kit',  1000, 1000, 'high',     'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(5, 'food',           220, 220,  'low',      'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(5, 'water',          320, 320,  'low',      'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day'),
(5, 'medicine-kit',   100, 100,  'low',      'delivered', 'Fully delivered',       NOW() - INTERVAL '1 day');


-- ============================================================================
-- FINAL WAREHOUSE RESTOCK — healthy stock after 14 days of operations
UPDATE warehouse_inventory SET quantity = 12000 WHERE item_type = 'food';
UPDATE warehouse_inventory SET quantity = 18000 WHERE item_type = 'water';
UPDATE warehouse_inventory SET quantity = 4000  WHERE item_type = 'medicine-kit';