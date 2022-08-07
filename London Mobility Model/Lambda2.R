atfc2 <-
  atfc %>% filter(P_Car > 0) # Drop travel flows with car flow == 0.

atfc2 <- atfc2 %>% filter(Diff_Time < 30)

if (FARE_MODE == F) {
  lm2 <-
    lm(Log_PCar ~ Diff_Time + FuelCost + CongestionCharge + ParkingCharge_D,
       data = atfc2)
} else {
  lm2 <- lm(
    Log_PCar ~ Diff_Time + Money_Public1 + FuelCost + CongestionCharge + ParkingCharge_D,
    data = atfc2
  )
}

print(lm2)

summary(lm2)

plot(x = atfc2$Diff_Time,
     y = atfc2$Log_PCar,
     main = "Log_PCar ~ Diff_Time")

abline(lm2)

car::vif(lm2)
confint(lm2)

# library(QuantPsyc)
# lm.beta(lm2)

atfc2$P1 <-
  lm2$coef[1] + (lm2$coef[2] * atfc2$Diff_Time) + (lm2$coef[3] * atfc2$FuelCost) + (lm2$coef[4] * atfc2$CongestionCharge) + (lm2$coef[5] * atfc2$ParkingCharge_D)

cor(atfc2$Log_PCar, atfc2$P1)

atfc2$P2 <- 1 /
  (1 + exp(-(
    lm2$coef[1] + (lm2$coef[2] * atfc2$Diff_Time) + (lm2$coef[3] * atfc2$FuelCost) + (lm2$coef[4] * atfc2$CongestionCharge) + (lm2$coef[5] * atfc2$ParkingCharge_D)
  )))

cor(atfc2$P_Car, atfc2$P2)

if (WRITE_LM_RESULTS_MODE)
  write_csv(atfc2, "LMResults2.csv")

mean(atfc2$P1)

mean(atfc2$P2)

# MSOA level.
tfc2 <- tfc %>% filter(P_Car > 0)

tfc2 <- tfc2 %>% filter(Diff_Time < 30)

# View(tfc2)

tfc2$P1 <-
  lm2$coef[1] + (lm2$coef[2] * tfc2$Diff_Time) + (lm2$coef[3] * tfc2$FuelCost) + (lm2$coef[4] * tfc2$CongestionCharge) + (lm2$coef[5] * tfc2$ParkingCharge_D)

cor(tfc2$Log_PCar, tfc2$P1) # NaN because some P_Car == 1 and Log_PCar == Inf.

tfc2$P2 <- 1 /
  (1 + exp(-(
    lm2$coef[1] + (lm2$coef[2] * tfc2$Diff_Time) + (lm2$coef[3] * tfc2$FuelCost) + (lm2$coef[4] * tfc2$CongestionCharge) + (lm2$coef[5] * tfc2$ParkingCharge_D)
  )))

cor(tfc2$P_Car, tfc2$P2)
