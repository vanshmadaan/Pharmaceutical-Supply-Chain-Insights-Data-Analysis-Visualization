# Pharmaceutical-Supply-Chain-Insights-Data-Analysis-Visualization

Technologies Used - Excel, Python, SQL (MySQL), Power BI

## Project Overview - 
This project focuses on optimizing the pharmaceutical supply chain by analyzing demand, supply, supplier performance, reorder levels and stock levels to prevent drug shortages and improve decision-making

## Project Workflow - 
### Data Collection & Preprocessing (Excel & Python): 
Excel: Cleaned raw data, added relevant columns, and created pivot tables for initial analysis.
Python (Pandas, NumPy, Seaborn, Matplotlib):

 Removed duplicates, handled missing values (using mean/median/zero imputation).
 Outlier detection (Using Z-score for selling price analysis). 
 Created additional derived columns for better insights.

### Database Management (MySQL) :
Loaded the cleaned dataset into MySQL
Created complex queries, CTEs, Views & Stored Procedures such as -
 PrescriptionVsSupplyDemand for identifying demand-supply gaps
 LateDeliveriesByEachSupplier for tracking supplier delays
 StockLevelPerFacility for monitoring quantity of stock at each facility
 OnTimeDeliveriesByEachSupplier for tracking supplier performance
 SuppylyTrendsWeekly, RevenueByPaymentMode, etc.
 Also, calculated Reliability Score of each supplier 

### Advanced Analysis In Python (Numpy, Pandas, Matplotlib, Seaborn):
Connected MySQL and Python to analyse & visualise trends
Key analysis performed -
  Reorder Calculation : Used Average Delivery Time + Safety Stock to determine when to reorder medicines
  Predictive Stockout Analysis : Calculated days_until_stockout based on daily demand
  Demand Vs Supply Gaps : Identified Medicines with consistent shortages
  Supplier Performance Trends : Evaluated monthly trends in supplier reliability
  Forecasting Medicine Trends : Built a Linear Regression model to predict future demnad for each facility

### Data Visualisation & Insights (Power BI) : 
Loaded the processed data from MySQL to Power BI
Built interactive dashboards for - 
 Supply vs Demand Comparison
 Supplier reliability (on-time vs. late deliveries)
 Revenue & profitability trends
 Medicine stock levels, reorder points, and stockout risks
 Weekly demand trends & forecasting

### Key Insights & Impact :
Supplier 207 is the most reliable supplier
Doxycycline was under-supplied by 34.52%, leading to potential shortages.
Supplier 200 had the highest late deliveries (59.32%), impacting medicine availability.
Facility 3 generated the most revenue, with Ibuprofen & Escitalopram as the top-selling medicines.
March had the highest medicine sales & profit.
Reorder levels optimized using predictive analytics, reducing stockouts.

### Conclusion :
This project showcases how data-driven decision-making can optimize medicine inventory, supplier performance, and demand forecasting, ensuring an efficient pharmaceutical supply chain
