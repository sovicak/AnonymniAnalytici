import pandas as pd
import os
perf = pd.read_pickle('workshop-files/buy_and_hodl_exercise_b.pickle') # read in perf DataFrame
perf.to_csv('workshop-files/buy_and_hodl_exercise_b.csv')
print(perf.head())


#data = pd.read_csv('workshop-files/buy_btc_simple_out.csv')
#data.columns
