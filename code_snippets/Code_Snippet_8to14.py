from google.cloud import bigquery
from google.cloud.exceptions import NotFound
import pandas as pd
import numpy as np
from statsmodels.tsa.holtwinters import ExponentialSmoothing
from statsmodels.tsa.api import SimpleExpSmoothing

# Initialize BigQuery client
client = bigquery.Client()

project_id = 'vlba-2024-mpd-group-6'
dataset_id = 'mpd_g6_data'

# Output table name
output_table_name = 'CCMPD_Sal_Prof_Seasonal_Model_Output'

# Query to retrieve data from BigQuery table
query = f"""
SELECT year, month, ProductId, ProdCat, Country, total_sales_qty, total_revenue, total_expense, monthly_profit
FROM `{project_id}.{dataset_id}.CCMPD_Past_TotSales_Rev_Exp_Prof_CYMP_Model`
"""

# Execute the query and retrieve results into a pandas DataFrame
sales_data = client.query(query).to_dataframe()

# Clean and prepare data
sales_data['year'] = sales_data['year'].astype(int)
sales_data['month'] = sales_data['month'].astype(int)
sales_data['total_sales_qty'] = sales_data['total_sales_qty'].astype(int)
sales_data['total_revenue'] = sales_data['total_revenue'].astype(float)
sales_data['total_expense'] = sales_data['total_expense'].astype(float)
sales_data['monthly_profit'] = sales_data['monthly_profit'].astype(float)

# Function to train seasonal models and forecast
def train_seasonal_models(data):
    forecasts = []

    unique_combinations = data[['Country', 'ProductId', 'ProdCat']].drop_duplicates()

    for _, row in unique_combinations.iterrows():
        country = row['Country']
        product = row['ProductId']
        prodcat = row['ProdCat']

        # Filter the data for the current country-product combination
        subset = data[(data['Country'] == country) & (data['ProductId'] == product)].copy()

        # Prepare the time series
        subset.loc[:, 'date'] = pd.to_datetime(subset[['year', 'month']].assign(day=1))
        subset.set_index('date', inplace=True)
        subset = subset.asfreq('MS')

        ts_sales = subset['total_sales_qty'].dropna()
        ts_revenue = subset['total_revenue'].dropna()
        ts_expense = subset['total_expense'].dropna()
        ts_profit = subset['monthly_profit'].dropna()

        def forecast_series(ts, seasonal_periods=12):
            if len(ts) > seasonal_periods:
                try:
                    model = ExponentialSmoothing(ts, trend='add', seasonal='add', seasonal_periods=seasonal_periods)
                    fit = model.fit(optimized=True)
                    forecast = fit.forecast(steps=24)
                except (ValueError, np.linalg.LinAlgError) as e:
                    print(f"Warning: Fallback to SimpleExpSmoothing for series due to: {e}")
                    model = SimpleExpSmoothing(ts)
                    fit = model.fit()
                    forecast = fit.forecast(steps=24)
                return forecast
            else:
                return pd.Series([np.nan] * 24)

        # Forecast Total Sales Quantity
        forecast_sales = forecast_series(ts_sales)
        # Forecast Total Revenue
        forecast_revenue = forecast_series(ts_revenue)
        # Forecast Total Expense
        forecast_expense = forecast_series(ts_expense)
        # Forecast Monthly Profit
        forecast_profit = forecast_series(ts_profit)

        # Save the forecast
        forecast_dates = pd.date_range(start='2025-01-01', periods=24, freq='MS')
        for date, sales, revenue, expense, profit in zip(forecast_dates, forecast_sales, forecast_revenue, forecast_expense, forecast_profit):
            forecasts.append({
                'Country': country,
                'ProductId': product,
                'ProdCat': prodcat,
                'Year': date.year,
                'Month': date.month,
                'Forecasted_Sales_Quantity': int(sales) if not np.isnan(sales) else None,
                'Forecasted_Revenue': float(revenue) if not np.isnan(revenue) else None,
                'Forecasted_Expense': float(expense) if not np.isnan(expense) else None,
                'Forecasted_Profit': float(profit) if not np.isnan(profit) else None
            })

    return pd.DataFrame(forecasts)

# Train the models and get forecasts
forecast_df = train_seasonal_models(sales_data)

# Define output table reference
output_table_ref = client.dataset(dataset_id).table(output_table_name)

# Define schema for output table
schema = [
    bigquery.SchemaField("Country", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("ProductId", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("ProdCat", "STRING", mode="REQUIRED"),
    bigquery.SchemaField("Year", "INTEGER", mode="REQUIRED"),
    bigquery.SchemaField("Month", "INTEGER", mode="REQUIRED"),
    bigquery.SchemaField("Forecasted_Sales_Quantity", "INTEGER", mode="NULLABLE"),
    bigquery.SchemaField("Forecasted_Revenue", "FLOAT", mode="NULLABLE"),
    bigquery.SchemaField("Forecasted_Expense", "FLOAT", mode="NULLABLE"),
    bigquery.SchemaField("Forecasted_Profit", "FLOAT", mode="NULLABLE"),
]

try:
    client.get_table(output_table_ref)
except NotFound:
    table = bigquery.Table(output_table_ref, schema=schema)
    table = client.create_table(table)
    print(f"Created table {output_table_ref.project}.{output_table_ref.dataset_id}.{output_table_ref.table_id}")

# Save results to BigQuery table, overwrite if exists
job_config = bigquery.LoadJobConfig(
    write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    schema=schema
)

client.load_table_from_dataframe(forecast_df, output_table_ref, job_config=job_config).result()
print(f"Forecast data successfully loaded to {output_table_ref.project}.{output_table_ref.dataset_id}.{output_table_ref.table_id}")
