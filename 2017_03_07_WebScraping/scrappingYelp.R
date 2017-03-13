# scrapping Yelp

library(magrittr)
library(rvest)

# init

nextUrl<-'/search?find_loc=Praha&start=0&cflt=restaurants'
getNext<-T

while(getNext){
    
    # wait
  
    Sys.sleep(sample(1:10,1))
  
    # url
  
    urlYelp<-paste0('https://www.yelp.cz',nextUrl)
    rawYelp<-paste(readLines(urlYelp,encoding='UTF-8'),collapse='')
    
    # tree
    
    treeYelp<-read_html(rawYelp)    
    
    # fetch properties from main page
    
    name<-treeYelp %>% html_nodes('a.biz-name.js-analytics-click') %>% 
            html_nodes('span') %>% html_text()
    
    # fix encoding
    
    Encoding(name)<-'UTF-8'

    rating<-treeYelp %>% html_nodes('div.biz-rating.biz-rating-large.clearfix') %>% 
              html_nodes('img.offscreen') %>% html_attr('alt') %>% 
                substr(1,3) %>% as.numeric()
    
    priceRange<-treeYelp %>% html_nodes('span.business-attribute.price-range') %>% 
                  html_text()
    
    #category<-treeYelp %>% html_nodes('span.category-str-list') %>% 
    #            lapply(function(x){x %>%  html_nodes('a') %>% html_text()})
    
    url<-treeYelp %>% html_nodes('a.biz-name.js-analytics-click') %>% 
          html_attr('href')
    
    # combine properties
    
    if (!exists('scrappedResults')){
      
      scrappedResults<-data.frame(name,rating,priceRange,url,stringsAsFactors=T)
    
      }else{
      
      scrappedResults<-rbind(scrappedResults,cbind(name,rating,priceRange,url))
        
    }
    
    # page of pages
    
    pageOf<-treeYelp %>% html_nodes('div.page-of-pages.arrange_unit--fill') %>% 
              html_text() %>% trimws() %>% strsplit(' ') %>% extract2(1) %>% 
                extract(c(2,4)) %>% as.numeric()
    
    # next page?
    
    getNext<-pageOf[1]!=pageOf[2]
    
    # next page!
    
    if(getNext){
      nextUrl<- treeYelp %>% html_nodes('a.u-decoration-none.next.pagination-links_anchor') %>% 
        html_attr('href')}
} 

# clean up
rm(list=setdiff(ls(), "scrappedResults"))
