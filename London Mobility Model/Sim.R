library(tidyverse)
library(readxl)
library(ipfp)

# RNGversion("4.1.1")

DIR_WORK <- "D:/Google/MicroSim"

setwd(DIR_WORK)

source("Config.R", echo = T)

if (BATCH_MODE) {
  set.seed(BATCH_RANDOM_SEED)
} else if (RANDOM_SEED_MODE) {
  set.seed(RANDOM_SEED)
}

# When BOROUGH_MODE is F, POPULATION_SCALE should be 1.
BOROUGH_MODE <-
  T # True for the borough mode; false for the MSOA mode.

# Recommended combination:
# POPULATION_SCALE = 1, INTEGER_AGENT_MODE = F
# POPULATION_SCALE = 0.1, INTEGER_AGENT_MODE = T
POPULATION_SCALE <- 0.1
INTEGER_AGENT_MODE <- T

# SAVE_MAP_MODE <- T # True for saving maps to the output directory.

AGENT_NO_NA_MODE <- T

if (BOROUGH_MODE) {
  ZONE_ID <- "BoroughID"
  
  ZONE_NAME <- "BoroughName"
} else {
  ZONE_ID <- "MSOAID"
  
  ZONE_NAME <- "MSOAName"
}

# Load individual data (BSA 2016 after factor analysis).
ind <- read_csv("BSA2016/Thesis.csv")

if (DEBUG_MODE)
  View(ind)

# Make sure that ind is sorted by worldview.
# indTest <- arrange(ind, Worldview)
#
# identical(ind, indTest)
#
# all.equal(ind, indTest)
#
# library(arsenal)
# comparedf(ind, indTest)
# summary(comparedf(ind, indTest))

ind <- arrange(ind, Worldview)

ind <- ind %>% select(
  "Sex",
  "RAgeCat",
  "HHincome",
  "EduLevel",
  "Worldview",
  "CON1",
  "LAB1",
  "LD1",
  "GRE1",
  "UKIP1",
  "BNP1",
  "SOC1",
  "OTHERS1",
  # "DRIVE",
  "CReduceCarTravel"
  # "F1",
  # "F2",
  # "F3"
  # "HigherCarTax",
  # "UnlessOthersDo",
  # "CongestionProblem"
)

colnames(ind)[colnames(ind) == "CReduceCarTravel"] <-
  "ReduceCarTravel"

# ind$IsCarUser <- (3 - ind$DRIVE) - 1

if (AGENT_NO_NA_MODE) {
  source("AgentNoNA.R", echo = T)
  
  ind <- indNew
  
  # View(ind)
}

zoneLookup <- read_csv("data/OA-LSOA-MSOA-LA_2011.csv")

if (DEBUG_MODE)
  View(zoneLookup)

zoneLookup <-
  zoneLookup %>% select("MSOA11CD", "MSOA11NM", "LAD11CD", "LAD11NM", "Inner_Outer") %>% unique()

colnames(zoneLookup) <-
  c("MSOAID",
    "MSOAName",
    "BoroughID",
    "BoroughName",
    "Region")

zoneLookup <-
  arrange(zoneLookup, BoroughID, MSOAID) # Make sure the result is ordered.

# Constraint 1: sex/age.
source("Cons_SexAge.R")

# Take a look at data.
head(ind)
head(cons1)

if (BATCH_MODE == F)
  View(zoneList)

if (BATCH_MODE == F)
  View(zoneLookup)

sum(zoneList$Pop)

if (sum(cons1) != sum(zoneList$Pop))
  myStop("The total number of people in cons1 is incorrect.")

if (!identical(rowSums(cons1), zoneList$Pop))
  myStop("The total number of people by zones in cons1 is incorrect.")

# table(rowSums(cons1) == zoneList$Pop)

# Constraint 2: income.
source("Cons_Income.R")

sum(cons2) == sum(cons1)

rowSums(cons2) == rowSums(cons1) # Decimals need to be considered.

# cons2Save <- cons2

source("Functions.R")

saveNames <- colnames(cons2)

# Integerize cons2.
cons2 <-
  apply(cons2, MARGIN = 1, function(x)
    int_trs(x)) %>% t() %>% data.frame()

colnames(cons2) <- saveNames

if (sum(cons2) != sum(zoneList$Pop))
  myStop("The total number of people in cons2 is incorrect.")

if (!identical(rowSums(cons2), zoneList$Pop))
  myStop("The total number of people by zones in cons2 is incorrect.")

# Constraint 3: educational level.
source("Cons_Edu.R")

sum(cons3) == sum(cons1)

rowSums(cons3) == rowSums(cons1) # Decimals need to be considered.

# cons3Save <- cons3

saveNames <- colnames(cons3)

# Integerize cons3.
cons3 <-
  apply(cons3, MARGIN = 1, function(x)
    int_trs(x)) %>% t() %>% data.frame()

colnames(cons3) <- saveNames

if (sum(cons3) != sum(zoneList$Pop))
  myStop("The total number of people in cons3 is incorrect.")

if (!identical(rowSums(cons3), zoneList$Pop))
  myStop("The total number of people by zones in cons3 is incorrect.")

# Constraint 4: political party identification.
source("Cons_Party.R")

sum(cons4) == sum(cons1)

rowSums(cons4) == rowSums(cons1) # Decimals need to be considered.

# cons4Save <- cons4

saveNames <- colnames(cons4)

# Integerize cons4.
cons4 <-
  apply(cons4, MARGIN = 1, function(x)
    int_trs(x)) %>% t() %>% data.frame()

colnames(cons4) <- saveNames

if (sum(cons4) != sum(zoneList$Pop))
  myStop("The total number of people in cons4 is incorrect.")

if (!identical(rowSums(cons4), zoneList$Pop))
  myStop("The total number of people by zones in cons4 is incorrect.")

if ((sum(cons1) != sum(zoneList$Pop)) |
    (sum(cons2) != sum(zoneList$Pop)) |
    (sum(cons3) != sum(zoneList$Pop)) |
    (sum(cons4) != sum(zoneList$Pop)))
  myStop("Constraint total counts mismatch.")

# summary(rowSums(cons1) == rowSums(cons2))
# summary(rowSums(cons2) == rowSums(cons3))
# summary(rowSums(cons3) == rowSums(cons4))

if (!identical(rowSums(cons1), zoneList$Pop) |
    !identical(rowSums(cons2), zoneList$Pop) |
    !identical(rowSums(cons3), zoneList$Pop) |
    !identical(rowSums(cons4), zoneList$Pop))
  myStop("Constraint row counts mismatch.")

cons <- bind_cols(cons1, cons2, cons3, cons4)

if (DEBUG_MODE)
  View(cons)

catLab <- colnames(cons) # Categorical names.

# Create binary dummy variables for each category.
source("Categorize.R")

# Check if the number in each category is correct.
if (sum(indCat[, 1:ncol(cons1)]) != nrow(ind))
  myStop("indCat's sum for cons1 is incorrect.")

if (sum(indCat[, ncol(cons1) + (1:ncol(cons2))]) != nrow(ind))
  myStop("indCat's sum for cons2 is incorrect.")

if (sum(indCat[, ncol(cons1) + ncol(cons2) + (1:ncol(cons3))]) != nrow(ind))
  myStop("indCat's sum for cons3 is incorrect.")

if (sum(indCat[, ncol(cons1) + ncol(cons2) + ncol(cons3) + (1:ncol(cons4))]) != nrow(ind))
  myStop("indCat's sum for cons4 is incorrect.")

if (length(which(cons <= 0)) > 0)
  myStop("A constraint number cannot be zero or negative.") # Because it will cause NaN in weights.

# (14+8+5+1):8
# 14+8+5+1:8 ==> 14+8+5+(1:8)

# Create a 2D weight matrix (individuals & zones).
### weights <- array(NA, dim = c(nrow(ind), nrow(cons)))

# if (DEBUG_MODE)
#   View(weights)

# Convert survey data into aggregates to compare with census.
### indAgg <- matrix(colSums(indCat), nrow(cons), ncol(cons), byrow = T)

cons <-
  apply(cons, MARGIN = 2, FUN = as.numeric) # Convert the integer constraints to a numeric matrix.

indCat_t <- t(indCat) # Transpose the dummy variables for ipfp.

if (DEBUG_MODE)
  View(indCat_t)

x0 <- rep(1, nrow(ind)) # Set the initial weights.

if (DEBUG_MODE)
  View(x0)

weights <-
  apply(
    cons,
    MARGIN = 1,
    FUN = function(x)
      ipfp(x, indCat_t, x0) #, maxit = 1000, verbose = T)
  )

if (DEBUG_MODE)
  View(weights)

# Convert back to aggregates.
# x (weights): matrix.
# indCat: data frame.
indAgg <- t(apply(
  weights,
  MARGIN = 2,
  FUN = function(x)
    colSums(x * indCat)
))

if (!identical(colnames(indAgg), colnames(cons)))
  myStop("indAgg is incorrect.")

if (DEBUG_MODE)
  View(indAgg)

# colSums((person, zone) * (person, category)).
# (zone i has n individuals) * (each individual accounts for what categories): sum up each category by zones.

# Test the results for the first row.
indAgg[1, ] - cons[1, ] # should be zero or close to zero.
indAgg[2, ] - cons[2, ] # should be zero or close to zero.
indAgg[3, ] - cons[3, ] # should be zero or close to zero.
indAgg[4, ] - cons[4, ] # should be zero or close to zero.
indAgg[5, ] - cons[5, ] # should be zero or close to zero.

cor(as.numeric(cons), as.numeric(indAgg)) # Fit between constraints and estimates.

# head(n = 30, cons)
# head(n = 30, indAgg)

which(abs(indAgg - cons) == max(abs(indAgg - cons)), arr.ind = T)

# Integerize if integer results are required.
source("Integerize.R")

iInd <- ints_df

colnames(iInd)[colnames(iInd) == "id"] <- "ID"
colnames(iInd)[colnames(iInd) == "zone"] <- "Zone"

# remove(ints_df)

# Optional.
iInd <- arrange(iInd, Zone, ID)

if (DEBUG_MODE)
  View(iInd)

if (nrow(iInd) != sum(zoneList$Pop))
  myStop("Populations mismatch.")

# if ((BATCH_MODE == F) & (SAVE_MAP_MODE == T))
#   source("CulturalMap.R") # Dangerous: loading tmap affects the random number stream.
