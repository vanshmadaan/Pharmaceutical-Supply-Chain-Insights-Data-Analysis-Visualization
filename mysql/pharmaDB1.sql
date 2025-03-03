CREATE DATABASE SupplyChainDB;
USE SupplyChainDB;


SELECT user, host FROM mysql.user;
SELECT CURRENT_USER();
SHOW GRANTS FOR 'root'@'localhost';
GRANT EXECUTE ON SupplyChainDB.* TO 'root'@'localhost';
FLUSH PRIVILEGES;




CREATE TABLE Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    manufacturer VARCHAR(50),
    shelf_life INT,
    cost_price DECIMAL(10,2),
    selling_price DECIMAL(10,2)
);

CREATE TABLE Facilities (
    facility_id INT PRIMARY KEY,
    name VARCHAR(100),
	type VARCHAR(50)
);

CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    name VARCHAR(100),
    delivery_time_avg INT,
	reliability_score DECIMAL(10,2)
);


CREATE TABLE Inventory (
    inventory_id INT PRIMARY KEY,
    facility_id INT,
    medicine_id INT,
    quantity_in_stock INT,
    reorder_level INT,
    last_updated DATE,
    inventory_value DECIMAL(10,2),
    expiry_date DATE,
    FOREIGN KEY (medicine_id) REFERENCES Medicines(medicine_id),
    FOREIGN KEY (facility_id) REFERENCES Facilities(facility_id)
);


CREATE TABLE Prescription_Demand (
    prescription_id INT PRIMARY KEY,
    facility_id INT,
    medicine_id INT,
    quantity_prescribed INT,
    prescription_date DATE,
    selling_price DECIMAL(10,2),
    revenue DECIMAL(10,2),
    payment_mode VARCHAR(20),
    insurance_covered_amount DECIMAL(10,2),
    patient_paid_amount DECIMAL(10,2),
    FOREIGN KEY (medicine_id) REFERENCES Medicines(medicine_id),
    FOREIGN KEY (facility_id) REFERENCES Facilities(facility_id)
);



CREATE TABLE Supply_Orders (
    order_id INT PRIMARY KEY,
    supplier_id INT,
    medicine_id INT,
    facility_id INT,
    quantity_ordered INT,
    order_date DATE,
    expected_delivery_date DATE,
    actual_delivery_date DATE,
    FOREIGN KEY (medicine_id) REFERENCES Medicines(medicine_id),
    FOREIGN KEY (facility_id) REFERENCES Facilities(facility_id),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

select * from supply_orders;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Pharmaceutical Supply Chain Dataset\\medicines_cleaned.csv' 
INTO TABLE medicines
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Pharmaceutical Supply Chain Dataset\\facilities_cleaned.csv' 
INTO TABLE facilities
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Pharmaceutical Supply Chain Dataset\\suppliers_cleaned.csv' 
INTO TABLE suppliers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Pharmaceutical Supply Chain Dataset\\inventory_cleaned.csv' 
INTO TABLE inventory
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Pharmaceutical Supply Chain Dataset\\prescription_demand_cleaned.csv' 
INTO TABLE prescription_demand
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Pharmaceutical Supply Chain Dataset\\supply_orders_cleaned.csv' 
INTO TABLE supply_orders
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;



SET SQL_SAFE_UPDATES = 0;

UPDATE supply_orders
SET quantity_ordered = FLOOR(10 + (RAND() * 5));

UPDATE prescription_demand
SET quantity_prescribed = FLOOR(5 + (RAND() * 10));

UPDATE inventory
SET quantity_in_stock = FLOOR(35 + (RAND() * 30));

UPDATE inventory
SET reorder_level = FLOOR(26 + (RAND() * 14));

UPDATE prescription_demand
SET revenue = quantity_prescribed * selling_price;

UPDATE prescription_demand
SET insurance_covered_amount = (0.50 + (RAND() * 0.25)) * revenue, patient_paid_amount = revenue - insurance_covered_amount
WHERE payment_mode = 'Insurance';

SET SQL_SAFE_UPDATES = 1;
