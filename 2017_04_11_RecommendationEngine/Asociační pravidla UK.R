library(arules); 
library(Matrix);
library(sqldf);
library(dplyr);
library(lubridate);
library(reshape2);
library(arulesViz);

setwd("D:\\Work&Education\\Anonymní Analytici\\20170411 Recommendation engine\\")
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
dt <- split(DataUK[,2], DataUK[,1]);
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
head(DataUK)

dataNodesMerge <- merge(x = DataUK, y = dataClusters[dataClusters$node != 268 ,c("node","Description")], key = "Description", x.all = TRUE)
dataAR <- data.frame(sqldf("select distinct InvoiceNo, node from dataNodesMerge"))
head(dataAR)

dtNodes <- split(dataNodesMerge[,1], dataNodesMerge[,2]);
dtNodes2 = as(dtNodes,"transactions");
rulesNodes = apriori(dtNodes2, parameter=list(support=10/nrow(dtNodes2), confidence=0.8,minlen = 2));

inspect(rulesNodes[1:50])
plot(rulesNodes[1:20], method="graph", control=list(type="items"))

top.support <- sort(rulesNodes, decreasing = TRUE, na.last = NA, by = "support")
inspect(head(top.support, 10))
plot(rulesNodes[1:10], method="graph", control=list(type="items"))

top.confidence <- sort(rulesNodes, decreasing = TRUE, na.last = NA, by = "confidence")
inspect(head(top.confidence, 10))
plot(rulesNodes[1:10], method="graph", control=list(type="items"))

top.lift <- sort(rulesNodes, decreasing = TRUE, na.last = NA, by = "lift")
inspect(head(top.lift, 10))
plot(rulesNodes[1:10], method="graph", control=list(type="items"))
