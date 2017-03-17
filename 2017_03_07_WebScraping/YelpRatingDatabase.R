### getting list of restaurant with rating and URL

install.packages("rvest")
library(rvest)

###Set range of pages
i = 2
n = 10
while(i <= 1020)
{
    PageURL <- paste("https://www.yelp.cz/search?find_loc=Praha&start=",i,"&cflt=restaurants",sep="")
    i <- i+n
    print(PageURL)
    
    ### Set system sleep time
    Sys.sleep(runif(1, 2.0, 9.5))
    
    ### Get actual URL
    Yelp <- read_html(PageURL)
    
    ### Get Name, URL and Rating of restaurant
    Names  <- html_nodes(Yelp,".column-alpha .main-attributes span a")
    URL    <- paste("https://www.yelp.cz/",as.character(html_attr(Names,"href")),sep="")
    Rating <- html_attr(html_nodes((html_nodes(Yelp,"div.biz-rating.biz-rating-large.clearfix")),'img.offscreen'),'alt')
    Names  <- encodeString(html_text(Names),"UTF-8")
    YelpDatabase <- cbind(Names,URL,Rating)
    
    ### Explore set
    head(YelpDatabase)
    str(YelpDatabase)
    
}
