CREATE VIEW medsExpiringSoon AS 
select medicine_id, facility_id, expiry_date
from inventory
where expiry_date < (current_date()+30);



CREATE VIEW quantityOrderedByEachFacility AS
select f.f_name, sum(so.quantity_ordered) as quantity_ordered
from supply_orders as so
join facilities as f
on so.facility_id = f.facility_id
group by f.f_name
order by quantity_ordered desc;

select * from quantityOrderedByEachFacility;





CREATE VIEW OnTimeDeliveriesByEachSupplier AS
	select s.name as SupplierName, count(case when (actual_delivery_date - expected_delivery_date) = 0 then 1 else null end) as NumberOfOnTimeDelivery, count(so.supplier_id) as TotalDeliveries,
	round(count(case when (actual_delivery_date - expected_delivery_date) = 0 then 1 else null end)*100/count(so.supplier_id),2) as OnTimeDeliveryAsPercentageOfTotal
	from supply_orders as so
	join suppliers as s
	on so.supplier_id = s.supplier_id
	group by s.name;

-- drop view OnTimeDeliveriesByEachSupplier;
select * from OnTimeDeliveriesByEachSupplier;




-- Prescription vs supply demand by each month
DELIMITER //
CREATE PROCEDURE PrescriptionVsSupplyDemand(IN month_num INT, IN year_num INT, IN id INT)
BEGIN

    SET id = IF(id = -1, NULL, id);
    SET month_num = IF(month_num = -1, NULL, month_num);
    SET year_num = IF(year_num = -1, NULL, year_num);

	with SupplyDemand as (	
		select medicine_id, sum(quantity_ordered) as quantityOrdered
		from supply_orders
		where (month_num is null or MONTH(order_date) = month_num) and (year_num is null or YEAR(order_date) = year_num) and (id is null or facility_id = id)
		group by medicine_id
	),

	PrescriptionDemand as (	
		select medicine_id, sum(quantity_prescribed) as quantityPrescribed
		from prescription_demand
	    where (month_num is null or MONTH(prescription_date) = month_num) and (year_num is null or YEAR(prescription_date) = year_num) and (id is null or facility_id = id)
		group by medicine_id
	)

	select sd.medicine_id, sd.quantityOrdered, pd.quantityPrescribed
	from SupplyDemand as sd
	join PrescriptionDemand as pd
	on sd.medicine_id = pd.medicine_id
    group by sd.medicine_id;
	
END //
DELIMITER ;

drop procedure PrescriptionVsSupplyDemand;
call PrescriptionVsSupplyDemand(null,null,null);







-- Added a column 'cost_price' in the inventory table
	alter table inventory add column cost_price decimal(10,2) not null;
	-- alter table inventory drop column cost_price;
	UPDATE inventory i
	JOIN medicines m 
	ON i.medicine_id = m.medicine_id
	SET i.cost_price = m.cost_price;

	update inventory
	set inventory_value = quantity_in_stock * cost_price;

select * from inventory;

ALTER TABLE inventory
MODIFY COLUMN cost_price DECIMAL(10,2)
AFTER medicine_id;

ALTER TABLE inventory
MODIFY COLUMN last_updated DATE
AFTER expiry_date;


ALTER TABLE facilities
CHANGE COLUMN name f_name VARCHAR(100);





-- current stock levels per facility
delimiter //
create procedure stock_levels_per_facility (IN id INT)
begin 

	select i.medicine_id, m.name, i.quantity_in_stock, i.reorder_level
	from inventory as i
	join medicines as m on i.medicine_id = m.medicine_id
	where i.facility_id = id;
end //
delimiter ;

drop procedure stock_levels_per_facility;
call stock_levels_per_facility(3); 







create table if not exists late_deliveries_results (
    supplier_id int primary key,
    name varchar(100),
    LateDeliveries int,
    TotalDeliveries int,
    LateDeliveriesAsPercentageOfTotal decimal(10,2),
    reliability_score decimal(5,2)
);


-- late deliveries by each supplier 
delimiter //
create procedure late_deliveries ()
begin

	-- Ensure the table is empty before inserting new results
    -- TRUNCATE TABLE late_deliveries_results;

    -- Insert calculated values directly into the permanent table
    -- INSERT INTO late_deliveries_results (supplier_id, name, LateDeliveries, TotalDeliveries, LateDeliveriesAsPercentageOfTotal, reliability_score)
	with lateDeliveriesPercentage as (
		select s.supplier_id, s1.name, count(case when (actual_delivery_date > expected_delivery_date) then 1 else null end) as LateDeliveries, count(s.supplier_id) as TotalDeliveries,
		round(count(case when (actual_delivery_date > expected_delivery_date) then 1 else null end)*100/count(s.supplier_id),2) as LateDeliveriesAsPercentageOfTotal
		from supply_orders as s
		join suppliers as s1
		on s.supplier_id = s1.supplier_id
		group by s.supplier_id, s1.name
    ),
    
	getReliabilityScore as (
		select supplier_id, round((100 - LateDeliveriesAsPercentageOfTotal)/100, 2) as reliability_score 
        from lateDeliveriesPercentage
	)
    
    select ldp.*,  grs.reliability_score 
	from lateDeliveriesPercentage as ldp
	join getReliabilityScore as grs
	on ldp.supplier_id = grs.supplier_id;
    
end //
delimiter ;


drop procedure late_deliveries;
call late_deliveries();
select * from late_deliveries_results;





-- Update the suppliers table with the new reliability scores
delimiter //
create procedure update_reliability_scores ()
begin
    SET SQL_SAFE_UPDATES = 0;
		update suppliers s
		join late_deliveries_results ldr on s.supplier_id = ldr.supplier_id
        set s.reliability_score = ldr.reliability_score;
    SET SQL_SAFE_UPDATES = 1;
end //
delimiter ;


drop procedure update_reliability_scores;
call update_reliability_scores();

select * from suppliers;







-- Avg. delivery time of each supplier
create view AverageDeliveryTime as (
select supplier_id, round(avg(actual_delivery_date - order_date), 0) as avg_delivery_days
from supply_orders
group by supplier_id
);

-- drop view AverageDeliveryTime;
-- select * from averagedeliverytime;


-- update avg delivery time in the suppliers table
delimiter //
create procedure update_avg_delivery_time ()
begin
    SET SQL_SAFE_UPDATES = 0;
		update suppliers s
		join AverageDeliveryTime adt on s.supplier_id = adt.supplier_id
        set s.delivery_time_avg = adt.avg_delivery_days;
    SET SQL_SAFE_UPDATES = 1;
end //
delimiter ;

call update_avg_delivery_time();

select * from suppliers;







delimiter //
create procedure medsSoldByEachFacility (IN id INT)
begin
	SET id = IF(id = -1, NULL, id);
	select pd.medicine_id, m.name, sum(pd.quantity_prescribed) as TotalQuantitySold, dense_rank() over (order by sum(pd.quantity_prescribed) desc) as ranking
	from prescription_demand as pd
	join medicines as m
	on pd.medicine_id = m.medicine_id
	where (id is null or pd.facility_id = id)
	group by pd.medicine_id, m.name;
end //
delimiter ;

call medsSoldByEachFacility(2);





create table supply_trends_weekly (
	id INT PRIMARY KEY auto_increment,
	medicine_id INT,
    SumQuantityPrevWeek INT,
    SumQuantityCurrWeek INT, 
    ChangeOverPrevWeek DECIMAL(10,2),
    WeekNum INT
);

select * from supply_trends_weekly;

-- CHANGE THIS BY ADDING FACILITY_ID -----------------------------
-- Supply trends 
DELIMITER //
create procedure SupplyTrendsWeekly(IN fid INT, IN id INT, IN month_num INT, IN year_num INT)
begin

	SET fid = IF(fid = -1, NULL, fid);
    SET id = IF(id = -1, NULL, id);
    SET month_num = IF(month_num = -1, NULL, month_num);
    SET year_num = IF(year_num = -1, NULL, year_num);
    
-- TRUNCATE TABLE supply_trends_weekly;
-- INSERT INTO supply_trends_weekly (medicine_id, SumQuantityPrevWeek, SumQuantityCurrWeek, ChangeOverPrevWeek, WeekNum)
with quantity_prev_week as (
	select medicine_id, sum(quantity_ordered) as SumQuantityCurrWeek, week(order_date) as WeekNum, lag(sum(quantity_ordered), 1) over (partition by medicine_id order by week(order_date)) as SumQuantityPrevWeek
    from supply_orders
    where (id is null or medicine_id = id) and (fid is null or facility_id = fid ) and (month_num is null or month(order_date) = month_num) and (year_num is null or year(order_date) = year_num)
    group by medicine_id, week(order_date)
) 

select medicine_id, SumQuantityPrevWeek, SumQuantityCurrWeek, round((SumQuantityCurrWeek - SumQuantityPrevWeek) *100/ SumQuantityPrevWeek, 2) as ChangeOverPrevWeek, WeekNum
from quantity_prev_week;

end //
DELIMITER ;

drop procedure SupplyTrendsWeekly;
call SupplyTrendsWeekly(1, -1, -1, null);





-- medicnies that require restocking
DELIMITER //
create procedure MedsNeedRestocking(IN id INT)
begin
select medicine_id, quantity_in_stock, reorder_level
from inventory
where quantity_in_stock < reorder_level and facility_id = id;
end //
DELIMITER ;

call medsneedrestocking(3);






--  Pescription demand VS inventory

DELIMITER //
CREATE PROCEDURE PrescriptionDemandVsInventory(IN month_num INT, IN year_num INT, IN id INT)
BEGIN

	SET id = IF(id = -1, NULL, id);
    SET month_num = IF(month_num = -1, NULL, month_num);
    SET year_num = IF(year_num = -1, NULL, year_num);

	with InventoryValue as (	
		select medicine_id, sum(quantity_in_stock) as CurrentQuantityInStock
		from inventory
		where (id is null or facility_id = id)
		group by medicine_id
	),

	PrescriptionDemand as (	
		select medicine_id, sum(quantity_prescribed) as quantityPrescribed
		from prescription_demand
	    where (month_num is null or MONTH(prescription_date) = month_num) and (year_num is null or YEAR(prescription_date) = year_num) and (id is null or facility_id = id)
		group by medicine_id
	)

	select iv.medicine_id, iv.CurrentQuantityInStock, pd.quantityPrescribed
	from InventoryValue as iv
	join PrescriptionDemand as pd
	on iv.medicine_id = pd.medicine_id
    group by iv.medicine_id;
	
END //
DELIMITER ;

drop procedure PrescriptionDemandVsInventory;
call PrescriptionDemandVsInventory(null,null,3);








-- Revenue generated by pharmacy vs hospital comparison
delimiter //
create procedure RevenueByPharmacyVSHospital (IN month_num INT, IN year_num INT)
begin

    SET month_num = IF(month_num = -1, NULL, month_num);
    SET year_num = IF(year_num = -1, NULL, year_num);

	select f.type as FacilityType, concat( 'Rs. ', round(sum(revenue), 0)) as TotalRevenueInRupees
	from prescription_demand as pd
	join facilities as f
	on pd.facility_id = f.facility_id
	where (month_num is null or month(prescription_date) = month_num) and (year_num is null or year(prescription_date) = year_num)
	group by f.type
	order by TotalRevenueInRupees desc;
end //
delimiter ;

drop procedure RevenueByPharmacyVSHospital;
call RevenueByPharmacyVSHospital(1,null);





-- Top 5 medicines with the highest profit percentage

create view MedsByProfitPercentage as (
select name, concat(round((selling_price - cost_price)*100/cost_price, 2), '%') as ProfitPercentage
from medicines
order by ProfitPercentage desc
limit 5
);





--  Profit per unit of each medicine in a facility
delimiter //
create procedure MedsProfitPerUnit(IN id INT, IN month_num INT, IN year_num INT)
begin

	SET id = IF(id = -1, NULL, id);
    SET month_num = IF(month_num = -1, NULL, month_num);
    SET year_num = IF(year_num = -1, NULL, year_num);

	select pd.medicine_id as medicine_id, 
    sum(quantity_prescribed) as QuantitySold,
    format(sum(pd.revenue) - sum(m.cost_price * pd.quantity_prescribed), 0) as ProfitInRupees,
    round((sum(pd.revenue) - sum(m.cost_price * pd.quantity_prescribed)) / sum(pd.quantity_prescribed), 2) as ProfitPerUnitInRupees
	from prescription_demand as pd
	join medicines as m 
	on pd.medicine_id = m.medicine_id
	where (month_num is null or MONTH(prescription_date) = month_num) and (year_num is null or YEAR(prescription_date) = year_num) and (id is null or facility_id = id)
	group by pd.medicine_id
	order by ProfitPerUnitInRupees desc;
end //
delimiter ;

drop procedure MedsProfitPerUnit;
call MedsProfitPerUnit(-1,-1,-1);




-- Comparison of revenue between Insurance and Cash
create view InsuranceVsCashByRevenue as 
select payment_mode, concat('Rs. ', sum(revenue)) as TotalRevenueGenerated
from prescription_demand
where payment_mode in ('Insurance', 'Cash')
group by payment_mode;

select * from InsuranceVsCashByRevenue;





-- Facility Order Dependency on a Single Supplier
delimiter //
create procedure OrderDependencyOnSupplier(IN id INT)
begin
	select facility_id, supplier_id, count(order_id) as OrderCount
	from supply_orders
	group by facility_id, supplier_id 
	having count(order_id) > 10 and facility_id = id;
end //
delimiter ;

drop procedure OrderDependencyOnSupplier;
call OrderDependencyOnSupplier(2);








create table PrescriptionDemandWeekly (
	id INT PRIMARY KEY auto_increment,
	medicine_id INT,
    SumDemandPrevWeek INT,
    SumDemandCurrWeek INT, 
    ChangeOverPrevWeek DECIMAL(10,2),
    WeekNum INT
);

-- Medicine Sold Weekly by each facility
DELIMITER //
create procedure PrescriptionDemandTrendsWeekly(IN fid INT, IN id INT, IN month_num INT, IN year_num INT)
begin

	SET fid = IF(fid = -1, NULL, fid);
	SET id = IF(id = -1, NULL, id);
    SET month_num = IF(month_num = -1, NULL, month_num);
    SET year_num = IF(year_num = -1, NULL, year_num);

-- TRUNCATE TABLE PrescriptionDemandWeekly;

-- INSERT INTO PrescriptionDemandWeekly (medicine_id, SumDemandPrevWeek, SumDemandCurrWeek, ChangeOverPrevWeek, WeekNum)
with prescription_demand_weekly as (
	select medicine_id, sum(quantity_prescribed) as SumDemandCurrWeek, week(prescription_date) as WeekNum, lag(sum(quantity_prescribed), 1) over (partition by medicine_id order by week(prescription_date)) as SumDemandPrevWeek
    from prescription_demand
    where (id is null or medicine_id = id) and (fid is null or facility_id = fid) and (month_num is null or month(prescription_date) = month_num) and (year_num is null or year(prescription_date) = year_num)
    group by medicine_id, week(prescription_date)
) 

select medicine_id, SumDemandPrevWeek, SumDemandCurrWeek,  round((SumDemandCurrWeek - SumDemandPrevWeek) *100/ SumDemandPrevWeek, 2) as ChangeOverPrevWeek, WeekNum
from prescription_demand_weekly;

end //
DELIMITER ;

drop procedure PrescriptionDemandTrendsWeekly;
call PrescriptionDemandTrendsWeekly(-1,null,null,-1);

select * from PrescriptionDemandWeekly;







-- overstocked medicines in each facility
delimiter //
create procedure OverStockedMeds(IN id INT)
begin
	select medicine_id, sum(quantity_in_stock), reorder_level
	from inventory
	where facility_id = id
	group by medicine_id, reorder_level
	order by sum(quantity_in_stock) desc
	limit 5;
end //
delimiter ;

call OverStockedMeds(5);








-- revenue by each payment mode 

delimiter //
create procedure RevenueByPaymentMode (IN fid INT, IN month_num INT, IN year_num INT)
begin
	
    SET fid = IF(fid = -1, NULL, fid);
    SET month_num = IF(month_num = -1, NULL, month_num);
    SET year_num = IF(year_num = -1, NULL, year_num);

	select
	payment_mode,
	concat('Rs. ', format(sum(case when payment_mode='Insurance' then insurance_covered_amount else patient_paid_amount end), 0)) as total_amount
	from prescription_demand
    where (fid is null or facility_id = fid) and (month_num is null or month(prescription_date) = month_num) and (year_num is null or year(prescription_date) = year_num)
	group by payment_mode

	union all 

	select 'Debit' as payment_mode,
	concat('Rs. ', format(sum(patient_paid_amount), 0)) as total_amount
	from prescription_demand
	where payment_mode='Insurance' and (fid is null or facility_id = fid) and (month_num is null or month(prescription_date) = month_num) and (year_num is null or year(prescription_date) = year_num);
end //
delimiter ;

drop procedure RevenueByPaymentMode;
call RevenueByPaymentMode(2,null,-1);




select * from inventory;


-- Change the reorder level in inventory from inventory_data_new
UPDATE inventory i
JOIN inventory_data_new n
ON i.inventory_id = n.inventory_id
SET i.reorder_level = n.reorder_level;


