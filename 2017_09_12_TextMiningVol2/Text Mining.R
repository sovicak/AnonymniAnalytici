library(data.table)
library(tm)

# path to the folder where the data is
path <- "D:\\Work&Education\\Anonymní Analytici\\20170718 Text mining"
setwd(path)
dir()

# DATA LOAD

# Read Yelp data set
data <- read.csv("nightlife_sanfrancisco_en.csv", stringsAsFactors = FALSE)

# Remove end of line
data$text = gsub("\n", " ", data$text)


# Explore data
head(data)
str(data)
table(is.na(data$text))
table(is.na(data$stars))


# Create corpus
corp = VCorpus(DataframeSource(data), readerControl = list(reader = readTabular(mapping = list(content = "text", company = "company", stars = "stars"))))

# Inspect corpus
inspect(corp[1])
corp[[1]]$meta
corp[[1]]$content


# Transformations
# Strip extra whitespace from a text document
corp = tm_map(corp, stripWhitespace)
# Convert to lowercase
corp = tm_map(corp, content_transformer(tolower))
# Remove stop words
corp = tm_map(corp, removeWords, stopwords("english"))
# Remove punctuation
corp = tm_map(corp, removePunctuation)
# Stem data
corp = tm_map(corp, stemDocument)
# Replace all numbers with expression "XnumberX"
rename_nbr <- function (x) {
  gsub("[[:digit:]]+\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*", "XnumberX", x)
}
corp = tm_map(corp, content_transformer(rename_nbr))
# or alternatively use: DocumentTermMatrix(corpus, list(removePunctuation = TRUE, stopwords = TRUE, stemming = TRUE, removeNumbers = TRUE))


# remove sparse terms
    corp_modif = removeSparseTerms(DocumentTermMatrix(corp), 0.99)
    #ALTERNATIVELY
    # create document term matrix with dynamic number of deleted terms; delete tems that are in less than 0.5 % documents
      corp_modif = DocumentTermMatrix(corp, control = list(bounds = list(global = c(floor(nrow(data)*0.005), Inf))))
    # or ALTERNATIVELY
    # create weighting document term matrix and delete terms which are in less than 4 documents
      corp_modif = DocumentTermMatrix(corp, control = list(bounds = list(global = c(4, Inf)), weighting =  function(x) weightTfIdf(x, normalize = TRUE)))
      

# Data overview     
DataOverview <- data.table(as.matrix(corp_modif))
freq = data.table(terms = colnames(DataOverview), freq = as.vector(t(DataOverview[, lapply(.SD, sum)])))
# the most frequent terms
freq[order(freq, decreasing = TRUE)] 
# terms with frequency higher than 250
freq[freq > 250] 

# Appended the explained variable
FinalDataset <- cbind(stars = data$stars,DataOverview)
