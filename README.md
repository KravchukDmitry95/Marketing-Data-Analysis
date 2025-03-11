# Marketing-Data-Analysis
Combines campaign data from Facebook and Google Ads, analyzes performance, and calculates ROMI to select the best campaigns and ad groups.
## 📌 Project description
This project analyzes Facebook Ads and Google Ads,  
to determine the effectiveness of advertising and find the campaigns with the best ROMI (Return on Marketing Investment).  
The queries are executed in DBeaver with a connection to the PostgreSQL database.
## 🛠️ Technologies used
- SQL (CTE, aggregate functions, analytical queries)
- DBeaver - for connecting and executing SQL queries
- PostgreSQL - database with marketing data
- Google Ads API, Facebook Ads API (as data sources)
## 🔗 Before running
📌 These SQL queries were run in DBeaver connected to a PostgreSQL database.  
To repeat the analysis, you should have a database with the following tables:  
- facebook_ads_basic_daily (Facebook Ads metrics)  
- facebook_adset (ad sets)  
- facebook_campaign (Facebook campaigns)  
- google_ads_basic_daily (Google Ads metrics)  

🔹 If you do not have access to this data, you can create a test database  
(⚡ A file with sample data will be added later).  

## 📥 How to use
1. Connect to the PostgreSQL database in DBeaver.  
2. Execute SQL queries in the appropriate order.  
3. Analyze the results (costs, impressions, clicks, ROMI).  
