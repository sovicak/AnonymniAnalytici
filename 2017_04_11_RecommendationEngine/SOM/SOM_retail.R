# Using textual descriptions to cluster similar products
# This should be useful to reduce data dimensionality
# for recommendation engines

# Download example data from http://archive.ics.uci.edu/ml/datasets/Online+Retail
# and save it into the same directory as this scipt

# SOM maps inspired by Shane Lynn
# https://www.slideshare.net/shanelynn/2014-0117-dublin-r-selforganising-maps-for-customer-segmentation-shane-lynn


library(data.table)
library(ggplot2)
library(cluster)
library(kohonen)
library(fpc)
library(readxl)
library(tm)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source('./coolBlueHotRed.R')
source('./func_plot_hexagon.R')


# DATA LOAD

df = read_excel("./Online Retail.xlsx")
data = data.table(df) # data table
items = unique(data[, Description]) # unique product descriptions

# basic statistics

data[, .N, by = CustomerID][, .N] # number of customers
data[, .N, by = Country][, .N] # number of countries
data[, .N, by = StockCode][, .N] # number of products (code)
data[, .N, by = Description][, .N] # number of products (description)

data[, .N, by = .(StockCode, Description)][, .N, by = StockCode][order(N, decreasing = TRUE)] # number of products/descriptions
data[StockCode == '85123A'][, .N, by = Description]

data[, .N, by = .(StockCode, Description)][, .N, by = Description][order(N, decreasing = TRUE)] # number of products/descriptions


# TM PACKAGE (text mining)

# corpus

corp = Corpus(VectorSource(items))

inspect(corp[25:35])
corp[[25]]$meta
corp[[25]]$content # kontrola


# text transformations

corp = tm_map(corp, stripWhitespace)
corp = tm_map(corp, content_transformer(tolower))
corp = tm_map(corp, removeWords, stopwords("english"))
corp = tm_map(corp, removePunctuation)
corp = tm_map(corp, stemDocument)

rename_nbr <- function (x) {
  ## replace all nubmers with term "XnumberX"
  gsub("[[:digit:]]+\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*\\.*\\,*[[:digit:]]*", "XnumberX", x)
}

corp = tm_map(corp, content_transformer(rename_nbr))

corp[[25]]$content # kontrola


# document-term matrix

dtm = DocumentTermMatrix(corp, control = list(bounds = list(global = c(3, Inf)))) # vyradit terms, ktere jsou v mene nez 3 dokumentech
inspect(dtm[1:35, 600:610])


# dtm overview

dtm2 = data.table(as.matrix(dtm))
freq = data.table(terms = colnames(dtm2), freq = as.vector(t(dtm2[, lapply(.SD, sum)])))
freq[order(freq, decreasing = TRUE)] # nejcastejsi pojmy


# SOM (Self-Organizing Network)

# SOM model

Sys.time()
set.seed(112233)
model.som = som(dtm, # data musi by matice!!!
                grid = somgrid(xdim = 20, ydim = 20, topo = "hexagonal"), 
                rlen = 200, 
                alpha = c(0.1, 0.001), 
                n.hood = "circular",
                keep.data = TRUE)
Sys.time() # cca pul hodiny

plot(model.som, type = "changes")
plot(model.som, type = "counts", main="Node Counts", palette.name = coolBlueHotRed) # counts within nodes
plot(model.som, type = "quality", main="Node Quality/Distance", palette.name = coolBlueHotRed) # map quality
plot(model.som, type = "dist.neighbours", main = "SOM neighbour distances", palette.name = grey.colors) # neighbour distances
#plot(model.som, type = "codes", codeRendering = 'stars') #code spread, nepouzivat 'segments' - pri velkych datech zasekne komplet vsechno


# nodes visualisation

nclust = nrow(model.som$grid$pts) # pocet clusteru

centroids = data.table(cbind(XclassX = model.som$unit.classif, dtm2)) # vypocet "centroidu" uzlu (aby nebyly hodnoty v grafu normovane)
centroids = centroids[, lapply(.SD, mean), by = XclassX] # je nutne pouzit XclassX, protoze "class" se muze vyskytovat uvnitr datasetu
classes = data.table(XclassX = c(1:nclust))
setkey(centroids, XclassX)
setkey(classes, XclassX)
centroids = centroids[classes]
centroids[, XclassX := NULL]
centroids = data.frame(centroids)

center = apply(dtm2, 2, mean, na.rm = TRUE)

for (i in 1:nclust) {  # odstraneni chybejicich hodnot (prazdne uzly vyplnene prumernymi hodnotami)
  if (is.na(centroids[i, 1])) {
    centroids[i, ] = center
  } 
}
table(is.na(centroids)) # kontrola

var = which(colnames(centroids) == "clock") # vybrane slovo (ve tvaru po stemmingu)

PlotHexagon(centroids[, var]
            , nrow = model.som$grid$ydim
            , ncol = model.som$grid$xdim
            , name = colnames(dtm2)[var])


# CLUSTERING SOM NODES (OPTIONAL)
# Clusters of clusters to reduce the dimensionality even more

# distance matrix

neigh = HexagonNeighbours(nrow = model.som$grid$ydim
                          , ncol = model.som$grid$xdim)
neigh = data.table(neigh)
neigh[, neigh := TRUE]

x = model.som$grid$ydim # columns
y = model.som$grid$xdim # rows

dist_mat = daisy(model.som$codes, metric = "euclidean") # distance matrix, puvodni

dist_mat_index = data.table(item1 = rep(c(1:(x*y)), each = x*y), item2 = rep(c(1:(x*y)), x*y)) # indexy jako v distance matrix
dist_mat_index = dist_mat_index[dist_mat_index$item1 < dist_mat_index$item2]
setkey(neigh, item1, item2)
setkey(dist_mat_index, item1, item2)

dist_mat_index_neigh = neigh[dist_mat_index]
dist_mat_index_neigh[is.na(dist_mat_index_neigh)] = FALSE

dist_mat_neigh = dist_mat # upravena distance matrix (ma nekonecno pro nesousedni bunky)
dist_mat_neigh[dist_mat_index_neigh$neigh == FALSE] =  max(dist_mat) * 100000000000000000

nodes = data.table(XclassX = c(1:(x*y)))
nodes_counts = data.table(XclassX = model.som$unit.classif)[, .N, by = XclassX] # pocty pozorovani v uzlech
setkey(nodes, XclassX)
setkey(nodes_counts, XclassX)
nodes_counts = nodes_counts[nodes]
nodes_counts[is.na(nodes_counts)] = 0


# clustering neighbours only

clusters.pom = hclust(dist_mat_neigh, method = "ward.D", members = nodes_counts$N)
clusters.som = cutree(clusters.pom, k = 15)

PlotHexagon(clusters.som
            , nrow = model.som$grid$ydim
            , ncol = model.som$grid$xdim
            , name = "Clusters")
AddHexagonClusterBoundaries(model.som, clusters.som, lwd = 5)


# variable importance

var_imp = data.table(cbind(XclassX = clusters.som, model.som$codes))
var_imp = var_imp[, lapply(.SD, mean), by = XclassX]
var_imp[, XclassX := NULL]

sel_clust = 1 # vybrany cluster

var_imp_sel = data.table(col = c(1:ncol(var_imp))
                         , col_name = colnames(var_imp)
                         , importance = t(var_imp[sel_clust, ])[, 1])
var_imp_sel[order(importance, decreasing = TRUE)]

var = 74 # vybrane slovo (podle poradoveho cisla)
#var = which(colnames(centroids) == "necklac") # vybrane slovo (ve tvaru po stemmingu)

PlotHexagon(centroids[, var]
            , nrow = model.som$grid$ydim
            , ncol = model.som$grid$xdim
            , name = colnames(dtm2)[var])
AddHexagonClusterBoundaries(model.som, clusters.som, lwd = 5)


# descriptions with assigned clusters

clusters.som2 = data.table(cbind(node = c(1:nclust), cluster = clusters.som)) # (x*y)
setkey(clusters.som2, node)

clustered_items = data.table(cbind(node = as.integer(model.som$unit.classif)
                                   , description = items))
clustered_items[, node := as.integer(node)]
setkey(clustered_items, node)

clustered_items = clusters.som2[clustered_items]
#clustered_items2 = clustered_items[, .(node, description)]


# save clusters

write.csv2(clustered_items, file = "clustered_items.csv", row.names = FALSE)
