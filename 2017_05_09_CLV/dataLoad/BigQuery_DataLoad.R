# LOADING DATA FROM BIGQUERY

library("bigrquery")
library("data.table")


# List available projects, datasets and tables

list_projects() # This asks you to authorize bigrquery in the browser

project = "clv-research-paveljasek"

list_datasets(project)

list_tables(project, dataset = "clv_aa")


# DATA LOAD

#sql = "select * from [clv-research-paveljasek:clv_aa.clv_transactions_input]"
#data_df = query_exec(sql, project = project, max_pages = Inf)

data_df = list_tabledata("clv-research-paveljasek", "clv_aa", "clv_transactions_input", max_pages = Inf)

head(data_df, n = 10)
hist(data_df$profit, xlim = c(0, 3000), breaks = 500)


# DATA TRANSFORMATIONS

data = data.table(data_df)

prevMonday <- function(x)
  7 * floor(as.numeric(x - 1 + 4) / 7) + as.Date(1 - 4, origin = "1970-01-01")

data[, monday_date := prevMonday(as.Date(date))]
data = data[order(date, transaction)]


# a) daily

data_daily = data[, .(transaction = transaction[1]
                      , date_user_created = date_user_created[1]
                      , date_first_order = date_first_order[1]
                      , zip_firstchar = zip_firstchar[1]
                      , profit = sum(profit)
                      , channel_poe = channel_poe[1]
                      , channel_type = channel_type[1]
                      , medium_source = medium_source[1]
                      , transaction_revenue = sum(transaction_revenue)
                      , item_quantity = sum(item_quantity)
                      , transaction_shipping = sum(transaction_shipping)
                      , count = .N)
                  , by = .(customer, date)]


# b) weekly

data_weekly = data[, .(transaction = transaction[1]
                       , date_user_created = date_user_created[1]
                       , date_first_order = date_first_order[1]
                       , zip_firstchar = zip_firstchar[1]
                       , profit = sum(profit)
                       , channel_poe = channel_poe[1]
                       , channel_type = channel_type[1]
                       , medium_source = medium_source[1]
                       , transaction_revenue = sum(transaction_revenue)
                       , item_quantity = sum(item_quantity)
                       , transaction_shipping = sum(transaction_shipping)
                       , count = .N)
                   , by = .(customer, monday_date)]


# DATA CHECK

sum(data$profit)
sum(data_daily$profit)
sum(data_weekly$profit)
