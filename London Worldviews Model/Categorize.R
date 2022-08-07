# Convert numeric variables into categorical variables.
# Create 0/1 counts from survey data.

# Constraint 1: sex/age.
sa <- paste0(ind$Sex, ind$RAgeCat)
summary(sa)
unique(sa)

# Create the matrix for constraint 1 - sex/age.
m1 <- model.matrix( ~ sa - 1) # Ordered alphabetically.
# View(m1)
head(m1)
head(cons1)

# Order matters.
# "names()" cannot work with matrix.
colnames(m1) <- colnames(cons1)
head(m1)
# summary(rowSums(m1))

if (table(rowSums(m1))["1"] != nrow(ind))
  myStop("Matrix 1 is incorrect.")

# Constraint 2: household income.
head(ind$HHincome)

# Align household incomes.
newIncome <- function(income) {
  sapply(income, function(x) {
    if (x == 1) {
      x <- 1
    } else if (x == 2) {
      x <- 2
    } else if (x >= 3 & x <= 5) {
      x <- 3
    } else if (x >= 6 & x <= 8) {
      x <- 4
    } else if (x >= 9 & x <= 11) {
      x <- 5
    } else if (x >= 12 & x <= 14) {
      x <- 6
    } else if (x >= 15 & x <= 17) {
      x <- 7
    } else if (x >= 18 & x <= 20) {
      x <- 8
    } else {
      myStop("Invalid argument of income.")
    }
  })
}

ind$NewIncome <- newIncome(ind$HHincome)

head(ind$NewIncome)

class(ind$NewIncome)

# It is important to use the factor or character type.
ind$NewIncome <- as.factor(ind$NewIncome)

m2 <- model.matrix( ~ ind$NewIncome - 1)
# View(m2)
head(m2)
head(cons2)

colnames(m2) <- colnames(cons2)
head(m2)
# summary(rowSums(m2))

if (table(rowSums(m2))["1"] != nrow(ind))
  myStop("Matrix 2 is incorrect.")

# Constraint 3: educational level.
# Align educational levels.
newEdu <- function(edu) {
  sapply(edu, function(x) {
    if (x == 6) {
      # Degree.
      x <- 5
    } else if (x == 5 | x == 4) {
      # Below degree and A level.
      x <- 4
    } else if (x == 3 | x == 2) {
      # O level and CSE.
      x <- 3
    } else if (x == 1) {
      # No qualification.
      x <- 1
    } else {
      # Others (average score).
      x <- 2
    }
  })
}

ind$NewEdu <- newEdu(ind$EduLevel)

ind$NewEdu <- as.factor(ind$NewEdu)

m3 <- model.matrix( ~ ind$NewEdu - 1)
# View(m3)

colnames(m3) <- colnames(cons3)
head(m3)
# summary(rowSums(m3))

if (table(rowSums(m3))["1"] != nrow(ind))
  myStop("Matrix 3 is incorrect.")

# Constraint 4: political party identification.
m4 <-
  tibble(ind$CON1,
         ind$LAB1,
         ind$LD1,
         ind$GRE1,
         ind$UKIP1,
         ind$BNP1,
         ind$SOC1,
         ind$OTHERS1) %>% as.matrix() # Because m1/m2/m3 are matrices.

# View(m4)

colnames(m4) <- colnames(cons4)
head(m4)
# summary(rowSums(m4))

if (table(rowSums(m4))["1"] != nrow(ind))
  myStop("Matrix 4 is incorrect.")

indCat <- data.frame(cbind(m1, m2, m3, m4))
# indCat <- data.frame(bind_cols(m1, m2, m3, m4)) # Wrong!

# rm(m1, m2, m3, m4)

if (!identical(colnames(indCat), catLab))
  myStop("indCat's column names are incorrect.")

head(indCat)

# View(indCat)

# Should be equal to the number of constraints.
# summary(rowSums(indCat))

# Quotation marks are necessary.
if (table(rowSums(indCat))["4"] != nrow(ind))
  myStop("indCat's row sums are incorrect.")
