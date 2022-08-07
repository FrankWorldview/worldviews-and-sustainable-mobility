if (BOROUGH_MODE) {
  party <-
    read_excel("data/GLA_Elections_2016.xlsx", sheet = "Boroughs_MicroSim")
  
  if (DEBUG_MODE)
    View(party)
  
  party <- party[, -c(17:30)]
  
  party <- party[-nrow(party),] # Drop the last record: London.
  
  colnames(party) <-
    c(
      "BoroughName",
      "Geog",
      "Constituency",
      "BoroughID",
      "LAB",
      "CON",
      "GRE",
      "LD",
      "UKIP",
      "BNP",
      "RESP_SOC",
      "BF_BNP",
      "CAN_OTH",
      "ONE_OTH",
      "WOMAN_OTH",
      "IND_OTH"
    )
  
  party <- arrange(party, BoroughID)
} else {
  party <-
    read_excel("data/GLA_Elections_2016.xlsx", sheet = "Wards & Postals_MicroSim")
  
  if (DEBUG_MODE)
    View(party)
  
  party <- party[, -c(18:31)]
  
  # party <- party[-nrow(party),] # No need of this line.
  
  # City of London's ward ID needs to be changed.
  party[party$Ward == "City", "Area Code"] <-
    "E05009288"
  
  colnames(party) <-
    c(
      "BoroughName",
      "WardName",
      "Geog",
      "Constituency",
      "WardID",
      "LAB",
      "CON",
      "GRE",
      "LD",
      "UKIP",
      "BNP",
      "RESP_SOC",
      "BF_BNP",
      "CAN_OTH",
      "ONE_OTH",
      "WOMAN_OTH",
      "IND_OTH"
    )
}

party$BNP <- party$BNP + party$BF_BNP

party$OTH <-
  party$CAN_OTH + party$ONE_OTH + party$WOMAN_OTH + party$IND_OTH

colnames(party)[colnames(party) == "RESP_SOC"] <- "SOC"

if (BOROUGH_MODE) {
  party <-
    party %>% select("BoroughID",
                     "BoroughName",
                     "CON",
                     "LAB",
                     "LD",
                     "GRE",
                     "UKIP",
                     "BNP",
                     "SOC",
                     "OTH")
} else {
  party <-
    party %>% select(
      "WardID",
      "WardName",
      "BoroughName",
      "Geog",
      "CON",
      "LAB",
      "LD",
      "GRE",
      "UKIP",
      "BNP",
      "SOC",
      "OTH"
    ) %>% filter(Geog == "Ward")
}

party$Total <-
  party$CON + party$LAB + party$LD + party$GRE + party$UKIP + party$BNP + party$SOC + party$OTH

party[, c("CON", "LAB", "LD", "GRE", "UKIP", "BNP", "SOC", "OTH")] <-
  party[, c("CON", "LAB", "LD", "GRE", "UKIP", "BNP", "SOC", "OTH")] / party$Total

# should all be 1.
table(rowSums(party[, c("CON", "LAB", "LD", "GRE", "UKIP", "BNP", "SOC", "OTH")]))

if (BOROUGH_MODE == F) {
  MSOA2Ward <- read_csv("data/MSOA2011-Ward2016.csv")
  
  if (DEBUG_MODE)
    View(MSOA2Ward)
  
  partyMSOA <- zoneList %>% select(all_of(ZONE_ID))
  
  if (DEBUG_MODE)
    View(partyMSOA)
  
  # Ward E05000042 (Whalebone) is missing in partyMSOA because there is no fit record.
  partyMSOA$WardID <-
    MSOA2Ward$WD16CD[match(partyMSOA$MSOAID, MSOA2Ward$MSOA11CD)]
  
  partyMSOA$WardName <-
    MSOA2Ward$WD16NM[match(partyMSOA$MSOAID, MSOA2Ward$MSOA11CD)]
  
  partyMSOA$BoroughID <-
    MSOA2Ward$LAD16CD[match(partyMSOA$MSOAID, MSOA2Ward$MSOA11CD)]
  
  partyMSOA$BoroughName <-
    MSOA2Ward$LAD16NM[match(partyMSOA$MSOAID, MSOA2Ward$MSOA11CD)]
  
  partyMSOA$CON <-
    party$CON[match(partyMSOA$WardID, party$WardID)]
  
  partyMSOA$LAB <-
    party$LAB[match(partyMSOA$WardID, party$WardID)]
  
  partyMSOA$LD <-
    party$LD[match(partyMSOA$WardID, party$WardID)]
  
  partyMSOA$GRE <-
    party$GRE[match(partyMSOA$WardID, party$WardID)]
  
  partyMSOA$UKIP <-
    party$UKIP[match(partyMSOA$WardID, party$WardID)]
  
  partyMSOA$BNP <-
    party$BNP[match(partyMSOA$WardID, party$WardID)]
  
  partyMSOA$SOC <-
    party$SOC[match(partyMSOA$WardID, party$WardID)]
  
  partyMSOA$OTH <-
    party$OTH[match(partyMSOA$WardID, party$WardID)]
  
  # Optional: Check if partyMSOA is sorted correctly.
  # partyMSOA1 <- arrange(partyMSOA, BoroughID, MSOAID)
  # identical(partyMSOA, partyMSOA1)
  # all.equal(partyMSOA, partyMSOA1)
  
  # should all be 1.
  table(rowSums(partyMSOA[, c("CON", "LAB", "LD", "GRE", "UKIP", "BNP", "SOC", "OTH")]))
  
  cons4 <-
    zoneList$Pop * partyMSOA[, c("CON", "LAB", "LD", "GRE", "UKIP", "BNP", "SOC", "OTH")]
} else {
  cons4 <-
    zoneList$Pop * party[, c("CON", "LAB", "LD", "GRE", "UKIP", "BNP", "SOC", "OTH")]
}

if (DEBUG_MODE == T)
  View(cons4)
