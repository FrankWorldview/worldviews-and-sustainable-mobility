library(filesstrings) # For moving files.

# Customize the work directory.
DIR_WORK <- "D:/Google/MicroSim"

setwd(DIR_WORK)

source("Config.R", echo = T)

if (BATCH_MODE) {
  for (i in 1:NUM_RUN) {
    print("------------------------------------------------------------")
    
    print(paste0("Run: ", i))
    
    BATCH_RANDOM_SEED <- i
    
    source("Sim.R", echo = T)
    
    source("DistributeFlow.R", echo = T)
    
    fileAgent <- paste0("Agent_", BATCH_RANDOM_SEED, ".csv")
    
    fileFlow <- paste0("FlowDist_", BATCH_RANDOM_SEED, ".csv")
    
    file.rename("Agent.csv", fileAgent)
    file.move(fileAgent, DIR_BATCH_OUTPUT)
    
    file.rename("FlowDist.csv", fileFlow)
    file.move(fileFlow, DIR_BATCH_OUTPUT)
  }
} else {
  source("Sim.R", echo = T)
  
  source("DistributeFlow.R", echo = T)
  
  file.rename("Agent.csv", "Agent_SingleRun.csv")
  
  file.rename("FlowDist.csv", "FlowDist_SingleRun.csv")
}

if (BATCH_MODE == F) {
  source("TravelTime.R", echo = T)
  
  source("MSOADistance.R", echo = T)
  
  source("Lambda1.R", echo = T)
  
  source("Lambda2.R", echo = T)
}
