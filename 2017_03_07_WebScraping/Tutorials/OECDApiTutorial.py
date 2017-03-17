# Get OECD data
# from Data Visualization with Python and JavaScript: Scrape, Clean, Explore
# book from books.google.com

# Main economic indicators (MEI)
# http://stats.oecd.org/restsdmx/sdmx.ashx/GetDataStructure/MEI
    
# API documentation
# https://data.oecd.org/api/sdmx-json-documentation/

import requests as rq
import pandas as pd
import re

# DATA SCRAPING FUNCTION
 
OECD_ROOT_URL = "http://stats.oecd.org/SDMX-JSON/data"

def make_OECD_request(dsname, dimensions, params = None, root_dir = OECD_ROOT_URL):
    # Make URL for the OECD API and return a response
    # 4 dimensions: location, subject, measure, frequency
    # OECD API: https://data.oecd.org/api/sdmx-json-documentation/#d.en.330346
    
    if not params:
        params = {}
    
    dim_args = ['+'.join(d) for d in dimensions]
    dim_str = '.'.join(dim_args)
    
    url = root_dir + '/' + dsname + '/' + dim_str + '/all'
    
    print('Requesting URL ' + url)
    return rq.get(url = url, params = params)


def create_DataFrame_from_OECD(country = 'CZE', subject = [], measure = [], frequency = 'M',  startDate = None, endDate = None):     
    # Request data from OECD API and return pandas DataFrame
    
    # country: country code (max 1)
    # subject: list of subjects, empty list for all
    # measure: list of measures, empty list for all
    # frequency: 'M' for monthly and 'Q' for quaterly time series
    # startDate: date in YYYY-MM (2000-01) or YYYY-QQ (2000-Q1) format, None for all observations
    # endDate: date in YYYY-MM (2000-01) or YYYY-QQ (2000-Q1) format, None for all observations
    
    # Data download
    
    response = make_OECD_request('MEI'
                                 , [[country], subject, measure, [frequency]]
                                 , {'startTime': startDate, 'endTime': endDate, 'dimensionAtObservation': 'AllDimensions'})
    
    # Data transformation
    
    if (response.status_code == 200):
        
        responseJson = response.json()
        
        obsList = responseJson.get('dataSets')[0].get('observations')
        
        if (len(obsList) > 0):
        
            print('Data downloaded from %s' % response.url)
            
            timeList = [item for item in responseJson.get('structure').get('dimensions').get('observation') if item['id'] == 'TIME_PERIOD'][0]['values']
            subjectList = [item for item in responseJson.get('structure').get('dimensions').get('observation') if item['id'] == 'SUBJECT'][0]['values']
            measureList = [item for item in responseJson.get('structure').get('dimensions').get('observation') if item['id'] == 'MEASURE'][0]['values']
            
            obs = pd.DataFrame(obsList).transpose()
            obs.rename(columns = {0: 'series'}, inplace = True)
            obs['id'] = obs.index
            obs = obs[['id', 'series']]
            obs['dimensions'] = obs.apply(lambda x: re.findall('\d+', x['id']), axis = 1)
            obs['subject'] = obs.apply(lambda x: subjectList[int(x['dimensions'][1])]['id'], axis = 1)
            obs['measure'] = obs.apply(lambda x: measureList[int(x['dimensions'][2])]['id'], axis = 1)
            obs['time'] = obs.apply(lambda x: timeList[int(x['dimensions'][4])]['id'], axis = 1)
            obs['names'] = obs['subject'] + '_' + obs['measure']
            
            data = obs.pivot_table(index = 'time', columns = ['names'], values = 'series')
            
            return(data)
        
        else:
        
            print('Error: No available records, please change parameters')

    else:
        
        print('Error: %s' % response.status_code)
   

# DATA LOAD

# Sample

response = make_OECD_request('QNA'
    , (('USA', 'AUS'), ('GDP', 'B1_GE'), ('CUR', 'VOBARSA'), ('Q'))
    , {'startTime': '2009-Q1', 'endTime': '2010-Q1'})
    
response = make_OECD_request('MEI'
    , [['CZE'], ['LOCOPCNO', 'XTIMVA01', 'PRMNTO01', 'BPFATT01'], [], ['M']]
    , {'startTime': '2009-Q1', 'endTime': '2010-Q1', 'dimensionAtObservation': 'AllDimensions'})


# Data in DataFrame

data = create_DataFrame_from_OECD(country = 'CZE', subject = ['LOCOPCNO'])
data = create_DataFrame_from_OECD(country = 'USA', frequency = 'Q', startDate = '2009-Q1', endDate = '2010-Q1')
data = create_DataFrame_from_OECD(country = 'USA', frequency = 'M', startDate = '2009-01', endDate = '2010-12')
data = create_DataFrame_from_OECD(country = 'USA', frequency = 'M', subject = ['B6DBSI01'])
data = create_DataFrame_from_OECD(country = 'USA', frequency = 'Q', subject = ['B6DBSI01'])

