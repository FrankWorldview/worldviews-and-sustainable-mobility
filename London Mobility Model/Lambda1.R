source("Config.R", echo = T)

if (TWO_WAYS_MODE == F) {
  travelTimeFlow <- read_csv("TravelTimeFlow_OneWay.csv", lazy = F)
} else {
  travelTimeFlow <- read_csv("TravelTimeFlow.csv", lazy = F)
}

# View(travelTimeFlow)

# Exclude the entries of travel flows == 0.
tfc <-
  travelTimeFlow %>% filter(Total > 0) # Travel times and flows (by MSOAs).

# View(tfc)

MSOADistance <- read_csv("MSOADistance.csv", lazy = F)

# View(MSOADistance)

tfc <-
  inner_join(tfc,
             MSOADistance,
             by = c("MSOAID_O" = "MSOAID_O", "MSOAID_D" = "MSOAID_D"))

tfc <- arrange(tfc, BoroughID_O, BoroughID_D, MSOAID_O, MSOAID_D)

CONGESTION_CHARGE <- 11.5

CONGESTION_CHARGE_RESIDENT <- 11.5 / 10

isCongestionChargeZone <- function(MSOA) {
  ccz <- c(
    "E02000001",
    "E02000189",
    "E02000190",
    "E02000191",
    "E02000192",
    "E02000193",
    "E02000371",
    "E02000574",
    "E02000575",
    "E02000576",
    "E02000619",
    "E02000620",
    "E02000808",
    "E02000809",
    "E02000812",
    "E02000815",
    "E02000878",
    "E02000890",
    "E02000967",
    "E02000970",
    "E02000971",
    "E02000972",
    "E02000977",
    "E02000978",
    "E02000979",
    "E02000980",
    "E02006801",
    "E02006802"
  )
  
  return (ifelse (is.element(MSOA, ccz), T, F))
}

# PS: In the future, there may be no discount for residents.
tfc$CongestionCharge <- ifelse(
  (
    # Use & instead of &&.
    isCongestionChargeZone(tfc$MSOAID_O) &
      (!isCongestionChargeZone(tfc$MSOAID_D))
  ),
  
  CONGESTION_CHARGE_RESIDENT,
  
  ifelse(
    (
      !isCongestionChargeZone(tfc$MSOAID_O) &
        isCongestionChargeZone(tfc$MSOAID_D)
    ),
    CONGESTION_CHARGE,
    0
  )
)

# V = km / hour.
tfc$V <-
  ifelse(tfc$MSOAID_O == tfc$MSOAID_D,
         0,
         (tfc$Distance / 1000) / (tfc$Car_Sec / 3600))

# DfT TAG data book A1.3.13: 2015 year (rounded at the 10th digit).
PETROL_A <- 46.5445617051

PETROL_B <-  9.8914743574

PETROL_C <- -0.1126756231

PETROL_D <-  0.0007462416

DIESEL_A <- 51.1465198535

DIESEL_B <-  7.3331460950

DIESEL_C <- -0.0705469083

DIESEL_D <-  0.0005559132

tfc$Fuel_Petrol_Pence_per_Km <-
  ifelse(tfc$V == 0,
         0,
         (PETROL_A / tfc$V) + PETROL_B + (PETROL_C * tfc$V) + (PETROL_D * tfc$V * tfc$V))

tfc$Fuel_Diesel_Pence_per_Km <-
  ifelse(tfc$V == 0,
         0,
         (DIESEL_A / tfc$V) + DIESEL_B + (DIESEL_C * tfc$V) + (DIESEL_D * tfc$V * tfc$V))

tfc$FuelCost <-
  ifelse(
    tfc$V == 0,
    0,
    (tfc$Fuel_Petrol_Pence_per_Km + tfc$Fuel_Diesel_Pence_per_Km) * (tfc$Distance / 1000) / (2 * 100) # Pence to pound.
  )

parking <-
  read_csv("data/ParkingCharge.csv")

# View(parking)

if (!identical(parking$BoroughID, zoneList$BoroughID) |
    !identical(parking$BoroughName, zoneList$BoroughName))
  myStop("Parking data's borough IDs or names are incorrect.")

parking$ParkingCharge <-
  parking$ParkingChargeMonthly / (52 / 12 * 5) # 52 weeks / 12 months * 5 days = working days per month.

tfc$BoroughPair <- paste0(tfc$BoroughID_O, tfc$BoroughID_D)

if (WEIGHTED_TIME_MODE == T) {
  # Average, weighted travel times. (Not yet verified.)
  wt_Car <-
    sapply(split(tfc, tfc$BoroughPair), function(x)
      weighted.mean(x$Car_Sec, w = x$Total))
  
  wt_Bus <-
    sapply(split(tfc, tfc$BoroughPair), function(x)
      weighted.mean(x$Bus_Sec, w = x$Total))
  
  wt_Rail <-
    sapply(split(tfc, tfc$BoroughPair), function(x)
      weighted.mean(x$Rail_Sec, w = x$Total))
  
  avgTravelTime <- bind_cols(wt_Car, wt_Bus, wt_Rail)
  
  avgTravelTime$BoroughPair <-
    tfc$BoroughPair %>% unique() %>% as_tibble() %>% arrange(value) %>% pull()
  
  colnames(avgTravelTime)[1] <- "Car_Sec"
  colnames(avgTravelTime)[2] <- "Bus_Sec"
  colnames(avgTravelTime)[3] <- "Rail_Sec"
  
  avgTravelTime <-
    avgTravelTime[, c("BoroughPair", "Car_Sec", "Bus_Sec", "Rail_Sec")]
} else {
  # Average, non-weighted travel times.
  avgTravelTime <-
    aggregate(tfc[, c("Car_Sec", "Bus_Sec", "Rail_Sec", "Distance")], by = list(tfc$BoroughPair), mean)
  
  colnames(avgTravelTime)[1] <- "BoroughPair"
}

# View(avgTravelTime)

# Should be false.
is.unsorted(avgTravelTime$BoroughPair)

avgTravelTime$Time_Car <- avgTravelTime$Car_Sec / 60
avgTravelTime$Time_Bus <- avgTravelTime$Bus_Sec / 60
avgTravelTime$Time_Rail <- avgTravelTime$Rail_Sec / 60

avgTravelTime <-
  avgTravelTime[, c("BoroughPair", "Time_Car", "Time_Bus", "Time_Rail", "Distance")] # WEIGHTED_TIME_MODE has no "distance."

tfc$Money_Car_WO_Parking <- tfc$FuelCost + tfc$CongestionCharge

tfc$ParkingCharge_O <-
  parking$ParkingCharge[match(tfc$BoroughID_O, parking$BoroughID)]

tfc$ParkingCharge_D <-
  parking$ParkingCharge[match(tfc$BoroughID_D, parking$BoroughID)]

tfc$ParkingCharge <- tfc$ParkingCharge_O + tfc$ParkingCharge_D

tfc$Money_Car <- tfc$Money_Car_WO_Parking + tfc$ParkingCharge

avgTravelMoney <-
  aggregate(tfc[, c(
    "Money_Car",
    "Money_Car_WO_Parking",
    "FuelCost",
    "CongestionCharge",
    "ParkingCharge",
    "ParkingCharge_O",
    "ParkingCharge_D"
  )], by = list(tfc$BoroughPair), mean)

colnames(avgTravelMoney)[1] <- "BoroughPair"

# View(avgTravelMoney)

# Should be false.
is.unsorted(avgTravelMoney$BoroughPair)

# It is actually unnecessary to include bike and foot here, since only car and non-car (bus, rail, bike, and foot) will be considered.
aggFlow <-
  aggregate(tfc[, c("Car",
                    "NonCar",
                    "Total",
                    "Bus", "Rail", "Bike", "Foot")], by = list(tfc$BoroughPair), sum)

colnames(aggFlow)[1] <- "BoroughPair"

# View(aggFlow)

# Should be false.
is.unsorted(aggFlow$BoroughPair)

aggTravelFlowCost <-
  aggFlow %>% inner_join(avgTravelTime) %>% inner_join(avgTravelMoney)

# View(aggTravelFlowCost)

aggTravelFlowCost <- arrange(aggTravelFlowCost, BoroughPair)

atfc <-
  aggTravelFlowCost # Aggregate travel flows, times, and money (by borough pairs).

# View(atfc)

atfc$BoroughID_O <- substring(atfc$BoroughPair, 1, 9)

atfc$BoroughID_D <- substring(atfc$BoroughPair, 10, 18)

# Should be true.
if (!identical(atfc, arrange(atfc, BoroughID_O, BoroughID_D)))
  myStop("atfc is not sorted correctly.")

if (FARE_MODE) {
  boroughFare <-
    read_csv("BoroughFare.csv") %>% as.data.frame() # Cannot be tibble here, because row names will be used.
  
  rownames(boroughFare) <- boroughFare$BoroughID
  
  # View(boroughFare)
  
  for (i in 1:nrow(atfc))
    atfc[i, "Money_Rail"] <-
    boroughFare[atfc[i, "BoroughID_O"], atfc[i, "BoroughID_D"]]
}

# aftc is for borough-borough, while tfc is for MSOA-MSOA.
atfc$P_Car <- atfc$Car / atfc$Total

atfc$P_Public <- 1 - atfc$P_Car

tfc$P_Car <- tfc$Car / tfc$Total

tfc$P_Public <- 1 - tfc$P_Car

# atfc$P_Bus <-
#   atfc$Bus / (atfc$Bus + atfc$Rail)
#
# atfc$P_Rail <-
#   atfc$Rail / (atfc$Bus + atfc$Rail)

atfc$Log_PCar <- log(atfc$P_Car / atfc$P_Public)

tfc$Log_PCar <- log(tfc$P_Car / tfc$P_Public)

MONEY_TO_TIME <- 60 / 9.95

if (FARE_MODE) {
  BUS_FARE <- 1.5
  
  tfc$Money_Bus <- BUS_FARE
}

tfc$Time_Car <- tfc$Car_Sec / 60

tfc$Time_Bus <- tfc$Bus_Sec / 60

tfc$Time_Rail <- tfc$Rail_Sec / 60

# if (FARE_MODE) {
#   for (i in 1:nrow(tfc))  {
#     if (i %% 10000 == 0)
#       print(i)
#
#     tfc[i, "Money_Rail"] <-
#       fareBorough[tfc[i, "BoroughID_O"], tfc[i, "BoroughID_D"]]
#   }
# }

# The same as the above.
if (FARE_MODE) {
  tfc$Money_Rail <-
    sapply(split(tfc, seq(nrow(tfc))), function(x)
      boroughFare[x$BoroughID_O, x$BoroughID_D])
}

tfc$Time_Public1 <-
  ifelse(tfc$Time_Bus <= tfc$Time_Rail,
         tfc$Time_Bus,
         tfc$Time_Rail)

tfc$Diff_Time1 <- tfc$Time_Public1 - tfc$Time_Car

# For tfc.
if (FARE_MODE) {
  tfc$Cost_Car <-
    tfc$Time_Car + tfc$Money_Car * MONEY_TO_TIME
  
  tfc$Cost_Bus <-
    tfc$Time_Bus + tfc$Money_Bus * MONEY_TO_TIME
  
  tfc$Cost_Rail <-
    tfc$Time_Rail + tfc$Money_Rail * MONEY_TO_TIME
  
  tfc$Time_Public2 <-
    ifelse(tfc$Cost_Bus <= tfc$Cost_Rail,
           tfc$Time_Bus,
           tfc$Time_Rail)
  
  tfc$Diff_Time2 <- tfc$Time_Public2 - tfc$Time_Car
  
  tfc$Money_Public1 <-
    ifelse(tfc$Time_Bus <= tfc$Time_Rail,
           tfc$Money_Bus,
           tfc$Money_Rail)
  
  tfc$Money_Public2 <-
    ifelse(tfc$Cost_Bus <= tfc$Cost_Rail,
           tfc$Money_Bus,
           tfc$Money_Rail)
  
  tfc$Cost_Public1 <-
    ifelse(tfc$Time_Bus <= tfc$Time_Rail,
           tfc$Cost_Bus,
           tfc$Cost_Rail)
  
  tfc$Cost_Public2 <-
    ifelse(tfc$Cost_Bus <= tfc$Cost_Rail,
           tfc$Cost_Bus,
           tfc$Cost_Rail)
  
  tfc$Diff_Money1 <- tfc$Money_Public1 - tfc$Money_Car
  tfc$Diff_Money2 <- tfc$Money_Public2 - tfc$Money_Car
  
  tfc$Diff_Cost1 <- tfc$Cost_Public1 - tfc$Cost_Car
  tfc$Diff_Cost2 <- tfc$Cost_Public2 - tfc$Cost_Car
}

atfc$Time_Public1 <-
  ifelse(atfc$Time_Bus <= atfc$Time_Rail,
         atfc$Time_Bus,
         atfc$Time_Rail)

atfc$Diff_Time1 <- atfc$Time_Public1 - atfc$Time_Car

# For atfc.
if (FARE_MODE) {
  atfc$Cost_Car <-
    atfc$Time_Car + atfc$Money_Car * MONEY_TO_TIME
  
  atfc$Money_Bus <- BUS_FARE
  
  atfc$Cost_Bus <-
    atfc$Time_Bus + atfc$Money_Bus * MONEY_TO_TIME
  
  atfc$Cost_Rail <-
    atfc$Time_Rail + atfc$Money_Rail * MONEY_TO_TIME
  
  atfc$Time_Public2 <-
    ifelse(atfc$Cost_Bus <= atfc$Cost_Rail,
           atfc$Time_Bus,
           atfc$Time_Rail)
  
  atfc$Diff_Time2 <- atfc$Time_Public2 - atfc$Time_Car
  
  atfc$Money_Public1 <-
    ifelse(atfc$Time_Bus <= atfc$Time_Rail,
           atfc$Money_Bus,
           atfc$Money_Rail)
  
  atfc$Money_Public2 <-
    ifelse(atfc$Cost_Bus <= atfc$Cost_Rail,
           atfc$Money_Bus,
           atfc$Money_Rail)
  
  atfc$Cost_Public1 <-
    ifelse(atfc$Time_Bus <= atfc$Time_Rail,
           atfc$Cost_Bus,
           atfc$Cost_Rail)
  
  atfc$Cost_Public2 <-
    ifelse(atfc$Cost_Bus <= atfc$Cost_Rail,
           atfc$Cost_Bus,
           atfc$Cost_Rail)
  
  atfc$Diff_Money1 <- atfc$Money_Public1 - atfc$Money_Car
  atfc$Diff_Money2 <- atfc$Money_Public2 - atfc$Money_Car
  
  atfc$Diff_Cost1 <- atfc$Cost_Public1 - atfc$Cost_Car
  atfc$Diff_Cost2 <- atfc$Cost_Public2 - atfc$Cost_Car
}

tfc$Diff_Time <- tfc$Diff_Time1
atfc$Diff_Time <- atfc$Diff_Time1

# write_csv(tfc, "TravelCost_MSOA.csv")
write_csv(atfc, "TravelCost.csv")

atfc1 <-
  atfc %>% filter(P_Car > 0) # Drop travel flows with car flow == 0.

# 30 is parallel.
atfc1 <- atfc1 %>% filter(Diff_Time >= 30)

# View(atfc1)

if (FARE_MODE == F) {
  lm1 <-
    lm(Log_PCar ~ Diff_Time + FuelCost + CongestionCharge + ParkingCharge_D,
       data = atfc1)
} else {
  lm1 <-
    lm(
      Log_PCar ~ Diff_Time + Money_Public2 + FuelCost + CongestionCharge + ParkingCharge_D,
      data = atfc1
    )
}

print(lm1)

summary(lm1)

plot(x = atfc1$Diff_Time,
     y = atfc1$Log_PCar,
     main = "Log_PCar ~ Diff_Time")

abline(lm1)

car::vif(lm1)
confint(lm1)

# library(QuantPsyc) # Conflicts with dplyr::select().
# lm.beta(lm1)

atfc1$P1 <-
  lm1$coef[1] + (lm1$coef[2] * atfc1$Diff_Time) + (lm1$coef[3] * atfc1$FuelCost) + (lm1$coef[4] * atfc1$CongestionCharge) + (lm1$coef[5] * atfc1$ParkingCharge_D)

cor(atfc1$Log_PCar, atfc1$P1)

atfc1$P2 <- 1 /
  (1 + exp(-(
    lm1$coef[1] + (lm1$coef[2] * atfc1$Diff_Time) + (lm1$coef[3] * atfc1$FuelCost) + (lm1$coef[4] * atfc1$CongestionCharge)
    + (lm1$coef[5] * atfc1$ParkingCharge_D)
  )))

cor(atfc1$P_Car, atfc1$P2)

if (WRITE_LM_RESULTS_MODE)
  write_csv(atfc1, "LMResults1.csv")

atfc1$P3 <- 1 /
  (1 + exp(-(
    lm1$coef[1] + (lm1$coef[2] * (atfc1$Diff_Time - 5)) + (lm1$coef[3] * atfc1$FuelCost) + (lm1$coef[4] * atfc1$CongestionCharge)
    + (lm1$coef[5] * atfc1$ParkingCharge_D)
  )))

atfc1$P4 <- 1 /
  (1 + exp(-(
    lm1$coef[1] + (lm1$coef[2] * atfc1$Diff_Time) + (lm1$coef[3] * atfc1$FuelCost) + (lm1$coef[4] * atfc1$CongestionCharge)
    + (lm1$coef[5] * (atfc1$ParkingCharge_D + 1))
  )))

mean(atfc1$P1)

mean(atfc1$P2)

mean(atfc1$P3)

mean(atfc1$P4)

# MSOA level.
tfc1 <- tfc %>% filter(P_Car > 0)

tfc1 <- tfc1 %>% filter(Diff_Time >= 30)

# View(tfc1)

tfc1$P1 <-
  lm1$coef[1] + (lm1$coef[2] * tfc1$Diff_Time) + (lm1$coef[3] * tfc1$FuelCost) + (lm1$coef[4] * tfc1$CongestionCharge) + (lm1$coef[5] * tfc1$ParkingCharge_D)

cor(tfc1$Log_PCar, tfc1$P1) # NaN because some P_Car == 1 and Log_PCar == Inf.

tfc1$P2 <- 1 /
  (1 + exp(-(
    lm1$coef[1] + (lm1$coef[2] * tfc1$Diff_Time) + (lm1$coef[3] * tfc1$FuelCost) + (lm1$coef[4] * tfc1$CongestionCharge)
    + (lm1$coef[5] * tfc1$ParkingCharge_D)
  )))

cor(tfc1$P_Car, tfc1$P2)
