#Author:Dominic Behrens
#Project: NSW Fair Trading Bond Data
#Purpose: Targets Script file
#Date: July 2024
#Notes:

#load targets
library(targets,tarchetypes)

source('./Scripts/functions.R')
tar_option_set(packages=c(  "tidyverse",
                            "readxl",  
                            "janitor",
                            "lubridate",
                            "sf",
                            "tmap",
                            "zoo",
                            "rvest"))


list(
  tar_target(data_files,"./Data"%>%
               list.files()),
  tar_target(missing_files,check_for_new_files(data_files)),
  tar_target(all_rents,make_all_rents('./Data','./Outputs/Data',missing_files)),
  tar_target(timeseries,make_timeseries(all_rents,'./Outputs/Data'))
)
