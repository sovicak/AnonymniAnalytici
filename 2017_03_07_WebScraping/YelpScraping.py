# GET REVIEWS FROM YELP


# Import libraries

import urllib # to query a website
from bs4 import BeautifulSoup # to parse the data returned from the website
import pandas as pd
import time
import random


# List of possible user agents to prevent getting blacklisted
# more options here: http://www.useragentstring.com/pages/useragentstring.php

userAgents = [
    'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:40.0) Gecko/20100101 Firefox/40.1',
    'Mozilla/5.0 (X11; OpenBSD amd64; rv:28.0) Gecko/20100101 Firefox/28.0',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:24.0) Gecko/20100101 Firefox/24.0',
    'Mozilla/5.0 (Windows NT 6.3; rv:36.0) Gecko/20100101 Firefox/36.0',
    'Googlebot/2.1 (+http://www.googlebot.com/bot.html)',
    'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246',
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36',
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/22.0.1207.1 Safari/537.1'\
    'Mozilla/5.0 (X11; CrOS i686 2268.111.0) AppleWebKit/536.11 (KHTML, like Gecko) Chrome/20.0.1132.57 Safari/536.11',\
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.6 (KHTML, like Gecko) Chrome/20.0.1092.0 Safari/536.6',\
    'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/536.6 (KHTML, like Gecko) Chrome/20.0.1090.0 Safari/536.6',\
    'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/19.77.34.5 Safari/537.1',\
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.9 Safari/536.5',\
    'Mozilla/5.0 (Windows NT 6.0) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.36 Safari/536.5',\
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1063.0 Safari/536.3',\
    'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1063.0 Safari/536.3',\
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_0) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1063.0 Safari/536.3',\
    'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1062.0 Safari/536.3',\
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1062.0 Safari/536.3',\
    'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1061.1 Safari/536.3',\
    'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1061.1 Safari/536.3',\
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1061.1 Safari/536.3',\
    'Mozilla/5.0 (Windows NT 6.2) AppleWebKit/536.3 (KHTML, like Gecko) Chrome/19.0.1061.0 Safari/536.3',\
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.24 (KHTML, like Gecko) Chrome/19.0.1055.1 Safari/535.24',\
    'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/535.24 (KHTML, like Gecko) Chrome/19.0.1055.1 Safari/535.24'
    ]

print(random.choice(userAgents))


# Specify the url

baseUrl = 'https://www.yelp.cz'


# Get companies names and URLs

companies = pd.DataFrame(columns = ['name', 'href'])


# a) companies from 1st page:

add = 'https://www.yelp.cz/search?cflt=nightlife&find_loc=Praha%2C+PR%2C+CZ' # Yelp Nightlife section (location Prague, language CS)

page_prep = urllib.request.Request(add)
page_prep.add_header('User-Agent', random.choice(userAgents))

page = urllib.request.urlopen(page_prep)  

soup = BeautifulSoup(page, 'html.parser')

allBiz = soup.find_all('span', {'class': 'indexed-biz-name'})
for span in allBiz:
    i = companies.shape[0]
    companies.loc[i, 'name'] = span.find('span').get_text()
    companies.loc[i, 'href'] = span.find('a').get('href')
    
    
# b) companies from next pages:
    
nextButton = soup.find('a', {'class': 'u-decoration-none next pagination-links_anchor'})

pageCount = 2 # first page was already downloaded
while nextButton and pageCount <= 5: # first 50 records (you can delete the pageCount restriction to get all records)
    
    time.sleep(15 + random.uniform(-5, 5))
    
    print('Getting companies names from page %d.' % pageCount)
    
    nextAdd = baseUrl + nextButton.get('href')
    
    page_prep = urllib.request.Request(nextAdd)
    page_prep.add_header('User-Agent', random.choice(userAgents))
    
    page = urllib.request.urlopen(page_prep)  
    
    soup = BeautifulSoup(page, 'html.parser')
    
    allBiz = soup.find_all('span', {'class': 'indexed-biz-name'})
    for span in allBiz:
        i = companies.shape[0]
        companies.loc[i, 'name'] = span.find('span').get_text()
        companies.loc[i, 'href'] = span.find('a').get('href')
        
    nextButton = soup.find('a', {'class': 'u-decoration-none next pagination-links_anchor'})
    pageCount += 1

    
# Go to company page and get its reviews (text and stars)

companies = companies.sample(frac = 1, random_state = 1234).reset_index(drop = True)

reviews = pd.DataFrame(columns = ['company', 'text', 'stars'])
for index, row in companies.iterrows():

    time.sleep(30 + random.uniform(-10, 10))
    
    print('Downloading reviews of %s.' % companies['name'][index])
    
    bizUrl = baseUrl + companies['href'][index]
    
    bizPage_prep = urllib.request.Request(bizUrl)
    bizPage_prep.add_header('User-Agent', random.choice(userAgents))
    
    bizPage = urllib.request.urlopen(bizPage_prep)
    
    bizSoup = BeautifulSoup(bizPage, 'html.parser')
    
    allRev = bizSoup.find_all('div', {'itemprop': 'review'})
    
    for review in allRev:
        i = reviews.shape[0]
        reviews.loc[i, 'company'] = companies['name'][index]
        reviews.loc[i, 'text'] = review.find('p').get_text()
        reviews.loc[i, 'stars'] = review.find('meta', {'itemprop': 'ratingValue'}).get('content')
        
    bizNextButton = bizSoup.find('a', {'class': 'u-decoration-none next pagination-links_anchor'})
        
    bizPageCount = 2 # first page was already downloaded
    while bizNextButton:
        
        time.sleep(15 + random.uniform(-5, 5))
        
        print('Getting company reviews from page %d.' % bizPageCount)
        
        nextBizAdd = bizNextButton.get('href')
        
        bizPage_prep = urllib.request.Request(nextBizAdd)
        bizPage_prep.add_header('User-Agent', random.choice(userAgents))
        
        bizPage = urllib.request.urlopen(bizPage_prep)  
        
        bizSoup = BeautifulSoup(bizPage, 'html.parser')
        
        allRev = bizSoup.find_all('div', {'itemprop': 'review'})
        
        if (len(allRev) == 0):
            
            print("Empty results.")
            break
            
        for span in allRev:
            i = reviews.shape[0]
            reviews.loc[i, 'company'] = companies['name'][index]
            reviews.loc[i, 'text'] = span.find('p').get_text()
            reviews.loc[i, 'stars'] = span.find('meta', {'itemprop': 'ratingValue'}).get('content') 
            
        bizNextButton = bizSoup.find('a', {'class': 'u-decoration-none next pagination-links_anchor'}) # otestovat
        bizPageCount += 1

