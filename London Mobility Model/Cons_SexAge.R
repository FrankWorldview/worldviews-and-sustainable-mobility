getPopulation <- function(sex, zoneLookup) {
  if (sex == "male") {
    pop <-
      read_excel("data/SexAge_2016.xlsx", sheet = "Mid-2016 Males_MicroSim")
  } else {
    pop <-
      read_excel("data/SexAge_2016.xlsx", sheet = "Mid-2016 Females_MicroSim")
  }
  
  if (DEBUG_MODE)
    View(pop)
  
  colnames(pop)[colnames(pop) == "Area Codes"] <- "MSOAID"
  
  colnames(pop)[colnames(pop) == "Area Names"] <- "MSOAName"
  
  colnames(pop)[colnames(pop) == "All Ages"] <- "TotalPeople"
  
  pop <- subset(pop, is.element(MSOAID, zoneLookup$MSOAID))
  
  pop$BoroughID <-
    zoneLookup$BoroughID[match(pop$MSOAID, zoneLookup$MSOAID)]
  
  pop$BoroughName <-
    zoneLookup$BoroughName[match(pop$MSOAID, zoneLookup$MSOAID)]
  
  pop <- arrange(pop, BoroughID, MSOAID) # Sort.
  
  pop$P_00_17 <- rowSums(pop[, 4:21])
  
  pop$P_18_24 <- rowSums(pop[, 22:28])
  
  pop$P_25_34 <- rowSums(pop[, 29:38])
  
  pop$P_35_44 <- rowSums(pop[, 39:48])
  
  pop$P_45_54 <- rowSums(pop[, 49:58])
  
  pop$P_55_59 <- rowSums(pop[, 59:63])
  
  pop$P_60_64 <- rowSums(pop[, 64:68])
  
  pop$P_65_Up <- rowSums(pop[, 69:94])
  
  # Check integrity.
  if (!identical(
    pop$TotalPeople,
    pop$P_00_17 + pop$P_18_24 + pop$P_25_34 + pop$P_35_44 + pop$P_45_54 + pop$P_55_59 + pop$P_60_64 + pop$P_65_Up
  ))
    myStop("The total number of people is incorrect.")
  
  pop <-
    pop %>% select(
      "MSOAID",
      "MSOAName",
      "BoroughID",
      "BoroughName",
      "P_18_24",
      "P_25_34",
      "P_35_44",
      "P_45_54",
      "P_55_59",
      "P_60_64",
      "P_65_Up"
    )
  
  return(pop)
}

popMale <- getPopulation("male", zoneLookup)

if (DEBUG_MODE)
  View(popMale)

colnames(popMale) <-
  c(
    "MSOAID",
    "MSOAName",
    "BoroughID",
    "BoroughName",
    "M_18_24",
    "M_25_34",
    "M_35_44",
    "M_45_54",
    "M_55_59",
    "M_60_64",
    "M_65_Up"
  )

popFemale <- getPopulation("female", zoneLookup)

if (DEBUG_MODE)
  View(popFemale)

colnames(popFemale) <-
  c(
    "MSOAID",
    "MSOAName",
    "BoroughID",
    "BoroughName",
    "F_18_24",
    "F_25_34",
    "F_35_44",
    "F_45_54",
    "F_55_59",
    "F_60_64",
    "F_65_Up"
  )

# Check the sorting order.
# identical(popMale[, 1:4], popFemale[, 1:4])
# identical(popMale[, 1:4], zoneLookup[, 1:4])
# identical(popFemale[, 1:4], zoneLookup[, 1:4])
#
# all.equal(popMale[, 1:4], popFemale[, 1:4])
# all.equal(popMale[, 1:4], zoneLookup[, 1:4])
# all.equal(popFemale[, 1:4], zoneLookup[, 1:4])

# cons1 <- bind_cols(popMale, popFemale[, -1:-4])

cons1 <- inner_join(popMale, popFemale)

if (DEBUG_MODE)
  View(cons1)

cons1 <-
  arrange(cons1, BoroughID, MSOAID) # Make sure the result is ordered.

# Check the order.
if (!identical(cons1[, 1:4], zoneLookup[, 1:4]))
  myStop("The order of cons1 is incorrect.")

# all.equal(cons1[, 1:4], zoneLookup[, 1:4])

# cons1[, which(colnames(cons1) == "M_18_24"):which(colnames(cons1) == "F_65_Up")]

cons1[, 5:18] <- (cons1[, 5:18] * POPULATION_SCALE) %>% round(0)

cons1$Pop <-
  rowSums(cons1[, 5:18])

zoneLookup$Pop <- cons1$Pop

if (BOROUGH_MODE) {
  zoneList <-
    zoneLookup[, c("BoroughID", "BoroughName")] %>% unique()
  
  zoneList <-
    arrange(zoneList, BoroughID) # Make sure the result is ordered.
  
  cons1 <-
    aggregate(cons1[, 5:18], by = list(cons1$BoroughID), sum) # Data frame.
  
  colnames(cons1)[1] <- ZONE_ID
  
  cons1 <-
    arrange(cons1, ZONE_ID) # Make sure the result is ordered.
  
  # Calculate population for zones.
  cons1$Pop <- rowSums(cons1[, -1])
  
  # zoneList <- bind_cols(zoneList, zonePop)
  zoneList <-
    inner_join(zoneList, cons1[, c(ZONE_ID, "Pop")]) # Tibble.
  
  zoneList <-
    arrange(zoneList, BoroughID) # Make sure the result is ordered.
} else {
  zoneList <- zoneLookup # Tibble.
}

if (DEBUG_MODE)
  View(zoneList)

# Check the number of people.
if (sum(zoneList$Pop) != sum(zoneLookup$Pop))
  myStop("The total number of people by zones is incorrect.")

cons1 <-
  cons1 %>% select(M_18_24:F_65_Up) %>% as.data.frame() # For the MSOA mode: Because cons2/cons3/con4 are data frames.
