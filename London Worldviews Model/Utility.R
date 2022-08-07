DIR_IMAGE <- paste0(DIR_WORK, "/images")

if (file.exists(DIR_IMAGE) == F)
  dir.create(DIR_IMAGE)

outputDir <- function(x) {
  return(paste0(DIR_IMAGE, "/", x))
}

myGgsave <- function(file, isSmall) {
  ggsave(
    outputDir(paste0(file, ".pdf")),
    width = ifelse(isSmall, IMAGE_WIDTH_SMALL, IMAGE_WIDTH),
    height = IMAGE_HEIGHT,
    units = "in"
  )
  
  ggsave(
    outputDir(paste0(file, ".png")),
    width = ifelse(isSmall, IMAGE_WIDTH_SMALL, IMAGE_WIDTH),
    height = IMAGE_HEIGHT,
    units = "in"
  )
}

saveMap <- function(tm, file, isBorough) {
  if (isBorough) {
    tmap_save(tm, paste0(DIR_OUTPUT_BOROUGH, "/", file, ".pdf"))
    
    tmap_save(tm, paste0(DIR_OUTPUT_BOROUGH, "/", file, ".png"))
  } else {
    tmap_save(tm, paste0(DIR_OUTPUT_MSOA, "/", file, ".pdf"))
    
    tmap_save(tm, paste0(DIR_OUTPUT_MSOA, "/", file, ".png"))
  }
}

percentFormat <- function(number, decimal) {
  return((number * 100) %>% round(decimal))
}
