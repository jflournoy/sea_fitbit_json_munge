#The goal here is to read in all of the intra-day data and export it to a csv
#file in a readable form. This is the format of a json file read into a list
#here:
#
library(rjson)
j <- rjson::fromJSON(file = '/data/jflournoy/SEA/fitbitcleaning/data/raw/1001_2017-01-04.json')

# > names(j)
#  [1] "activities-steps"            
#  [2] "activities-steps-intraday"   
#  [3] "activities-calories"         
#  [4] "activities-calories-intraday"
#  [5] "activities-distance"         
#  [6] "activities-distance-intraday"
#  [7] "activities-heart"            
#  [8] "activities-heart-intraday"   
#  [9] "sleep"                       
# [10] "summary" 

RDS_dir <- '/data/jflournoy/SEA/fitbitcleaning/data/RDS'
RDS_file <- file.path(RDS_dir, 'intraday.RDS')
RDS_d_file_base <- file.path(RDS_dir, 'intraday_')
j_files <- dir('/data/jflournoy/SEA/fitbitcleaning/data/raw/', pattern = '*.json', full.names = TRUE)



if(!file.exists(RDS_file)){
  data_list <- lapply(j_files, function(file){
    j <- rjson::fromJSON(file = file)
    steps <- data.table::rbindlist(j$`activities-steps-intraday`$dataset)
    calories <- data.table::rbindlist(j$`activities-calories-intraday`$dataset)
    distance <- data.table::rbindlist(j$`activities-distance-intraday`$dataset)
    heart <- data.table::rbindlist(j$`activities-heart-intraday`$dataset)
    return(list(steps = steps,
                calories = calories,
                distance = distance,
                heart = heart,
                file = file))
  })
  if(!dir.exists(RDS_dir)){
    dir.create(RDS_dir)
  }
  saveRDS(data_list, RDS_file)
} else {
  data_list <- readRDS(RDS_file)
}

data_names <- c('steps',
                'calories',
                'distance',
                'heart')
names(data_names) <- data_names

d_list_fn <- paste0(RDS_d_file_base, 'dt_list.RDS')
if(!file.exists(d_list_fn)){
  d_list <- lapply(data_names, function(aname){
    this_d_list <- lapply(data_list, function(a){
      b <- a[[aname]]
      b$sub <- as.numeric(gsub('.*?([0-9]+)_.*', '\\1', a$file))
      date_obs <- gsub('.*?[0-9]+_([0-9-]+).*', '\\1', a$file)
      b$time <- as.POSIXct(paste0(date_obs, ' ', b$time), format = '%Y-%m-%d %H:%M:%S')
      return(b)
    })
    this_d <- data.table::rbindlist(this_d_list, fill = TRUE)
    return(this_d)
  })
  saveRDS(d_list, d_list_fn)
} else {
  d_list <- readRDS(d_list_fn)
}

NADA <- lapply(names(d_list), function(aname){
  d <- d_list[[aname]]
  fn <- paste0(RDS_d_file_base, aname, '.RDS')
  if(!file.exists(fn))
    saveRDS(d, fn)
})
