

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

----------------------------------------------------------------------

CREATE TABLE camps (
    camp_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    cord_x INTEGER NOT NULL
        CHECK (cord_x BETWEEN 0 AND 1000),
    cord_y INTEGER NOT NULL
        CHECK (cord_y BETWEEN 0 AND 1000),
    total_population INTEGER DEFAULT 0
        CHECK (total_population >= 0),
    injured_population INTEGER DEFAULT 0
        CHECK (injured_population >= 0),
    urgency_score FLOAT DEFAULT 0.0
        CHECK (urgency_score BETWEEN 0 AND 1),
    status VARCHAR(20) DEFAULT 'moderate',
    manager_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_coordinates UNIQUE (cord_x, cord_y)
);
-----------------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------------------------

CREATE TABLE warehouse_inventory (
    item_id SERIAL PRIMARY KEY,
    item_name VARCHAR(50), 
    item_type VARCHAR(30) NOT NULL
        CHECK (item_type IN ('food', 'water', 'medicine-kit', 'other')),
    quantity INTEGER NOT NULL DEFAULT 0
        CHECK (quantity >= 0),
    unit VARCHAR(20) NOT NULL
        CHECK (unit IN ('kg', 'liter', 'units')),
    low_stock_threshold INTEGER NOT NULL DEFAULT 0
        CHECK (low_stock_threshold >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_item_type_unit UNIQUE (item_type, unit)
);

-----------------------------------------------------------------------------------------

CREATE TABLE requests (
    request_id SERIAL PRIMARY KEY,
    camp_id INTEGER NOT NULL REFERENCES camps(camp_id) ON DELETE CASCADE,
    item_type VARCHAR(30) NOT NULL
        CHECK (item_type IN ('food', 'water', 'medicine-kit', 'other')),
    quantity_needed INTEGER NOT NULL
        CHECK (quantity_needed > 0),
    fulfilled_quantity INTEGER DEFAULT 0
        CHECK (fulfilled_quantity >= 0),
    priority VARCHAR(20) DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status VARCHAR(20) DEFAULT 'pending'
        CHECK (status IN (
            'pending',
            'partially_approved',
            'approved',
            'dispatched',
            'delivered'
        )),
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE requests
ADD COLUMN admin_note TEXT,
ADD COLUMN last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE requests
DROP CONSTRAINT requests_status_check;

--For Dicard by Admin
ALTER TABLE requests
ADD CONSTRAINT requests_status_check
CHECK (status IN (
    'pending',
    'partially_approved',
    'approved',
    'dispatched',
    'delivered',
    'discarded'
));

------------------------------------------------------------------------------------------

CREATE TABLE trucks (
    truck_id SERIAL PRIMARY KEY,
    truck_number VARCHAR(20) UNIQUE NOT NULL,
    capacity_kg NUMERIC(10,2) NOT NULL
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
    driver_id INTEGER
        REFERENCES users(id)
        ON DELETE SET NULL,
    driver_name VARCHAR(100),
    driver_contact VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO trucks (
    truck_number,
    capacity_kg,
    current_load_kg,
    status,
    driver_id,
    driver_name,
    driver_contact
)
VALUES
('TRUCK-01', 1000, 0, 'available', NULL, 'Driver A', '9000000001'),
('TRUCK-02', 1000, 0, 'available', NULL, 'Driver B', '9000000002'),
('TRUCK-03', 1000, 0, 'available', NULL, 'Driver C', '9000000003'),
('TRUCK-04', 1000, 0, 'available', NULL, 'Driver D', '9000000004'),
('TRUCK-05', 1000, 0, 'available', NULL, 'Driver E', '9000000005');


------------------------------------------------------------------------------------------

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    request_id INTEGER NOT NULL REFERENCES requests(request_id) ON DELETE CASCADE,
    allocated_quantity INTEGER NOT NULL
        CHECK (allocated_quantity > 0),
    allocation_datetime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_status VARCHAR(30) DEFAULT 'scheduled'
        CHECK (delivery_status IN (
            'scheduled',
            'in_transit',
            'delivered',
            'failed'
        )),
    delivery_datetime TIMESTAMP,
    truck_id INTEGER
        REFERENCES trucks(truck_id)
        ON DELETE SET NULL
);

ALTER TABLE allocations
ADD COLUMN item_weight NUMERIC(10,2);


-----------------------------------------------------------------------------

CREATE TABLE truck_assignments (
    assignment_id SERIAL PRIMARY KEY,
    truck_id INTEGER NOT NULL
        REFERENCES trucks(truck_id)
        ON DELETE CASCADE,
    camp_id INTEGER NOT NULL
        REFERENCES camps(camp_id)
        ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (truck_id, camp_id)
);


SELECT t.truck_number,c.name AS camp_name
FROM truck_assignments ta
JOIN trucks t ON ta.truck_id = t.truck_id
JOIN camps c ON ta.camp_id = c.camp_id
ORDER BY t.truck_id;

SELECT * FROM truck_assignments;


SELECT * FROM trucks;

ALTER TABLE truck_assignments ADD COLUMN visit_order INTEGER;

SELECT t.truck_number, c.name AS camp_name,ta.visit_order
FROM truck_assignments ta
JOIN trucks t ON ta.truck_id = t.truck_id
JOIN camps c ON ta.camp_id = c.camp_id
ORDER BY t.truck_id, ta.visit_order;


SELECT allocation_id, item_weight, delivery_status FROM allocations;
SELECT allocation_id, truck_id FROM allocations;


UPDATE allocations a
SET truck_id = ta.truck_id
FROM requests r
JOIN truck_assignments ta ON ta.camp_id = r.camp_id
WHERE a.request_id = r.request_id
AND a.truck_id IS NULL;

SELECT truck_number, current_load_kg, status FROM trucks;

DELETE FROM truck_assignments;

SELECT truck_id, COUNT(*) FROM truck_assignments GROUP BY truck_id;

SELECT camp_id, name FROM camps;

SELECT DISTINCT c.camp_id, c.name FROM requests r JOIN camps c ON r.camp_id = c.camp_id WHERE r.status IN 
('approved', 'partially_approved');

