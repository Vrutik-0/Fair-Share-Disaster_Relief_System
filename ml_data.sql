-- ML TRAINING DATA — 14 Days (Quantities in Thousands)
-- Scenario: Gujarat Earthquake Relief — Extended Timeline

-- Uses existing camps: Alpha(1), Bravo(2), Charlie(3), Delta(4), Echo(5)
-- Uses existing warehouse with restocked quantities
-- Quantities in THOUSANDS (e.g., 1200 = 1,200 kg/liters/units)
--
-- RUN AFTER: data.sql and syndata.sql
-- NOTE: Clear old requests first if needed
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

-- Camp Alpha (urgency=0.75, critical, pop=850, injured=600)
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(1, 'food',          1200, 'critical', 'pending',              NOW() - INTERVAL '14 days'),
(1, 'water',         1800, 'critical', 'pending',              NOW() - INTERVAL '14 days'),
(1, 'medicine-kit',  1500, 'critical', 'pending',              NOW() - INTERVAL '14 days');

-- Camp Bravo (urgency=0.38, moderate, pop=400, injured=150)
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(2, 'food',           600, 'medium',   'pending',              NOW() - INTERVAL '14 days'),
(2, 'water',          800, 'medium',   'pending',              NOW() - INTERVAL '14 days');

-- Camp Charlie (urgency=0.64, moderate-high, pop=620, injured=400)
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(3, 'food',           900, 'high',     'pending',              NOW() - INTERVAL '14 days'),
(3, 'water',         1200, 'high',     'pending',              NOW() - INTERVAL '14 days'),
(3, 'medicine-kit',   800, 'high',     'pending',              NOW() - INTERVAL '14 days');

-- Camp Delta (urgency=0.84, critical, pop=950, injured=750)
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(4, 'food',          1500, 'critical', 'pending',              NOW() - INTERVAL '14 days'),
(4, 'water',         2200, 'critical', 'pending',              NOW() - INTERVAL '14 days'),
(4, 'medicine-kit',  1800, 'critical', 'pending',              NOW() - INTERVAL '14 days');

-- Camp Echo (urgency=0.32, moderate, pop=300, injured=100)
INSERT INTO requests (camp_id, item_type, quantity_needed, priority, status, request_date) VALUES
(5, 'food',           400, 'medium',   'pending',              NOW() - INTERVAL '14 days'),
(5, 'water',          500, 'medium',   'pending',              NOW() - INTERVAL '14 days');


-- ============================================================================
-- DAY 2

-- Camp Alpha — aftershock injuries, desperate for medicine
INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',          1100, 800,  'critical', 'partially_approved', 'Limited stock, partial fill',  NOW() - INTERVAL '13 days'),
(1, 'water',         1600, 1200, 'critical', 'partially_approved', 'Partial — trucks dispatched',  NOW() - INTERVAL '13 days'),
(1, 'medicine-kit',  2000, 0,    'critical', 'pending',            NULL,                           NOW() - INTERVAL '13 days');

-- Camp Bravo — stable, small top-up
INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(2, 'food',           500, 500,  'medium',   'approved',           'Fully approved',               NOW() - INTERVAL '13 days'),
(2, 'water',          700, 700,  'medium',   'approved',           'Fully approved',               NOW() - INTERVAL '13 days');

-- Camp Charlie — injuries worsening
INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(3, 'food',           850, 600,  'high',     'partially_approved', 'Partial due to priority queue', NOW() - INTERVAL '13 days'),
(3, 'water',         1100, 900,  'high',     'partially_approved', 'Partial fill',                  NOW() - INTERVAL '13 days'),
(3, 'medicine-kit',  1000, 0,    'high',     'pending',            NULL,                            NOW() - INTERVAL '13 days');

-- Camp Delta — worst hit, full emergency
INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(4, 'food',          1600, 1000, 'critical', 'partially_approved', 'Partial — stock running low',  NOW() - INTERVAL '13 days'),
(4, 'water',         2500, 1500, 'critical', 'partially_approved', 'Emergency partial',            NOW() - INTERVAL '13 days'),
(4, 'medicine-kit',  2200, 500,  'critical', 'partially_approved', 'Critical shortage',            NOW() - INTERVAL '13 days');

-- Camp Echo — small request
INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(5, 'food',           350, 350,  'medium',   'approved',           'Approved',                     NOW() - INTERVAL '13 days'),
(5, 'water',          450, 450,  'medium',   'approved',           'Approved',                     NOW() - INTERVAL '13 days'),
(5, 'medicine-kit',   200, 0,    'medium',   'pending',            NULL,                           NOW() - INTERVAL '13 days');


-- ============================================================================
-- DAY 3

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
-- Alpha
(1, 'food',          1300, 1000, 'critical', 'partially_approved', 'Partial',                      NOW() - INTERVAL '12 days'),
(1, 'water',         1900, 1500, 'critical', 'partially_approved', 'Partial',                      NOW() - INTERVAL '12 days'),
(1, 'medicine-kit',  2500, 1800, 'critical', 'partially_approved', 'High priority partial fill',   NOW() - INTERVAL '12 days'),
-- Bravo
(2, 'food',           550, 550,  'medium',   'approved',           'OK',                           NOW() - INTERVAL '12 days'),
(2, 'water',          750, 750,  'medium',   'approved',           'OK',                           NOW() - INTERVAL '12 days'),
(2, 'medicine-kit',   300, 300,  'medium',   'approved',           'OK',                           NOW() - INTERVAL '12 days'),
-- Charlie
(3, 'food',          1000, 800,  'high',     'partially_approved', 'Partial',                      NOW() - INTERVAL '12 days'),
(3, 'water',         1300, 1100, 'high',     'partially_approved', 'Partial',                      NOW() - INTERVAL '12 days'),
(3, 'medicine-kit',  1200, 900,  'high',     'partially_approved', 'Partial fill',                 NOW() - INTERVAL '12 days'),
-- Delta
(4, 'food',          1800, 1200, 'critical', 'partially_approved', 'Partial — restocking',         NOW() - INTERVAL '12 days'),
(4, 'water',         2800, 2000, 'critical', 'partially_approved', 'Partial',                      NOW() - INTERVAL '12 days'),
(4, 'medicine-kit',  2500, 1500, 'critical', 'partially_approved', 'Still short',                  NOW() - INTERVAL '12 days'),
-- Echo
(5, 'food',           400, 400,  'medium',   'approved',           'OK',                           NOW() - INTERVAL '12 days'),
(5, 'water',          500, 500,  'medium',   'approved',           'OK',                           NOW() - INTERVAL '12 days'),
(5, 'medicine-kit',   250, 200,  'medium',   'partially_approved', 'Partial',                      NOW() - INTERVAL '12 days');


-- ============================================================================
-- DAY 4 

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
-- Alpha — demand starting to plateau
(1, 'food',          1100, 1100, 'critical', 'approved',           'Fully approved',               NOW() - INTERVAL '11 days'),
(1, 'water',         1700, 1700, 'critical', 'approved',           'Fully approved',               NOW() - INTERVAL '11 days'),
(1, 'medicine-kit',  2000, 1500, 'critical', 'partially_approved', 'Partial — med shortage',       NOW() - INTERVAL '11 days'),
-- Bravo — stable
(2, 'food',           500, 500,  'medium',   'delivered',          'Delivered',                    NOW() - INTERVAL '11 days'),
(2, 'water',          650, 650,  'medium',   'delivered',          'Delivered',                    NOW() - INTERVAL '11 days'),
-- Charlie
(3, 'food',           900, 900,  'high',     'approved',           'Approved',                     NOW() - INTERVAL '11 days'),
(3, 'water',         1200, 1200, 'high',     'approved',           'Approved',                     NOW() - INTERVAL '11 days'),
(3, 'medicine-kit',  1100, 800,  'high',     'partially_approved', 'Partial',                      NOW() - INTERVAL '11 days'),
-- Delta — still heavy
(4, 'food',          1500, 1500, 'critical', 'approved',           'Approved — supply restored',   NOW() - INTERVAL '11 days'),
(4, 'water',         2400, 2000, 'critical', 'partially_approved', 'Partial',                      NOW() - INTERVAL '11 days'),
(4, 'medicine-kit',  2000, 1800, 'critical', 'partially_approved', 'Almost full',                  NOW() - INTERVAL '11 days'),
-- Echo
(5, 'food',           380, 380,  'low',      'delivered',          'Delivered',                    NOW() - INTERVAL '11 days'),
(5, 'water',          480, 480,  'low',      'delivered',          'Delivered',                    NOW() - INTERVAL '11 days'),
(5, 'medicine-kit',   220, 220,  'medium',   'approved',           'OK',                           NOW() - INTERVAL '11 days');


-- ============================================================================
-- DAY 5 

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',          1000, 1000, 'high',     'delivered',          'Delivered on time',            NOW() - INTERVAL '10 days'),
(1, 'water',         1500, 1500, 'high',     'delivered',          'Delivered',                    NOW() - INTERVAL '10 days'),
(1, 'medicine-kit',  1800, 1800, 'critical', 'delivered',          'Full delivery',                NOW() - INTERVAL '10 days'),
(2, 'food',           450, 450,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '10 days'),
(2, 'water',          600, 600,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '10 days'),
(3, 'food',           800, 800,  'high',     'delivered',          'OK',                           NOW() - INTERVAL '10 days'),
(3, 'water',         1100, 1100, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '10 days'),
(3, 'medicine-kit',   900, 900,  'high',     'delivered',          'Full',                         NOW() - INTERVAL '10 days'),
(4, 'food',          1400, 1400, 'critical', 'delivered',          'Delivered',                    NOW() - INTERVAL '10 days'),
(4, 'water',         2200, 2200, 'critical', 'delivered',          'Delivered',                    NOW() - INTERVAL '10 days'),
(4, 'medicine-kit',  1800, 1800, 'critical', 'delivered',          'Full',                         NOW() - INTERVAL '10 days'),
(5, 'food',           350, 350,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '10 days'),
(5, 'water',          450, 450,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '10 days');


-- ============================================================================
-- DAY 6 

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           950, 950,  'high',     'delivered',          'Weekend delivery',             NOW() - INTERVAL '9 days'),
(1, 'water',         1400, 1400, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(1, 'medicine-kit',  1500, 1500, 'high',     'delivered',          'Injury rate declining',        NOW() - INTERVAL '9 days'),
(2, 'food',           400, 400,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(2, 'water',          550, 550,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(3, 'food',           750, 750,  'high',     'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(3, 'water',         1000, 1000, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(3, 'medicine-kit',   700, 700,  'medium',   'delivered',          'Downgraded priority',          NOW() - INTERVAL '9 days'),
(4, 'food',          1300, 1300, 'critical', 'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(4, 'water',         2000, 2000, 'critical', 'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(4, 'medicine-kit',  1500, 1500, 'high',     'delivered',          'Priority lowered',             NOW() - INTERVAL '9 days'),
(5, 'food',           300, 300,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '9 days'),
(5, 'water',          400, 400,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '9 days');


-- ============================================================================
-- DAY 7

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           900, 900,  'high',     'delivered',          'Steady',                       NOW() - INTERVAL '8 days'),
(1, 'water',         1300, 1300, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '8 days'),
(1, 'medicine-kit',  1200, 1200, 'high',     'delivered',          'Injury treatment ongoing',     NOW() - INTERVAL '8 days'),
(2, 'food',           420, 420,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '8 days'),
(2, 'water',          580, 580,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '8 days'),
(2, 'medicine-kit',   200, 200,  'low',      'delivered',          'Routine',                      NOW() - INTERVAL '8 days'),
(3, 'food',           700, 700,  'medium',   'delivered',          'Priority lowered',             NOW() - INTERVAL '8 days'),
(3, 'water',          950, 950,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '8 days'),
(3, 'medicine-kit',   600, 600,  'medium',   'delivered',          'Stable',                       NOW() - INTERVAL '8 days'),
(4, 'food',          1200, 1200, 'high',     'delivered',          'Improving',                    NOW() - INTERVAL '8 days'),
(4, 'water',         1800, 1800, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '8 days'),
(4, 'medicine-kit',  1300, 1300, 'high',     'delivered',          'Still high injury load',       NOW() - INTERVAL '8 days'),
(5, 'food',           320, 320,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '8 days'),
(5, 'water',          420, 420,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '8 days'),
(5, 'medicine-kit',   150, 150,  'low',      'delivered',          'Routine',                      NOW() - INTERVAL '8 days');


-- ============================================================================
-- DAY 8

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           880, 880,  'high',     'delivered',          'OK',                           NOW() - INTERVAL '7 days'),
(1, 'water',         1600, 1200, 'critical', 'partially_approved', 'Rain prep — surge',           NOW() - INTERVAL '7 days'),
(1, 'medicine-kit',  1100, 1100, 'medium',   'delivered',          'Declining need',               NOW() - INTERVAL '7 days'),
(2, 'food',           400, 400,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '7 days'),
(2, 'water',          800, 600,  'high',     'partially_approved', 'Rain stockpile',              NOW() - INTERVAL '7 days'),
(3, 'food',           680, 680,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '7 days'),
(3, 'water',         1200, 900,  'high',     'partially_approved', 'Rain prep',                   NOW() - INTERVAL '7 days'),
(3, 'medicine-kit',   550, 550,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '7 days'),
(4, 'food',          1150, 1150, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '7 days'),
(4, 'water',         2200, 1800, 'critical', 'partially_approved', 'Rain surge demand',           NOW() - INTERVAL '7 days'),
(4, 'medicine-kit',  1200, 1200, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '7 days'),
(5, 'food',           300, 300,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '7 days'),
(5, 'water',          600, 450,  'medium',   'partially_approved', 'Rain prep',                   NOW() - INTERVAL '7 days'),
(5, 'medicine-kit',   130, 130,  'low',      'delivered',          'Routine',                      NOW() - INTERVAL '7 days');


-- ============================================================================
-- DAY 9

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           850, 850,  'medium',   'delivered',          'Declining trend',              NOW() - INTERVAL '6 days'),
(1, 'water',         1300, 1300, 'high',     'delivered',          'Back to normal',               NOW() - INTERVAL '6 days'),
(1, 'medicine-kit',  1300, 1000, 'high',     'partially_approved', 'Waterborne illness risk',     NOW() - INTERVAL '6 days'),
(2, 'food',           380, 380,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '6 days'),
(2, 'water',          560, 560,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '6 days'),
(2, 'medicine-kit',   250, 250,  'medium',   'delivered',          'Illness prevention',           NOW() - INTERVAL '6 days'),
(3, 'food',           650, 650,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '6 days'),
(3, 'water',          920, 920,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '6 days'),
(3, 'medicine-kit',   700, 500,  'high',     'partially_approved', 'Post-rain illness',           NOW() - INTERVAL '6 days'),
(4, 'food',          1100, 1100, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '6 days'),
(4, 'water',         1700, 1700, 'high',     'delivered',          'Normalized',                   NOW() - INTERVAL '6 days'),
(4, 'medicine-kit',  1500, 1200, 'critical', 'partially_approved', 'Waterborne illness outbreak', NOW() - INTERVAL '6 days'),
(5, 'food',           280, 280,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '6 days'),
(5, 'water',          400, 400,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '6 days'),
(5, 'medicine-kit',   180, 180,  'medium',   'delivered',          'Prevention kits',              NOW() - INTERVAL '6 days');


-- ============================================================================
-- DAY 10 

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           800, 800,  'medium',   'delivered',          'Recovery mode',                NOW() - INTERVAL '5 days'),
(1, 'water',         1200, 1200, 'medium',   'delivered',          'Stable',                       NOW() - INTERVAL '5 days'),
(1, 'medicine-kit',  1100, 1100, 'high',     'delivered',          'Illness treatment',            NOW() - INTERVAL '5 days'),
(2, 'food',           350, 350,  'low',      'delivered',          'Baseline',                     NOW() - INTERVAL '5 days'),
(2, 'water',          500, 500,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '5 days'),
(2, 'medicine-kit',   200, 200,  'low',      'delivered',          'Routine',                      NOW() - INTERVAL '5 days'),
(3, 'food',           620, 620,  'medium',   'delivered',          'Declining',                    NOW() - INTERVAL '5 days'),
(3, 'water',          880, 880,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '5 days'),
(3, 'medicine-kit',   600, 600,  'medium',   'delivered',          'Illness contained',            NOW() - INTERVAL '5 days'),
(4, 'food',          1050, 1050, 'high',     'delivered',          'Improving',                    NOW() - INTERVAL '5 days'),
(4, 'water',         1600, 1600, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '5 days'),
(4, 'medicine-kit',  1300, 1300, 'high',     'delivered',          'Still treating injuries',      NOW() - INTERVAL '5 days'),
(5, 'food',           260, 260,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '5 days'),
(5, 'water',          380, 380,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '5 days'),
(5, 'medicine-kit',   160, 160,  'low',      'delivered',          'Routine',                      NOW() - INTERVAL '5 days');


-- ============================================================================
-- DAY 11

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           750, 750,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(1, 'water',         1100, 1100, 'medium',   'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(1, 'medicine-kit',   900, 900,  'medium',   'delivered',          'Winding down',                 NOW() - INTERVAL '4 days'),
(2, 'food',           330, 330,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(2, 'water',          480, 480,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(3, 'food',           600, 600,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(3, 'water',          850, 850,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(3, 'medicine-kit',   500, 500,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(4, 'food',          1000, 1000, 'high',     'delivered',          'Still high pop',               NOW() - INTERVAL '4 days'),
(4, 'water',         1500, 1500, 'high',     'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(4, 'medicine-kit',  1100, 1100, 'high',     'delivered',          'Ongoing treatment',            NOW() - INTERVAL '4 days'),
(5, 'food',           250, 250,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(5, 'water',          360, 360,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '4 days'),
(5, 'medicine-kit',   140, 140,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '4 days');


-- ============================================================================
-- DAY 12

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           700, 700,  'medium',   'delivered',          'Near baseline',                NOW() - INTERVAL '3 days'),
(1, 'water',         1050, 1050, 'medium',   'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(1, 'medicine-kit',   750, 750,  'medium',   'delivered',          'Declining',                    NOW() - INTERVAL '3 days'),
(2, 'food',           320, 320,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(2, 'water',          460, 460,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(2, 'medicine-kit',   150, 150,  'low',      'delivered',          'Routine',                      NOW() - INTERVAL '3 days'),
(3, 'food',           580, 580,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(3, 'water',          800, 800,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(3, 'medicine-kit',   450, 450,  'low',      'delivered',          'Near baseline',                NOW() - INTERVAL '3 days'),
(4, 'food',           950, 950,  'medium',   'delivered',          'Declining',                    NOW() - INTERVAL '3 days'),
(4, 'water',         1400, 1400, 'medium',   'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(4, 'medicine-kit',   900, 900,  'medium',   'delivered',          'Improving',                    NOW() - INTERVAL '3 days'),
(5, 'food',           240, 240,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(5, 'water',          340, 340,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '3 days'),
(5, 'medicine-kit',   120, 120,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '3 days');


-- ============================================================================
-- DAY 13 

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           680, 680,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(1, 'water',         1000, 1000, 'medium',   'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(1, 'medicine-kit',   650, 650,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(2, 'food',           310, 310,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(2, 'water',          440, 440,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(3, 'food',           560, 560,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(3, 'water',          780, 780,  'medium',   'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(3, 'medicine-kit',   400, 400,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
-- Delta SPIKES — evacuees from nearby village arrive
(4, 'food',          1400, 1000, 'critical', 'partially_approved', 'Evacuee surge!',              NOW() - INTERVAL '2 days'),
(4, 'water',         2000, 1500, 'critical', 'partially_approved', 'New arrivals — urgent',       NOW() - INTERVAL '2 days'),
(4, 'medicine-kit',  1200, 800,  'critical', 'partially_approved', 'Evacuee medical needs',       NOW() - INTERVAL '2 days'),
(5, 'food',           230, 230,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(5, 'water',          330, 330,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '2 days'),
(5, 'medicine-kit',   110, 110,  'low',      'delivered',          'OK',                           NOW() - INTERVAL '2 days');


-- ============================================================================
-- DAY 14

INSERT INTO requests (camp_id, item_type, quantity_needed, fulfilled_quantity, priority, status, admin_note, request_date) VALUES
(1, 'food',           650, 0,    'medium',   'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(1, 'water',          980, 0,    'medium',   'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(1, 'medicine-kit',   600, 0,    'medium',   'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(2, 'food',           300, 0,    'low',      'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(2, 'water',          430, 0,    'low',      'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(2, 'medicine-kit',   130, 0,    'low',      'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(3, 'food',           550, 0,    'medium',   'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(3, 'water',          760, 0,    'medium',   'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(3, 'medicine-kit',   380, 0,    'low',      'pending',            NULL,                           NOW() - INTERVAL '1 day'),
-- Delta still elevated from evacuee surge
(4, 'food',          1200, 0,    'high',     'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(4, 'water',         1800, 0,    'high',     'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(4, 'medicine-kit',  1000, 0,    'high',     'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(5, 'food',           220, 0,    'low',      'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(5, 'water',          320, 0,    'low',      'pending',            NULL,                           NOW() - INTERVAL '1 day'),
(5, 'medicine-kit',   100, 0,    'low',      'pending',            NULL,                           NOW() - INTERVAL '1 day');


-- ============================================================================
-- VERIFICATION QUERIES

-- Total requests per day (should see 14 days of data)
-- SELECT DATE(request_date) as day, COUNT(*) as requests, SUM(quantity_needed) as total_demand FROM requests GROUP BY DATE(request_date) ORDER BY day;

-- Demand trend per item type
-- SELECT DATE(request_date) as day, item_type, SUM(quantity_needed) as total FROM requests GROUP BY DATE(request_date), item_type ORDER BY day, item_type;

-- Camp-wise daily demand
-- SELECT DATE(request_date) as day, camp_id, SUM(quantity_needed) as demand FROM requests GROUP BY DATE(request_date), camp_id ORDER BY day, camp_id;

-- Status distribution
-- SELECT status, COUNT(*), SUM(quantity_needed) as total_qty FROM requests GROUP BY status ORDER BY COUNT(*) DESC;

-- Approval ratio per day
-- SELECT DATE(request_date) as day,
--        ROUND(SUM(fulfilled_quantity)::numeric / NULLIF(SUM(quantity_needed), 0) * 100, 1) as approval_pct
-- FROM requests GROUP BY DATE(request_date) ORDER BY day;