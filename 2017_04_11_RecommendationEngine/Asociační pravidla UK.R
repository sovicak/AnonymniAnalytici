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

DataUK <- data[data$Country == "United Kingdom" & data$Description != "POSTAGE",c("InvoiceNo","Description")]
head(DataUK)

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

###Merge data with nodes information
dataClusters <- read.csv("clustered_items.csv",sep = ";", stringsAsFactors = F)
head(dataClusters)  
str(dataClusters)
names(dataClusters) <- c("node","cluster","Description")

dataNodesMerge <- merge(x = by_CustomerProd, y = dataClusters[,c("node","Description")], key = "Description", all.x = TRUE)
head(dataNodesMerge)
dataAR <- data.frame(sqldf("select distinct InvoiceNo,node from dataNodesMerge"))
head(dataAR)


top.support <- sort(rules, decreasing = TRUE, na.last = NA, by = "support")
inspect(head(top.support, 10))


top.confidence <- sort(rules, decreasing = TRUE, na.last = NA, by = "confidence")
inspect(head(top.confidence, 10))

top.lift <- sort(rules, decreasing = TRUE, na.last = NA, by = "lift")
inspect(head(top.lift, 10))

inspect(rules[1:50])
plot(rules[1:20], method="graph", control=list(type="items"))

