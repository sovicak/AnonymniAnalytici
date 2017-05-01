library(arules); 
library(Matrix);
library(sqldf);
library(dplyr);
library(lubridate);
library(reshape2);
library(arulesViz);

setwd(".....")
data <- read.csv("OnlineRetail.csv",sep = ",", stringsAsFactors = F)
data$InvoiceDate <- as.Date(data$InvoiceDate, "%m/%d/%y")
data$InvoiceNo[is.na(data$InvoiceNo)] <- "Claim"

head(data)
str(data)

#Filter Only UK
unique(data$Country)
table(data$Country)

DataUK <- data[data$Country == "United Kingdom",]
head(DataUK)

### Remove claims
by_CustomerProd <- data.frame(group_by(DataUK, Description, CustomerID) 
                              %>% summarise(QuantitySum=sum(Quantity))
                              %>% filter(QuantitySum > 0 & Description != "POSTAGE"))


#Prepare data
data <- by_CustomerProd[,c(1:2)]
head(data)
dt <- split(data[,1], data[,2]);
dt2 = as(dt,"transactions");
rules = apriori(dt2, parameter=list(support=10/nrow(dt2), confidence=0.8,minlen = 2));

inspect(rules[1:10])
plot(rules[1:10], method="graph", control=list(type="items"))

quality(rules)<-cbind(quality(rules),interestMeasure(rules,measure = c("phi","gini"),trans=dt2));
rulesDF <- as(rules, "data.frame")
rulesDF$rules=gsub("\\{", "", rulesDF$rules)
rulesDF$rules=gsub("\\}", "", rulesDF$rules)
rulesDF$rules=gsub("\"", "", rulesDF$rules)
OutputDataSet <- rulesDF;
write.csv(OutputDataSet,"OutputDataSet.csv")

head(OutputDataSet)
inspect(OutputDataSet)
