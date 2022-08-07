source("Config.R", echo = T)

if (BATCH_MODE) {
  IS_WRITE_BOROUGH_CAR <- F
} else {
  IS_WRITE_BOROUGH_CAR <- T
}

flowMSOA_UK <- read_csv("data/wu03ew_v2.csv")

# This dataset does not include the MSOA pairs with total flow == 0.
if (DEBUG_MODE)
  View(flowMSOA_UK)

flowMSOA_UK <- flowMSOA_UK[, c(1:2, 5:13)]

colnames(flowMSOA_UK) <-
  c(
    "MSOAID_O",
    "MSOAID_D",
    "Rail1",
    "Rail2",
    "Bus",
    "Car1",
    "Car2",
    "Car3",
    "Car4",
    "Bike",
    "Foot"
  )

# zoneLookup$MSOAID is a vector, while zoneLookup[, "MSOAID"] is a tibble.
flowMSOA <-
  flowMSOA_UK %>% filter(MSOAID_O %in% zoneLookup$MSOAID) %>%
  filter(MSOAID_D %in% zoneLookup$MSOAID)

# flowMSOA <-
#   subset(flowMSOA_UK,
#          flowMSOA_UK$MSOAID_O %in% zoneLookup$MSOAID)

remove(flowMSOA_UK)

if (DEBUG_MODE)
  View(flowMSOA)

# flowMSOA <-
#   subset(flowMSOA,
#          flowMSOA$MSOAID_D %in% zoneLookup$MSOAID)

flowMSOA$BoroughID_O <-
  zoneLookup$BoroughID[match(flowMSOA$MSOAID_O, zoneLookup$MSOAID)]

flowMSOA$BoroughID_D <-
  zoneLookup$BoroughID[match(flowMSOA$MSOAID_D, zoneLookup$MSOAID)]

flowMSOA$Car <-
  flowMSOA$Car1 + flowMSOA$Car2 + flowMSOA$Car3 + flowMSOA$Car4

flowMSOA$Rail <- flowMSOA$Rail1 + flowMSOA$Rail2

flowMSOA$NonCar <-
  flowMSOA$Bus + flowMSOA$Rail + flowMSOA$Bike + flowMSOA$Foot

flowMSOA$Total <- flowMSOA$Car + flowMSOA$NonCar

flowMSOA <-
  arrange(flowMSOA, BoroughID_O, BoroughID_D, MSOAID_O, MSOAID_D)

sum(flowMSOA$Car)
sum(flowMSOA$Bus)
sum(flowMSOA$Rail)
sum(flowMSOA$NonCar)
sum(flowMSOA$Total)

# summary(flowMSOA$Car + flowMSOA$NonCar == flowMSOA$Total)

if (!identical(flowMSOA$Car + flowMSOA$NonCar, flowMSOA$Total))
  myStop("Flow sums are incorrect.")

# View the fractions of each mode by borough pairs.
allFlowBoroughPair <-
  aggregate(flowMSOA[, c("Car", "Bus", "Rail", "Bike", "Foot", "Total")],
            by = list(flowMSOA$BoroughID_O, flowMSOA$BoroughID_D),
            sum)

# View(allFlowBoroughPair)

colnames(allFlowBoroughPair)[1] <- "BoroughID_O"
colnames(allFlowBoroughPair)[2] <- "BoroughID_D"

allFlowBoroughPair <-
  arrange(allFlowBoroughPair, BoroughID_O, BoroughID_D)

if (BOROUGH_MODE) {
  ##########
  # Origin #
  ##########
  
  boroughCar_O <-
    aggregate(flowMSOA[, c("Car", "Total")], by = list(flowMSOA$BoroughID_O), sum)
  
  # View(boroughCar_O)
  
  colnames(boroughCar_O) <- c("BoroughID_O", "Car", "Total")
  
  boroughCar_O <-
    arrange(boroughCar_O, BoroughID_O)
  
  boroughCar_O$P_Car <- boroughCar_O$Car / boroughCar_O$Total
  
  # Only for the borough mode.
  boroughCar_O$BoroughName <- zoneList$BoroughName
  
  if (IS_WRITE_BOROUGH_CAR)
    write_csv(boroughCar_O, "BoroughCar_Orig.csv")
  
  P_Car_O <- sum(boroughCar_O$Car) / sum(boroughCar_O$Total)
  
  P_Car_O
  
  ###############
  # Destination #
  ###############
  
  boroughCar_D <-
    aggregate(flowMSOA[, c("Car", "Total")], by = list(flowMSOA$BoroughID_D), sum)
  
  # View(boroughCar_D)
  
  colnames(boroughCar_D) <- c("BoroughID_D", "Car", "Total")
  
  boroughCar_D <-
    arrange(boroughCar_D, BoroughID_D)
  
  boroughCar_D$P_Car <- boroughCar_D$Car / boroughCar_D$Total
  
  # Only for the borough mode.
  boroughCar_D$BoroughName <- zoneList$BoroughName
  
  if (IS_WRITE_BOROUGH_CAR)
    write_csv(boroughCar_D, "BoroughCar_Dest.csv")
  
  P_Car_D <- sum(boroughCar_D$Car) / sum(boroughCar_D$Total)
  
  P_Car_D
  
  if (P_Car_O != P_Car_D)
    myStop("P_Car_O and P_Car_D are not equal.")
}
