indNew <- ind

if (BATCH_MODE == F) {
  indSave <- ind
  
  reduceCarTravel_mean <-
    tapply(ind$ReduceCarTravel, ind$Worldview, mean, na.rm = T)
  
  reduceCarTravel_sd <-
    tapply(ind$ReduceCarTravel, ind$Worldview, sd, na.rm = T)
}

# Before doing the following, make sure that ind or indNew has been sorted by worldview.
for (w in 1:3) {
  indSet <- filter(indNew, Worldview == w)
  
  n <- sum(is.na(indSet$ReduceCarTravel))
  
  values <-
    indSet %>% drop_na(ReduceCarTravel) %>% pull(ReduceCarTravel)
  
  # values <- rnorm(nrow(indSet), mean = reduceCarTravel_mean[w], sd = reduceCarTravel_sd[w])
  
  # View(values)
  
  indNew[(indNew$Worldview == w) &
           is.na(indNew$ReduceCarTravel), "ReduceCarTravel"] <-
    sample(values, size = n, replace = T)
}

if (DEBUG_MODE)
  View(indNew)

if (BATCH_MODE == F) {
  indSave %>% drop_na(ReduceCarTravel) %>%
    ggplot(aes(x = ReduceCarTravel)) +
    geom_bar(fill = RED) +
    geom_text(aes(label = ..count..), vjust = -0.5, stat = "count") +
    labs(x = "Reduce Car Trael",
         y = "Count",
         title = "Old Scores of \"Reduce Car Travel\"")
  
  indNew %>%
    ggplot(aes(x = ReduceCarTravel)) +
    geom_bar(fill = BLUE) +
    geom_text(aes(label = ..count..), vjust = -0.5, stat = "count") +
    labs(x = "Reduce Car Trael",
         y = "Count",
         title = "New Scores of \"Reduce Car Travel\"")
  
  indSave %>% drop_na(ReduceCarTravel) %>% filter(Worldview == 1) %>%
    ggplot(aes(x = ReduceCarTravel)) +
    geom_bar(fill = RED) +
    geom_text(aes(label = ..count..), vjust = -0.5, stat = "count") +
    labs(x = "Reduce Car Trael",
         y = "Count",
         title = "Old Scores of \"Reduce Car Travel\", Egalitarian")
  
  indNew %>% filter(Worldview == 1) %>%
    ggplot(aes(x = ReduceCarTravel)) +
    geom_bar(fill = BLUE) +
    geom_text(aes(label = ..count..), vjust = -0.5, stat = "count") +
    labs(x = "Reduce Car Trael",
         y = "Count",
         title = "New Scores of \"Reduce Car Travel\", Egalitarian")
  
  indSave1 <-
    indSave %>% mutate(Worldview = as.factor(indSave$Worldview))
  
  indNew1 <-
    indNew %>% mutate(Worldview = as.factor(indNew$Worldview))
  
  indSave1 %>% drop_na(ReduceCarTravel) %>%
    ggplot(aes(x = ReduceCarTravel,
               fill = Worldview)) +
    geom_density(alpha = 0.5) +
    labs(title = "Old \"Reduce Car Travel\" by Worldviews") + scale_fill_manual(values = c(GREEN, BLUE, RED))
  
  indNew1 %>%
    ggplot(aes(x = ReduceCarTravel,
               fill = Worldview)) +
    geom_density(alpha = 0.5) +
    labs(title = "New \"Reduce Car Travel\" by Worldviews") + scale_fill_manual(values = c(GREEN, BLUE, RED))
  
  reduceCarTravel_mean_new <-
    tapply(indNew$ReduceCarTravel, indNew$Worldview, mean)
  
  reduceCarTravel_sd_new <-
    tapply(indNew$ReduceCarTravel, indNew$Worldview, sd)
}
