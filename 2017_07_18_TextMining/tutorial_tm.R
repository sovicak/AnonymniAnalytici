#install.packages("tm.corpus.Reuters21578", repos = "http://datacube.wu.ac.at")

library(data.table)
library(tm)
library(tm.corpus.Reuters21578)
library(wordcloud)


# DATA LOAD

# Reuters data set is ready in VCorpus format. However;
# I wanted to do some changes, so I converted it into data table.
# Feel free to use the original Reuters VCorpus instead.

data(Reuters21578)
head(meta(Reuters21578, "topics_cat"), 100)
head("grain" %in% meta(Reuters21578, "topics_cat"), 100)

dataset_df = data.frame("id" = integer(), "heading" = character(), "content" = character(), "topics_cat" = character(), stringsAsFactors = FALSE)
for (i in 1:length(Reuters21578)) {
  dataset_df[i, "id"] = i
  dataset_df[i, "heading"] = ifelse(length(as.character(Reuters21578[[i]]$meta$heading)) == 0, NA, as.character(Reuters21578[[i]]$meta$heading))
  dataset_df[i, "content"] = ifelse(length(as.character(Reuters21578[[i]]$content)) == 0, NA, as.character(Reuters21578[[i]]$content))
  dataset_df[i, "topics_cat"] = ifelse(length(as.character(Reuters21578[[i]]$meta$topics_cat)) == 0, NA, paste(meta(Reuters21578[[i]], "topics_cat"), collapse = " "))
}


# data transformations

dataset = data.table(dataset_df)
dataset[, `:=`(content = gsub("\n", " ", content))]

dataset = dataset[!is.na(content)]

dataset[, `:=`(earn = ifelse(.I %in% grep("earn", dataset$topics_cat), 'yes', 'no')
              , acq = ifelse(.I %in% grep("acq", dataset$topics_cat), 'yes', 'no')
              , money_fx = ifelse(.I %in% grep("money-fx", dataset$topics_cat), 'yes', 'no')
              , grain = ifelse(.I %in% grep("grain", dataset$topics_cat), 'yes', 'no')
              , crude = ifelse(.I %in% grep("crude", dataset$topics_cat), 'yes', 'no')
              , trade = ifelse(.I %in% grep("trade", dataset$topics_cat), 'yes', 'no')
              , interest = ifelse(.I %in% grep("interest", dataset$topics_cat), 'yes', 'no')
)]


# overview

dataset[, .N, by = topics_cat][order(N, decreasing = TRUE)] # counts of combinations of categories

sort(table(unlist(strsplit(dataset$topics_cat, split = " "))), decreasing = TRUE)
table(dataset$earn)


# TM PACKAGE

# corpus

corp = VCorpus(DataframeSource(dataset), readerControl = list(reader = readTabular(mapping = list(content = "content", id = "id", earn = "earn"))))

inspect(corp[25:35])

corp[[15517]]$meta # id 17470
corp[[15517]]$content


# transformations

corp = tm_map(corp, stripWhitespace)
corp = tm_map(corp, content_transformer(tolower))
corp = tm_map(corp, removeWords, stopwords("english"))
corp = tm_map(corp, removePunctuation)
corp = tm_map(corp, stemDocument)

rename_nbr <- function (x) {
  ## nahradi vsechny cisla slovem XnumberX
  gsub("[[:digit:]]+\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*", "XnumberX", x)
}
corp = tm_map(corp, content_transformer(rename_nbr))

corp[[15517]]$meta # id 17470
corp[[15517]]$content


# document-term matrix (try different ways of weighting)

dtm = DocumentTermMatrix(corp, control = list(bounds = list(global = c(4, Inf)))) # delete terms which are in less than 4 documents
inspect(dtm[1:35, 600:610])

dtm_idf = DocumentTermMatrix(corp, control = list(bounds = list(global = c(4, Inf)), weighting =  function(x) weightTfIdf(x, normalize = TRUE))) # delete terms which are in less than 4 documents
inspect(dtm_idf[1:35, 600:610])


# remove sparse terms

dtm_wst = removeSparseTerms(dtm, 0.99)
inspect(dtm_wst[1:35, 600:610])

dtm_wst2 = removeSparseTerms(dtm, 0.95)
inspect(dtm_wst2[1:35, 100:110])


# dtm overview

dtm2 = data.table(as.matrix(dtm))
freq = data.table(terms = colnames(dtm2), freq = as.vector(t(dtm2[, lapply(.SD, sum)])))
freq[order(freq, decreasing = TRUE)] # the most frequent terms
freq[freq > 250] # terms with frequency higher than 250

dtm_idf2 = data.table(as.matrix(dtm_idf))
freq2 = data.table(terms = colnames(dtm_idf2), freq = as.vector(t(dtm_idf2[, lapply(.SD, sum)])))

findFreqTerms(dtm, 250) # terms with frequency higher than 250 directly from dtm
findFreqTerms(dtm_wst, 250)

findAssocs(dtm, "bank", 0.2) # associated terms
findAssocs(dtm, "interest", 0.2)


# WORDCLOUDS

wordcloud(corp, max.words = 100, random.order = FALSE) # weighting tf
wordcloud(freq2$terms, freq2$freq, max.words = 100, random.order = FALSE) # weighting tf-idf

wordcloud(corp[meta(corp, "earn") ==  "yes"], max.words = 100, random.order = FALSE) # weighting tf (earn topic only)

