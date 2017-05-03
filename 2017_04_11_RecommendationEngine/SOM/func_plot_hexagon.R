# Inspired by Shane Lynn
# http://www.shanelynn.ie/self-organising-maps-for-customer-segmentation-using-r/


library(RColorBrewer) #to use brewer.pal
library(fields) #to use designer.colors

#Function to create the polygon for each hexagon
Hexagon <- function (x, y, unitcell = 1, col = col) {
  polygon(c(x
            , x
            , x + unitcell/2
            , x + unitcell
            , x + unitcell
            , x + unitcell/2)
          , c(y + unitcell * 0.125 
              , y + unitcell * 0.875 
              , y + unitcell * 1.125 
              , y + unitcell * 0.875 
              , y + unitcell * 0.125 
              , y - unitcell * 0.125)
          , col = col, border = NA)
}#function



PlotHexagonFromMatrix <- function (Heatmap_Matrix, name = NULL) {
  
  x <- as.vector(Heatmap_Matrix)
  
  #Number of rows and columns of your SOM
  SOM_Rows <- dim(Heatmap_Matrix)[1]
  SOM_Columns <- dim(Heatmap_Matrix)[2]
  
  #To make room for the legend
  par(mar = c(0.4, 2, 2, 7))
  
  #Initiate the plot window but do show any axes or points on the plot
  plot(0, 0, type = "n"
       , axes = FALSE
       , xlim = c(0, SOM_Columns)
       , ylim = c(0, SOM_Rows)
       , xlab = ""
       , ylab =  ""
       , asp = 1
       , main = name)
  
  #Create the color palette 
  ColRamp <- rev(designer.colors(n = 50, col = brewer.pal(9, "Spectral")))
  
  #Match each point from x with one of the colors in ColorRamp
  ColorCode <- rep("#FFFFFF", length(x)) #default is all white
  Bins <- seq(min(x, na.rm = T), max(x, na.rm = T), length = length(ColRamp))
  for (i in 1:length(x))
    if (!is.na(x[i])) ColorCode[i] <- ColRamp[which.min(abs(Bins - x[i]))] 
  
  #Actual plotting of hexagonal polygons on map
  offset <- 0.5 #offset for the hexagons when moving up a row
  for (row in 1:SOM_Rows) {
    for (column in 0:(SOM_Columns - 1)) 
      Hexagon(column + offset, row - 1, col = ColorCode[row + SOM_Rows * column])
    offset <- ifelse(offset, 0, 0.5)
  }
  
  #Add legend to the right
  image.plot(legend.only = TRUE
             , col = ColRamp
             , zlim=c(min(x, na.rm = T), max(x, na.rm = T)))
}


PlotHexagon <- function (data, nrow, ncol, name = NULL) {
  
  Heatmap_Matrix = matrix(data, nrow = nrow, ncol = ncol, byrow = TRUE)
  
  PlotHexagonFromMatrix(Heatmap_Matrix, name)
  
}


AddHexagonClusterBoundaries <- function (x, clustering, unitcell = 1, lwd = 5) {
  # upravena funkce add.cluster.boundaries() z package kohonen
  
  grd <- x$grid
  cluster <- clustering
  
  
  # dimenze SOM objektu
  SOM_Rows <- grd$ydim 
  SOM_Columns <- grd$xdim
  
  
  # koordinaty (pro vypocet sousednich bunek)
  coor = data.table(items = c(1:(SOM_Rows*SOM_Columns)) 
                    , rows = rep(c(1:SOM_Columns), each = SOM_Rows)
                    , cols = rep(c(1:SOM_Rows), SOM_Columns)) # matice souradnic
  
  
  # koordinaty pro kresleni obrysu
  coor2 = data.frame(items = coor$items 
                     , cols = coor$cols - 0.5 + 0.5 * (coor$rows %% 2 - 1)
                     , rows = coor$rows - 1)
  

  grd$pts[, 1] = coor2$cols
  grd$pts[, 2] = coor2$rows

  
  # sousedni bunky pro sestiuhelniky
  neighbours = data.frame(HexagonNeighbours(SOM_Rows, SOM_Columns))
    
  
  # jsou sousedni bunky v ruznych clusterech?
  diffclass.idx <- sapply(1:nrow(neighbours), function(ii) cluster[neighbours[ii, 1]] != cluster[neighbours[ii, 2]]) 
  
  
  # sousedi jenom z ruznych clusteru
  nb <- neighbours[diffclass.idx, ] 

  
  # kresleni segmentu
  par(mar = c(0.4, 2, 2, 7))
  
  for (i in 1:nrow(nb)) {
    u1 <- nb[i, 1]
    u2 <- nb[i, 2]
    dloc <- grd$pts[u1, ] - grd$pts[u2, ]
    if (abs(dloc[2]) < 0.1) {
      segments(grd$pts[u2, 1] 
               , grd$pts[u2, 2] + unitcell * 0.875
               , grd$pts[u2, 1] 
               , grd$pts[u2, 2] + unitcell * 0.125
               , lwd = lwd, xpd = NA)
      if (dloc[1] > 0.9)  {
        segments(grd$pts[u2, 1] + unitcell
                 , grd$pts[u2, 2] + unitcell * 0.875
                 , grd$pts[u2, 1] + unitcell
                 , grd$pts[u2, 2] + unitcell * 0.125
                 , lwd = lwd, xpd = NA)  
      }
    }
    else {
      if (dloc[2] > 0.1) {
        segments(grd$pts[u2, 1] + unitcell/2
                 , grd$pts[u2, 2] + unitcell * 1.125
                 , grd$pts[u2, 1] + unitcell
                 , grd$pts[u2, 2] + unitcell * 0.875
                 , lwd = lwd, xpd = NA)  
        if (dloc[1] < -0.1) {
          segments(grd$pts[u2, 1] + unitcell/2
                   , grd$pts[u2, 2] + unitcell * 1.125
                   , grd$pts[u2, 1]
                   , grd$pts[u2, 2] + unitcell * 0.875
                   , lwd = lwd, xpd = NA) 
        }
      }
      else {
        if (dloc[1] > 0.1) {
          segments(grd$pts[u2, 1] + unitcell/2
                   , grd$pts[u2, 2] - unitcell * 0.125
                   , grd$pts[u2, 1] + unitcell
                   , grd$pts[u2, 2] + unitcell * 0.125
                   , lwd = lwd, xpd = NA)    
        }
        else {
          segments(grd$pts[u2, 1] + unitcell/2
                   , grd$pts[u2, 2] - unitcell * 0.125
                   , grd$pts[u2, 1]
                   , grd$pts[u2, 2] + unitcell * 0.125
                   , lwd = lwd, xpd = NA)               
        }
      }
    }
  }
  
  invisible()
  
}


HexagonNeighbours <- function(nrow, ncol) {
  
  coor = data.table(items = c(1:(ncol*nrow))
                    , rows = rep(c(1:nrow), each = ncol)
                    , cols = rep(c(1:ncol), nrow)) # matice souradnic
  
  neighbours = data.frame(item1 = as.integer(), item2 = as.integer())
  
  for (i in 1: (ncol*nrow)) {
    if (coor[i, ]$cols != ncol) {
      neighbours = rbind(neighbours, cbind(item1 = i, item2 = i + 1))
    }
    if (coor[i, ]$rows != nrow) {
      neighbours = rbind(neighbours, cbind(item1 = i, item2 = i + ncol))
      if (coor[i, ]$cols != ncol & coor[i, ]$rows %% 2 == 1) {
        neighbours = rbind(neighbours, cbind(item1 = i, item2 = i + ncol + 1))
      }
      if (coor[i, ]$cols != 1 & coor[i, ]$rows %% 2 == 0) {
        neighbours = rbind(neighbours, cbind(item1 = i, item2 = i + ncol - 1))
      }
    }
  }
  
  return(neighbours)
}




