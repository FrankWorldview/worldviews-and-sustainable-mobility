income <-
  read_excel("data/Income_2016.xlsx", sheet = "Household income LSOA_MicroSim")

if (DEBUG_MODE)
  View(income)

colnames(income) <-
  c(
    "ZoneID",
    "ZoneName",
    "LSOAName",
    "X0",
    "X0_5000",
    "X5000_10000",
    "X10000_15000",
    "X15000_20000",
    "X20000_30000",
    "X30000_40000",
    "X40000_60000",
    "X60000_Up",
    "NoInfo"
  )

if (BOROUGH_MODE) {
  # zoneIncome <- subset(income, is.element(income$ZoneID, zoneList[, ZONE_ID])) # Problematic: is.element(vector, tibble).
  
  zoneIncome <-
    subset(income, income$ZoneID %in% pull(zoneList, ZONE_ID))
  
  if (DEBUG_MODE)
    View(zoneIncome)
  
  zoneIncome <- arrange(zoneIncome, ZoneID)
} else {
  LSOA2MSOA <- read_csv("data/OA-LSOA-MSOA-LA_2011.csv")
  
  if (DEBUG_MODE)
    View(LSOA2MSOA)
  
  # Only London LSOAs.
  income$MSOAID <-
    LSOA2MSOA$MSOA11CD[match(income$ZoneID, LSOA2MSOA$LSOA11CD)]
  
  income <-
    subset(income, income$MSOAID %in% pull(zoneLookup, ZONE_ID))
  
  # Calculate MSOA incomes by averaging LSOA incomes. Using mean() instead of sum() because the dataset is about percentages.
  zoneIncome <-
    aggregate(income[, 4:13],
              by = list(income$MSOAID),
              mean)
  
  if (DEBUG_MODE)
    View(zoneIncome)
  
  colnames(zoneIncome)[1] <- "MSOAID"
  
  zoneIncome$BoroughID <-
    zoneLookup$BoroughID[match(zoneIncome$MSOAID, zoneLookup$MSOAID)]
  
  zoneIncome <- arrange(zoneIncome, BoroughID, MSOAID)
}

zoneIncome$X0_5000 <- zoneIncome$X0 + zoneIncome$X0_5000

zoneIncome$Total <-
  zoneIncome$X0_5000 + zoneIncome$X5000_10000 + zoneIncome$X10000_15000 + zoneIncome$X15000_20000 + zoneIncome$X20000_30000 + zoneIncome$X30000_40000 + zoneIncome$X40000_60000 + zoneIncome$X60000_Up

zoneIncome[, c(
  "X0_5000",
  "X5000_10000",
  "X10000_15000",
  "X15000_20000",
  "X20000_30000",
  "X30000_40000",
  "X40000_60000",
  "X60000_Up"
)] <-
  zoneIncome[, c(
    "X0_5000",
    "X5000_10000",
    "X10000_15000",
    "X15000_20000",
    "X20000_30000",
    "X30000_40000",
    "X40000_60000",
    "X60000_Up"
  )] / zoneIncome$Total

# should all be 1.
table(rowSums(zoneIncome[, c(
  "X0_5000",
  "X5000_10000",
  "X10000_15000",
  "X15000_20000",
  "X20000_30000",
  "X30000_40000",
  "X40000_60000",
  "X60000_Up"
)]))

cons2 <-
  zoneList$Pop * select(zoneIncome, X0_5000:X60000_Up)

if (DEBUG_MODE)
  View(cons2)
