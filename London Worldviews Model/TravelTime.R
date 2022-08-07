source("Config.R", echo = T)

source("TravelFlow.R", echo = T)

if (DEBUG_MODE)
  View(flowMSOA)

travelTime <-
  read_csv("data/QUANT_London.csv")

if (DEBUG_MODE)
  View(travelTime)

# Swap origins and destinations because QUANT models the trips from workplaces to residences.
travelTime <-
  travelTime %>% select("destination_j",
                        "origin_i",
                        "dij_road_secs",
                        "dij_bus_secs",
                        "dij_rail_secs")

colnames(travelTime) <-
  c("MSOAID_O",
    "MSOAID_D",
    "Car_Sec",
    "Bus_Sec",
    "Rail_Sec")

travelTime$BoroughID_O <-
  zoneLookup$BoroughID[match(travelTime$MSOAID_O, zoneLookup$MSOAID)]

travelTime <-
  travelTime %>% filter(!is.na(travelTime$BoroughID_O))

travelTime$BoroughID_D <-
  zoneLookup$BoroughID[match(travelTime$MSOAID_D, zoneLookup$MSOAID)]

travelTime <-
  travelTime %>% filter(!is.na(travelTime$BoroughID_D))

travelTime <- unique(travelTime)

travelTime <-
  arrange(travelTime, BoroughID_O, BoroughID_D, MSOAID_O, MSOAID_D)

if (TWO_WAYS_MODE == F) {
  # write_csv(travelTime, "TravelTime_OneWay.csv")
} else {
  # travelTime1: from residence to workplace.
  travelTime1 <- travelTime
  
  # write_csv(travelTime1, "TravelTime1.csv")
  
  # travelTime2: from workplace to residence.
  travelTime2 <- travelTime1[, c(
    "MSOAID_D",
    "MSOAID_O",
    "Car_Sec",
    "Bus_Sec",
    "Rail_Sec",
    "BoroughID_D",
    "BoroughID_O"
  )]
  
  colnames(travelTime2) <-
    c(
      "MSOAID_O",
      "MSOAID_D",
      "Car_Sec",
      "Bus_Sec",
      "Rail_Sec",
      "BoroughID_O",
      "BoroughID_D"
    )
  
  travelTime2 <-
    arrange(travelTime2, BoroughID_O, BoroughID_D, MSOAID_O, MSOAID_D)
  
  # write_csv(travelTime2, "TravelTime2.csv")
  
  # Check if travel times are sorted in the same way.
  # summary(travelTime1[, c(1, 2)] == travelTime2[, c(1, 2)])
  # summary(travelTime1[, c(1, 2)] == travelTime[, c(1, 2)])
  
  if (!identical(travelTime1[, c(1, 2)], travelTime2[, c(1, 2)]) |
      !identical(travelTime1[, c(1, 2)], travelTime[, c(1, 2)]))
    myStop("MSOA IDs are inconsistent.")
  
  travelTime$Car_Sec <-
    (travelTime1$Car_Sec + travelTime2$Car_Sec) / 2
  
  travelTime$Bus_Sec <-
    (travelTime1$Bus_Sec + travelTime2$Bus_Sec) / 2
  
  travelTime$Rail_Sec <-
    (travelTime1$Rail_Sec + travelTime2$Rail_Sec) / 2
  
  summary(travelTime1$Car_Sec - travelTime2$Car_Sec)
  
  summary(travelTime1$Bus_Sec - travelTime2$Bus_Sec)
  
  summary(travelTime1$Rail_Sec - travelTime2$Rail_Sec)
  
  # write_csv(travelTime, "TravelTime.csv")
}

flowMSOA <-
  flowMSOA[, c("MSOAID_O",
               "MSOAID_D",
               "Car",
               "NonCar",
               "Total",
               "Bus",
               "Rail",
               "Bike",
               "Foot")]

# Either full or left join is fine.
travelTimeFlow <-
  full_join(travelTime, flowMSOA, by = c("MSOAID_O", "MSOAID_D"))

if (DEBUG_MODE)
  View(travelTimeFlow)

travelTimeFlow <-
  arrange(travelTimeFlow, BoroughID_O, BoroughID_D, MSOAID_O, MSOAID_D)

travelTimeFlow[is.na(travelTimeFlow)] <- 0

sum(travelTimeFlow$Car)

sum(travelTimeFlow$NonCar)

sum(travelTimeFlow$Bus)

sum(travelTimeFlow$Rail)

summary(travelTimeFlow$Car + travelTimeFlow$NonCar == travelTimeFlow$Total)

summary(
  travelTimeFlow$Car + travelTimeFlow$Bus + travelTimeFlow$Rail + travelTimeFlow$Bike + travelTimeFlow$Foot == travelTimeFlow$Total
)

if (!identical(travelTimeFlow$Car + travelTimeFlow$NonCar,
               travelTimeFlow$Total))
  myStop("Travel time sums (car and non-car) are inconsistent.")

if (!identical(
  travelTimeFlow$Car + travelTimeFlow$Bus + travelTimeFlow$Rail + travelTimeFlow$Bike + travelTimeFlow$Foot,
  travelTimeFlow$Total
))
  myStop("Travel time sums are inconsistent.")

if (sum(
  travelTimeFlow$Car + travelTimeFlow$Bus + travelTimeFlow$Rail + travelTimeFlow$Bike + travelTimeFlow$Foot
) != sum(flowMSOA$Total))
  myStop("Travel time sums are inconsistent (compared with flowMSOA).")

if (TWO_WAYS_MODE == F) {
  write_csv(travelTimeFlow, "TravelTimeFlow_OneWay.csv")
} else {
  write_csv(travelTimeFlow, "TravelTimeFlow.csv")
}
