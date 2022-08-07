library(tidyverse)
library(reshape2)
library(sp)
library(rgdal)
# library(sf)

DIR_WORK <- "D:/Google/MicroSim"

setwd(DIR_WORK)

source("Config.R", echo = T)

MSOA <- readOGR("GIS/London/ESRI", "MSOA_2011_London_gen_MHW")

proj4string(MSOA)

# View(MSOA@data)

## MSOA <- read_sf("GIS/London/ESRI", "MSOA_2011_London_gen_MHW")

# is.unsorted(MSOA$MSOA11CD)

MSOA <-
  MSOA[order(MSOA$MSOA11CD), ] # Make sure the result is ordered. (Strange: the sorted object is not identical to the original.)

if (is.unsorted(MSOA$MSOA11CD))
  myStop("MSOA IDs are not sorted.")

dist <- spDists(MSOA)

## dist <- st_distance(st_centroid(MSOA))

# View(dist)

distPair <- melt(dist) # melt.matrix().

# View(distPair)

nameList <- data.frame(MSOA$MSOA11CD)

if (is.unsorted(nameList$MSOA.MSOA11CD))
  myStop("The name list is not sorted.")

# View(nameList)

nameList$Var <- 1:nrow(nameList)

distPair1 <- inner_join(distPair, nameList, by = c("Var1" = "Var"))

distPair1 <- inner_join(distPair1, nameList, by = c("Var2" = "Var"))

# View(distPair1)

distPair2 <- distPair1[, c(4, 5, 3)]

# View(distPair2)

colnames(distPair2) <- c("MSOAID_O", "MSOAID_D", "Distance")

distPair2 <-
  arrange(distPair2, MSOAID_O, MSOAID_D) # Make sure the result is ordered.

# Should be all equal (orig to dest == dest to orig).
# table(distPair1$value == distPair2$Distance)

write_csv(distPair2, "MSOADistance.csv")
