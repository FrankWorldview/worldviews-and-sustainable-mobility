edu <-
  read_csv("data/msoa-data.csv", locale = locale(encoding = "ISO-8859-1"))

if (DEBUG_MODE)
  View(edu)

edu <-
  edu %>% select(
    "Middle Super Output Area",
    "Qualifications (2011 Census);No qualifications;",
    "Qualifications (2011 Census);Highest level of qualification: Level 1 qualifications;",
    "Qualifications (2011 Census);Highest level of qualification: Level 2 qualifications;",
    "Qualifications (2011 Census);Highest level of qualification: Apprenticeship;",
    "Qualifications (2011 Census);Highest level of qualification: Level 3 qualifications;",
    "Qualifications (2011 Census);Highest level of qualification: Level 4 qualifications and above;",
    "Qualifications (2011 Census);Highest level of qualification: Other qualifications;"
  )

edu <- edu %>% slice(-nrow(edu)) # The last row.

colnames(edu) <- c("MSOAID",
                   "NoQual",
                   "NVQ1",
                   "NVQ2",
                   "Apprenticeship",
                   "NVQ3",
                   "NVQ4Up",
                   "OtherQual")

edu$BoroughID <-
  zoneLookup$BoroughID[match(edu$MSOAID, zoneLookup$MSOAID)]

edu <- arrange(edu, BoroughID, MSOAID)

if (BOROUGH_MODE) {
  edu <-
    aggregate(edu[, 2:8], by = list(edu$BoroughID), sum)
  
  colnames(edu)[1] <- ZONE_ID
  
  edu <- arrange(edu, BoroughID)
}

edu$OtherQual <- edu$OtherQual + edu$Apprenticeship

edu$OLevel <- edu$NVQ1 + edu$NVQ2

edu <-
  edu %>% select(all_of(ZONE_ID),
                 ## ZONE_ID, # Error.
                 "NoQual",
                 "OtherQual",
                 "OLevel",
                 "NVQ3",
                 "NVQ4Up")

colnames(edu) <-
  c(ZONE_ID,
    "NoQual",
    "OtherQual",
    "OLevel",
    "ALevel",
    "Degree")

edu$Total <-
  edu$NoQual + edu$OtherQual + edu$OLevel + edu$ALevel + edu$Degree

edu[, c("NoQual", "OtherQual", "OLevel", "ALevel", "Degree")] <-
  edu[, c("NoQual", "OtherQual", "OLevel", "ALevel", "Degree")] / edu$Total

# should all be 1.
table(rowSums(edu[, c("NoQual", "OtherQual", "OLevel", "ALevel", "Degree")]))

cons3 <-
  zoneList$Pop * edu[, c("NoQual", "OtherQual", "OLevel", "ALevel", "Degree")]

if (DEBUG_MODE)
  View(cons3)
