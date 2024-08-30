%livy.pyspark
from pyspark.sql.functions import month, year, col, round, current_timestamp, desc
df_purchases = spark.read.option("header", "true").csv("s3a://desafio/purchases_2023.csv")
df_purchases = df_purchases.withColumn("price", round("price", 2))
df_purchases.write.mode("overwrite").saveAsTable("default.purchases")

%livy.pyspark
df_campaigns = spark.read.csv("s3a://tarefa2/campaigns_2023_hist.csv", header=True)
df_campaigns.write.mode("overwrite").saveAsTable("default.campaigns")

%hive
CREATE TABLE consolidated_client_data AS
SELECT 
    p.client_id,  -- Selects 'client_id' from the purchases table ('p'), identifying the client
    ROUND(SUM(p.price * p.amount * (1 - p.discount_applied)), 2) AS total_price,  
    -- Calculates the total amount spent by the client: 
    -- Multiplies price by the number of items (amount) and the discount applied (1 - discount_applied)

    (SELECT purchase_location  
     FROM purchases 
     WHERE client_id = p.client_id  -- Filters by matching 'client_id'
     GROUP BY purchase_location  -- Groups purchases by 'purchase_location'
     ORDER BY COUNT(*) DESC  -- Orders by frequency, from highest to lowest
     LIMIT 1) AS most_purchase_location,  
     -- Returns the most frequently used purchase location for the client

    MIN(p.purchase_datetime) AS first_purchase,  
    -- Finds the earliest purchase date using MIN()

    MAX(p.purchase_datetime) AS last_purchase,  
    -- Finds the most recent purchase date using MAX()

    (SELECT c.id_campaign  
     FROM campaigns c 
     WHERE c.client_id = p.client_id  -- Filters by matching 'client_id'
     GROUP BY c.id_campaign  -- Groups by campaign ID
     ORDER BY COUNT(*) DESC  -- Orders by frequency, from highest to lowest
     LIMIT 1) AS most_campaign,  
     -- Returns the most received campaign ID for the client

    (SELECT COUNT(*)  
     FROM campaigns c 
     WHERE c.client_id = p.client_id  -- Filters by matching 'client_id'
     AND c.return_status = 'error') AS quantity_error,  
     -- Counts how many campaigns had a return status of "error" for the client

    CURRENT_DATE() AS date_today,  
    -- Inserts the current date

    CAST(CONCAT(LPAD(MONTH(CURRENT_DATE()), 2, '0'), YEAR(CURRENT_DATE())) AS INT) AS anomes_today  
    -- Creates a MMYYYY code for the current month and year:
    -- CONCAT() combines month and year into a string
    -- LPAD() adds a leading zero to single-digit months
    -- CAST() converts the result to an integer

FROM 
    purchases p  -- Alias 'p' for the purchases table
GROUP BY 
    p.client_id  -- Groups results by 'client_id' to apply calculations for each client individually