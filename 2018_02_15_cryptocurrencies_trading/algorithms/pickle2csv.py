import pandas as pd
import os
import sys

for filename in sys.argv[1:]:
    print("Converting to csv: " + filename)
    perf = pd.read_pickle('algorithms/export/'+filename+'.pickle') # read in perf DataFrame
    perf.to_csv('algorithms/export/'+filename+'.csv')
