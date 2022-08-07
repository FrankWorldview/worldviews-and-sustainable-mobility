library(sf)
library(tmap) # Loading tmap will change the random status!
# library(rgdal)
# library(reshape2)

source("Config.R", echo = T)
source("Utility.R", echo = T)

MY_BOROUGH_ID <-
  "E09000031" # For the MSOA mode only: specify the borough ID of interest (e.g. E09000031: Waltham Forest).

# VIEW_MODE <- "plot"
VIEW_MODE <- "view"
tmap_mode(VIEW_MODE) # View mode: "plot" for the static mode; "view" for the interactive mode.

# Create output directories.
if (!file.exists(DIR_OUTPUT))
  dir.create(DIR_OUTPUT)

if (!file.exists(DIR_OUTPUT_BOROUGH))
  dir.create(DIR_OUTPUT_BOROUGH)

if (!file.exists(DIR_OUTPUT_MSOA))
  dir.create(DIR_OUTPUT_MSOA)

# Load shape files.
if (BOROUGH_MODE) {
  # gisCity <- readOGR("GIS/London/ESRI", "London_Borough_Excluding_MHW")
  gisCity <-
    st_read("GIS/London/ESRI", "London_Borough_Excluding_MHW")
} else {
  # gisCity <- readOGR("GIS/London/ESRI", "MSOA_2011_London_gen_MHW")
  gisCity <- st_read("GIS/London/ESRI", "MSOA_2011_London_gen_MHW")
}

summary(gisCity)
# proj4string(gisCity)
# st_crs(gisCity)
# (CRS("+init=epsg:27700"))

# plot(gisCity)

saveRank <- function(file, isBorough) {
  if (isBorough) {
    ggsave(
      paste0(DIR_OUTPUT_BOROUGH,
             "/", file,
             ".pdf"),
      width = IMAGE_WIDTH,
      height = IMAGE_HEIGHT,
      units = "in"
    )
    
    ggsave(
      paste0(DIR_OUTPUT_BOROUGH,
             "/", file,
             ".png"),
      width = IMAGE_WIDTH,
      height = IMAGE_HEIGHT,
      units = "in"
    )
  } else {
    ggsave(
      paste0(DIR_OUTPUT_MSOA,
             "/", file,
             ".pdf"),
      width = IMAGE_WIDTH,
      height = IMAGE_HEIGHT,
      units = "in"
    )
    
    ggsave(
      paste0(DIR_OUTPUT_MSOA,
             "/", file,
             ".png"),
      width = IMAGE_WIDTH,
      height = IMAGE_HEIGHT,
      units = "in"
    )
  }
}

if (BOROUGH_MODE & INTEGER_AGENT_MODE) {
  source("ViewZone.R", echo = T)
  
  pct <- zonePct
} else {
  source("Worldviews.R", echo = T)
}

if (BOROUGH_MODE) {
  pct$Zone <- zoneList$BoroughName
} else {
  pct$Zone <- 1:nrow(zoneList)
}

pct <-
  pct %>% select("Zone",
                 all_of(EGALITARIAN),
                 all_of(HIERARCHIST),
                 all_of(INDIVIDUALIST))

pct$Egalitarian <- pct$Egalitarian * 100
pct$Hierarchist <- pct$Hierarchist * 100
pct$Individualist <- pct$Individualist * 100

# Extract necessary zones. pct1: partial MSOAs.
if (BOROUGH_MODE == F) {
  w <- which(zoneList$BoroughID == MY_BOROUGH_ID)
  
  row_start <- w[1]
  
  row_end <- tail(w, n = 1)
  
  num <- row_end - row_start + 1
  
  pct1 <-
    subset(pct, pct$Zone %in% row_start:row_end)
  
  pct1$Zone <- 1:num
} else {
  pct1 <- pct
}

# View(pct1)

if (BOROUGH_MODE == F) {
  # Extract the borough name according to MY_BOROUGH_ID defined before.
  myBoroughName <-
    zoneList[which(zoneList$BoroughID == MY_BOROUGH_ID)[1], "BoroughName"] %>% pull()
}

worldviews <- c(EGALITARIAN, HIERARCHIST, INDIVIDUALIST)

# Plotting proportions of worldview groups for each zone.
for (wv in worldviews) {
  # Reorder zones (factors) according to zonal proportions of a worldview.
  if (wv == EGALITARIAN) {
    # newPct$Zone will become a factor.
    newPct <- transform(pct1, Zone = reorder(Zone, Egalitarian))
  } else if (wv == HIERARCHIST) {
    newPct <- transform(pct1, Zone = reorder(Zone, Hierarchist))
  } else if (wv == INDIVIDUALIST) {
    newPct <- transform(pct1, Zone = reorder(Zone, Individualist))
  } else {
    myStop("Invalid value of worldview.")
  }
  
  # View(newPct)
  
  # From wide to long.
  meltedPct <- gather(newPct,
                      key = "Worldview",
                      value = "Proportion",
                      Egalitarian:Individualist)
  # View(meltedPct)
  
  # meltedPct <- melt(newPct, id = "Zone")
  # colnames(meltedPct) <- c("Zone", "Worldview", "Proportion")
  
  if (BOROUGH_MODE) {
    TITLE <-
      paste0(
        "Worldview groups in London local authority districts\n(Ordered by % of ",
        tolower(wv),
        "s)"
      )
  } else {
    TITLE <- paste0(
      "Worldview groups in London Borough of ",
      myBoroughName,
      "\n(Ordered by % of ",
      tolower(wv),
      "s)"
    )
  }
  
  meltedPct$Worldview <- as.factor(meltedPct$Worldview)
  
  # meltedPct$Worldview %>% levels()
  
  gg <- ggplot(data = meltedPct,
               mapping = aes(x = Zone, y = Proportion, fill = Worldview)) +
    geom_bar(stat = "identity", position = "dodge") + coord_flip() +
    scale_y_continuous(breaks = seq(0, 60, 5)) +
    ylab("Proportion (%)") +
    ggtitle(TITLE) +
    scale_fill_manual(name = "Worldview\ngroup", values = c(GREEN, BLUE, RED)) +
    theme(panel.grid.minor.x = element_blank()) + theme_grey(base_size = BASE_SIZE)
  
  if (BOROUGH_MODE) {
    gg <- gg + xlab("Local authority district")
    
    saveRank(paste0("London_Borough_Ranking_", wv, "_", POPULATION_SCALE),
             isBorough = T)
  } else {
    gg <- gg + xlab("MSOA")
    
    saveRank(paste0("London_MSOA_Ranking_", wv, "_", POPULATION_SCALE),
             isBorough = F)
  }
}
# https://ithelp.ithome.com.tw/articles/10234577

# All zones: pct2.
pct2 <- bind_cols(pct, zoneList[, ZONE_ID])

# View(pct2)

pct2 <-
  pct2[, c("Zone",
           ZONE_ID,
           EGALITARIAN,
           HIERARCHIST,
           INDIVIDUALIST)]

str(pct2)

# pct2$Egalitarian <- pct2$Egalitarian * 100
# pct2$Hierarchist <- pct2$Hierarchist * 100
# pct2$Individualist <- pct2$Individualist * 100

culturalMap <- function(gis, worldview, isBorough) {
  if (worldview == EGALITARIAN) {
    pal <- "Greens"
  } else if (worldview == HIERARCHIST) {
    pal <- "Blues"
  } else if (worldview == INDIVIDUALIST) {
    pal <- "Reds"
  } else {
    myStop("Invalid value of worldview.")
  }
  
  tm <-
    tm_shape(gis) + tm_borders(lwd = 0.5, alpha = 0.5) +
    tm_fill(
      col = worldview,
      palette = pal,
      alpha = 0.7,
      n = NUMBER_BINS,
      title = "Proportion (%)"
    ) + tm_layout(title = paste0(worldview, "s in London"),
                  title.size = TITLE_SIZE)
  
  if (isBorough)
    tm <- tm + tm_text(text = "NAME", size = 0.6)
  
  return (tm)
}

# Plotting cultural maps.
if (BOROUGH_MODE) {
  # merge() needs a tibble or data frame here, not a matrix.
  gisCity1 <-
    merge(gisCity, pct2, by.x = "GSS_CODE", by.y = ZONE_ID)
  
  # Show all London boroughs.
  tm <-
    tm_shape(gisCity1) + tm_borders(lwd = 0.5, alpha = 0.5) + tm_text(text = "NAME", size = 0.6) + tm_layout(title = "London Boroughs", title.size = TITLE_SIZE)
  
  saveMap(tm, "London_Boroughs", T)
  
  for (wv in worldviews) {
    tm <- culturalMap(gisCity1, wv, T)
    
    saveMap(tm,
            paste0("London_Borough_", wv, "_", POPULATION_SCALE),
            T)
  }
} else {
  # Show all London MSOAs.
  
  # merge() needs a tibble or data frame here, not a matrix.
  gisCity1 <-
    merge(gisCity, pct2, by.x = "MSOA11CD", by.y = ZONE_ID)
  
  for (wv in worldviews) {
    tm <- culturalMap(gisCity1, wv, F)
    
    saveMap(tm,
            paste0("London_MSOA_", wv, "_", POPULATION_SCALE),
            F)
  }
}

if (BOROUGH_MODE == F) {
  # Only show MSOAs in the borough of interest.
  
  pct3 <- bind_cols(pct1, zoneList[row_start:row_end, ZONE_ID])
  
  # View(pct3)
  
  pct3$Egalitarian <- pct3$Egalitarian * 100
  pct3$Hierarchist <- pct3$Hierarchist * 100
  pct3$Individualist <- pct3$Individualist * 100
  
  pct3 <-
    pct3[, c("Zone",
             ZONE_ID,
             EGALITARIAN,
             HIERARCHIST,
             INDIVIDUALIST)]
  
  gisCity2 <- subset(gisCity, LAD11CD == MY_BOROUGH_ID)
  
  gisCity2 <-
    merge(gisCity2, pct3, by.x = "MSOA11CD", by.y = ZONE_ID)
  
  # Plotting the (simple) borough map.
  tm <-
    tm_shape(gisCity2) + tm_borders(lwd = 0.5, alpha = 0.5) + tm_text("Zone") + tm_layout(title = myBoroughName, title.size = TITLE_SIZE)
  
  saveMap(tm, myBoroughName, F)
  
  # Plot the borough's cultural maps by worldview group.
  for (wv in worldviews) {
    if (wv == EGALITARIAN) {
      pal <- "Greens"
    } else if (wv == HIERARCHIST) {
      pal <- "Blues"
    } else if (wv == INDIVIDUALIST) {
      pal <- "Reds"
    } else {
      myStop("Invalid value of worldview.")
    }
    
    tm <-
      tm_shape(gisCity2) + tm_borders(lwd = 0.5, alpha = 0.5) + tm_fill(
        col = wv,
        palette = pal,
        alpha = 0.7,
        n = NUMBER_BINS,
        title = "Proportion (%)"
      ) + tm_text("Zone") + tm_layout(title = paste0(wv, "s in ", myBoroughName),
                                      title.size = TITLE_SIZE)
    
    saveMap(tm, paste0(myBoroughName, "_", wv, "_", POPULATION_SCALE), F)
  }
}
