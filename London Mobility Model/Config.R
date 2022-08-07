DIR_WORK <- "D:/Google/MicroSim"

setwd(DIR_WORK)

Sys.setlocale("LC_ALL", "English")

DEBUG_MODE <- F

BATCH_MODE <- F

if (BATCH_MODE)
  DIR_BATCH_OUTPUT <- paste0(DIR_WORK, "/batch")

NUM_RUN <- 100

RANDOM_SEED_MODE <- T

if ((RANDOM_SEED_MODE == T) & (BATCH_MODE == F))
  RANDOM_SEED <- 1

options(digits = 10)

TWO_WAYS_MODE <- T

FARE_MODE <- F

WEIGHTED_TIME_MODE <- F

WRITE_LM_RESULTS_MODE <- T

# library(scales)
# show_col(palette())
# palette()

GREEN <- palette()[3]
BLUE <- palette()[4]
RED <- palette()[2]

SKY <- palette()[5]
MAGENTA <- palette()[6]
YELLOW <- palette()[7]
GRAY <- palette()[8]

WHITE <- "#FFFFFF"

IMAGE_WIDTH <- 16
IMAGE_WIDTH_SMALL <- 12
IMAGE_HEIGHT <- 10

POINT_SIZE <- 2
LINE_SIZE <- 1
TEXT_SIZE <- 6
BASE_SIZE <- 18

TITLE_SIZE <- 1
NUMBER_BINS <- 4

EGALITARIAN <- "Egalitarian"
HIERARCHIST <- "Hierarchist"
INDIVIDUALIST <- "Individualist"

myStop <- function(msg) {
  print(msg)
  
  quit()
}

DIR_OUTPUT <- paste0(DIR_WORK, "/output")
DIR_OUTPUT_BOROUGH <- paste0(DIR_OUTPUT, "/borough")
DIR_OUTPUT_MSOA <- paste0(DIR_OUTPUT, "/MSOA")

WARMUP_DURATION <- 120

TICK_WARMUP_START <- 3
TICK_W0 <- TICK_WARMUP_START - 1
TICK_BEFORE_W0 <- TICK_WARMUP_START - 2
TICK_WARMUP_END <- TICK_W0 + WARMUP_DURATION

DECIMAL_MODE_SHARE <- 1
DECIMAL_WORLDVIEW_SHARE <- 1
DECIMAL_TPB <- 3
