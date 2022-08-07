source("Utility.R", echo = T)

pop <-
  data.frame(matrix(0, nrow = ncol(weights), ncol = 3))

colnames(pop) <- c(EGALITARIAN, HIERARCHIST, INDIVIDUALIST)

if (nrow(weights) != nrow(ind))
  myStop("Row numbers are different.")

# i: individual, j: zone.
for (i in 1:nrow(weights)) {
  w <- ind[i, "Worldview"]
  
  for (j in 1:ncol(weights)) {
    if (w == 1) {
      pop[j, EGALITARIAN] <- pop[j, EGALITARIAN] + weights[i, j]
    } else if (w == 2) {
      pop[j, HIERARCHIST] <- pop[j, HIERARCHIST] + weights[i, j]
    } else if (w == 3) {
      pop[j, INDIVIDUALIST] <- pop[j, INDIVIDUALIST] + weights[i, j]
    } else {
      myStop("Invalid value of worldview.")
    }
  }
}

# View(pop)

pop <- bind_cols(zoneList, pop)

sum(pop$Pop)

sum(pop$Egalitarian + pop$Hierarchist + pop$Individualist)

# Maybe false because of decimals.
sum(pop$Pop) == sum(pop$Egalitarian + pop$Hierarchist + pop$Individualist)

pop <-
  pop %>% add_row(
    Pop = sum(pop$Pop),
    Egalitarian = sum(pop$Egalitarian),
    Hierarchist = sum(pop$Hierarchist),
    Individualist = sum(pop$Individualist)
  )

pop$Total <- pop$Egalitarian + pop$Hierarchist + pop$Individualist

# Maybe false because of decimals.
pop$Pop == pop$Total

pop$Total - pop$Pop

pop$Pct_E <- pop$Egalitarian / pop$Total

pop$Pct_H <- pop$Hierarchist / pop$Total

pop$Pct_I <- pop$Individualist / pop$Total

pop1 <- pop
pop1$Pct_E1 <- percentFormat(pop1$Pct_E, DECIMAL_WORLDVIEW_SHARE)
pop1$Pct_H1 <- percentFormat(pop1$Pct_H, DECIMAL_WORLDVIEW_SHARE)
pop1$Pct_I1 <- percentFormat(pop1$Pct_I, DECIMAL_WORLDVIEW_SHARE)
# View(pop1)
write_csv(pop1, "Worldview_Summary.csv")

pct <- pop %>% select("Pct_E", "Pct_H", "Pct_I")

pct <- pct %>% slice(-nrow(pct))

colnames(pct) <-
  c(EGALITARIAN,
    HIERARCHIST,
    INDIVIDUALIST)
