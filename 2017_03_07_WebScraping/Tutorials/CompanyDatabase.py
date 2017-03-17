try:
    import urllib.request as urllib2
except ImportError:
    import urllib2
from xml.etree import ElementTree as ET
import time
import json
from datetime import datetime
import sys



       
url1 = 'http://www.edb.cz/list.aspx?l=cz&p='
url2 = '&region=hk&slv=hradec+kr%e1lov%e9'

tab_s = '<table class="striped films">'
tab_body_s = '<tbody>'
tab_body_e = '</tbody>'
tab_e = '</table>'
            

for page in range(1,2):

       time.sleep(60)
       
       url = url1 + str(page) + url2
    
       req = urllib2.Request(url)        
       req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36')
       req.add_header('Referer', 'http://www.edb.cz/List.aspx?l=CZ&slv=')
        
       val = 0
       while val == 0:
           try:
               response = urllib2.urlopen(req)
               val = 1
           except:
               print('Chyba stránky')
               sys.stdout.flush()
               time.sleep(30)
            
       s = response.read().decode('utf-8')
       if s.find('Je zobrazeno pouze prvních 25 nalezených firem. Pokud jsi nenašel co hledáš, upřesni hledání.')>0:
           print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Na stránce ' + str(page) + ' nemusí být staženy všechny záznamy')
           sys.stdout.flush()
       if s.find('žádné filmy neodpovídají zadaným podmínkám')<=0:
           s = s[s.find(tab_s):]
           s = s[s.find(tab_body_s):]
           s = s[:s.find(tab_body_e)+len(tab_body_e)]


           table = ET.XML(s)

           for row in table:
               res = ''
               for i in row:
                   if str(i.attrib) == "{'class': 'name'}":
                       for j in i:
                           res = res + str(j.text) + '|'
                   else:
                       res = res + str(i.text) + '|'
               print(res)
               sys.stdout.flush()
       else:
           page = 21

print("done")   

