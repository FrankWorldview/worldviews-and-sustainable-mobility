# Because of the random seed, please run this file after running Sim.R.

source("Config.R", echo = T)

source("TravelFlow.R", echo = T)

# flowMSOA$Total is a vector, while flowMSOA[, "Total"] is a tibble.
flowBoroughPair <-
  aggregate(flowMSOA[, "Total"],
            by = list(flowMSOA$BoroughID_O, flowMSOA$BoroughID_D),
            sum)

if (DEBUG_MODE)
  View(flowBoroughPair)

colnames(flowBoroughPair) <- c("BoroughID_O", "BoroughID_D", "Flow")

flowBoroughPair <-
  arrange(flowBoroughPair, BoroughID_O, BoroughID_D)

flowBorough <-
  aggregate(flowMSOA[, "Total"], by = list(flowMSOA$BoroughID_O), sum)

if (DEBUG_MODE)
  View(flowBorough)

colnames(flowBorough) <- c("BoroughID_O", "Flow")

flowBorough <- arrange(flowBorough, BoroughID_O)

flowBoroughPair$FlowPct <-
  flowBoroughPair$Flow / flowBorough$Flow[match(flowBoroughPair$BoroughID_O, flowBorough$BoroughID_O)]

flowBoroughPair$People <-
  zoneList$Pop[match(flowBoroughPair$BoroughID_O, zoneList$BoroughID)] * flowBoroughPair$FlowPct

newFlowBoroughPair <-
  flowBoroughPair %>% select("BoroughID_O", "BoroughID_D", "People")

# View(newFlowBoroughPair)

# https://stackoverflow.com/questions/9617348/reshape-three-column-data-frame-to-matrix-long-to-wide-format
newFlowBoroughPair <-
  newFlowBoroughPair %>% pivot_wider(names_from = BoroughID_D,
                                     values_from = People) %>% select(-BoroughID_O)

saveNames <- colnames(newFlowBoroughPair)

# Integerize newFlowBoroughPair.
newFlowBoroughPair_Int <-
  apply(newFlowBoroughPair, MARGIN = 1, function(x)
    int_trs(x)) %>% t() %>% data.frame()

# View(newFlowBoroughPair_Int)

colnames(newFlowBoroughPair_Int) <- saveNames

if (min(newFlowBoroughPair_Int) < 0)
  myStop("Flow cannot be negative.")

# Should be equal.
sum(newFlowBoroughPair_Int) == sum(zoneList$Pop)

rowSums(newFlowBoroughPair_Int) == zoneList$Pop

if (!identical(rowSums(newFlowBoroughPair_Int), zoneList$Pop))
  myStop("Flow counts mismatch.")

newFlowBoroughPair_Int$BoroughID_O <- zoneList$BoroughID

peopleInt <-
  newFlowBoroughPair_Int %>% pivot_longer(!BoroughID_O, names_to = "BoroughID_D", values_to = "People_Adj")

# View(peopleInt)

if (!identical(flowBoroughPair[, c(1:2)], as.data.frame(peopleInt[, c(1:2)])))
  myStop("Colnames mismatch.")

flowBoroughPair$People_Adj <- peopleInt$People_Adj

# At most 1.
if (max(flowBoroughPair$People_Adj - floor(flowBoroughPair$People)) > 1)
  myStop("Integerization error.")

write_csv(flowBoroughPair, "FlowDist.csv")

# Generate all travel flows based on flowBoroughPair.
flow <-
  flowBoroughPair[rep(1:nrow(flowBoroughPair),
                      flowBoroughPair$People_Adj), c("BoroughID_O", "BoroughID_D")]

if (is.unsorted(flow$BoroughID_O))
  myStop("Flow should be sorted by BoroughID_O.")

if (DEBUG_MODE)
  View(flow) # Sorted by BoroughID_O (and then BoroughID_D).

flow <-
  arrange(flow, BoroughID_O, BoroughID_D) # This statement can be dropped.

# r1 <- as.integer(rep(row.names(flowBoroughPair),flowBoroughPair$People_Adj))
# r2 <- rep(1:nrow(flowBoroughPair), flowBoroughPair$People_Adj)
# identical(r1, r2)
# all.equal(r1, r2)

# Check if row.names(flowBoroughPair) is unsorted.
# is.unsorted(row.names(flowBoroughPair))
# is.unsorted(as.integer(row.names(flowBoroughPair)))
# is.unsorted(1:nrow(flowBoroughPair))

agent <- iInd

if (DEBUG_MODE)
  View(agent)

agent$BoroughID_O <-
  as.data.frame(zoneList)[agent$Zone, "BoroughID"]

# agent$BoroughID_O <- zoneList[agent$Zone, "BoroughID"]
# colnames(agent) # The column name/structure of "BoroughID_O" will be strange.

totPop <- 0

# For agents of each zone, assign a ticket to each of the agents.
# e.g. Zone 1: 1 ~ 615.
# e.g. Zone 2: (615+1 = 616) ~ (615+14630 = 15245).
for (i in 1:nrow(zoneList)) {
  borough <- pull(zoneList[i, "BoroughID"]) # Pull a tibble cell.
  
  pop <- pull(zoneList[i, "Pop"]) # Pull a tibble cell.
  
  rn <-
    sample(1:pop, size = pop, replace = F) # Shuffle 1:pop.
  
  row_start <- which(agent$BoroughID_O == borough)[1]
  
  row_end <- tail(which(agent$BoroughID_O == borough), n = 1)
  
  if (i == 1) {
    agent[row_start:row_end , "Ticket"] <- rn
  } else {
    agent[row_start:row_end , "Ticket"] <- totPop + rn
  }
  
  totPop <- totPop + pop
}

# Shuffle agents.
# For each zone, sort agents by their ticket numbers.
agent1 <- arrange(agent, Ticket)

if (DEBUG_MODE)
  View(agent1)

# Should be false (i.e. sorted).
if (is.unsorted(agent1$Zone) == T)
  myStop("Agents are not sorted by zones.")

# Ticket numbers correspond to the sequence numbers of flows.
agent1$Orig <- flow$BoroughID_O

agent1$Dest <- flow$BoroughID_D

# colnames(agent1)

# summary(agent1$BoroughID_O == agent1$Orig) # Check consistency. Should be all true.

if (!identical(agent1$BoroughID_O, agent1$Orig))
  myStop("An agent's origin boroughs are inconsistent.")

agent_sorted <-
  arrange(agent1, Orig, Dest, ID) # The result is also sorted by Worldview because ID is sorted by Worldview.
# agent_sorted <- arrange(agent1, Zone, Dest, ID) # This also works.

if (DEBUG_MODE)
  View(agent_sorted)

if (!identical(agent_sorted, arrange(agent1, Orig, Dest, Worldview, ID)))
  myStop("agent_sorted is sorted incorrectly.")

# agent_sorted1 <- arrange(agent1, Zone, Orig, Dest, ID) # This also works.
# library(arsenal)
# identical(agent_sorted, agent_sorted1) # Should be true.
# all.equal(agent_sorted, agent_sorted1) # Should be true.
# comparedf(agent_sorted, agent_sorted1) # There should be no differences.

# agent_sorted$Serial <- 1:nrow(agent_sorted)

agent_final <-
  agent_sorted %>% select("ID",
                          "Worldview",
                          "Orig",
                          "Dest",
                          "ReduceCarTravel")
# "F1",
# "F2",
# "F3",
# "HigherCarTax",
# "UnlessOthersDo",
# "CongestionProblem",
# "IsCarUser"

if (DEBUG_MODE)
  View(agent_final)

# "T" means type.
agent_final$ID <-
  paste0("T", agent_final$ID)

write_csv(agent_final, "Agent.csv")
