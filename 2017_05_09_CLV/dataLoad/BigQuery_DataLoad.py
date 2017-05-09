# LOADING DATA FROM BIGQUERY

from google.cloud import bigquery # We use this library only to list available datasets...
import pandas as pd # ... the real querying is done directly with pandas!
import datetime


# List available datasets and tables

client = bigquery.Client(project = 'clv-research-paveljasek')

for dataset in client.list_datasets():
    print(dataset.path)
    
dataset = client.dataset('clv_aa')

for table in dataset.list_tables():
    print(table.path)


# DATA LOAD

sql = "select * from [clv-research-paveljasek:clv_aa.clv_transactions_input]"

data = pd.read_gbq(query = sql, project_id = 'clv-research-paveljasek')


# DATA TRANSFORMATIONS

def prevMonday(x):
    x = datetime.datetime.strptime(x, "%Y-%m-%d").date()
    mon = x - datetime.timedelta(days = x.weekday())
    return(mon.strftime("%Y-%m-%d"))
    
data['monday_date'] = data['date'].apply(lambda x: prevMonday(x))
data.sort_values(by = ['date', 'transaction'], inplace = True)

# a) daily

aggregations = {
    'transaction': {'transaction': 'first'
                    , 'count': 'count'}
    , 'date_user_created': {'date_user_created': 'first'}
    , 'date_first_order': {'date_first_order': 'first'}
    , 'zip_firstchar': {'zip_firstchar': 'first'}
    , 'profit': {'profit': 'sum'}
    , 'channel_poe': {'channel_poe': 'first'}
    , 'channel_type': {'channel_type': 'first'}
    , 'medium_source': {'medium_source': 'first'}
    , 'transaction_revenue': {'transaction_revenue': 'sum'}
    , 'item_quantity': {'item_quantity': 'sum'}
    , 'transaction_shipping': {'transaction_shipping': 'sum'}
    }

data_daily = data.groupby(['customer', 'date']).agg(aggregations)
data_daily.columns = data_daily.columns.get_level_values(1)
data_daily['customer'] = data_daily.index.get_level_values(0)
data_daily['date'] = data_daily.index.get_level_values(1)
data_daily.reset_index(drop = True, inplace = True)


# b) weekly

data_weekly = data.groupby(['customer', 'monday_date']).agg(aggregations)
data_weekly.columns = data_weekly.columns.get_level_values(1)
data_weekly['customer'] = data_weekly.index.get_level_values(0)
data_weekly['monday_date'] = data_weekly.index.get_level_values(1)
data_weekly.reset_index(drop = True, inplace = True)


# DATA CHECK

data['profit'].sum()
data_daily['profit'].sum()
data_weekly['profit'].sum()
