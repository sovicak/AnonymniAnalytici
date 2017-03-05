# Beginner’s guide to Web Scraping in Python (using BeautifulSoup)
# Analytics Vidhya
# https://www.analyticsvidhya.com/blog/2015/10/beginner-guide-web-scraping-beautiful-soup-python/

# adjusted for Python 3

# Import libraries

import urllib # to query a website
from bs4 import BeautifulSoup # to parse the data returned from the website
import pandas as pd


# Specify the url

wiki = "https://en.wikipedia.org/wiki/List_of_state_and_union_territory_capitals_in_India"


# Query the website and return the html to the variable 'page'

page = urllib.request.urlopen(wiki)


# Parse the html in the 'page' variable, and store it in Beautiful Soup format

soup = BeautifulSoup(page, "html.parser")

print(soup.prettify())

soup.get_text()
soup.title
soup.title.string
soup.title.parent.name
soup.a


# Find all links

all_links = soup.find_all("a")
for link in all_links:
    print(link.get("href"))
    print("\n")

    
# Find the right table

right_table = soup.find("table", {"class": "wikitable sortable plainrowheaders"})


# Generate lists

A=[]
B=[]
C=[]
D=[]
E=[]
F=[]
G=[]

for row in right_table.find_all("tr"):
    cells = row.find_all('td')
    states = row.find_all('th') # to store second column data
    if len(cells)==6: # only extract table body not heading
        A.append(cells[0].find(text=True))
        B.append(states[0].find(text=True))
        C.append(cells[1].find(text=True))
        D.append(cells[2].find(text=True))
        E.append(cells[3].find(text=True))
        F.append(cells[4].find(text=True))
        G.append(cells[5].find(text=True))

# Note: Punjab is missing in results (its row contain only 5 cells) 
#<td>28</td>
#<th scope="row"><a href="/wiki/Punjab,_India" title="Punjab, India">Punjab</a></th>
#<td><b><a href="/wiki/Chandigarh" title="Chandigarh">Chandigarh</a></b></td>
#<td>Chandigarh</td>
#<td>Chandigarh</td>
#<td>1966</td>
#</tr>
  
# Convert lists to data frame

df = pd.DataFrame(A, columns = ['Number'])

df['State/UT'] = B
df['Admin_Capital'] = C
df['Legislative_Capital'] = D
df['Judiciary_Capital'] = E
df['Year_Capital'] = F
df['Former_Capital'] = G

print(df)

