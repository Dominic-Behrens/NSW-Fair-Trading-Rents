#Author:Dominic Behrens
#Project: NSW Fair Trading Bond Data
#Purpose: Targets Script file
#Date: July 2024
#Notes:

#load targets
library(targets)

source('./Scripts/functions.R')
tar_option_set(packages=c(  "tidyverse",
                            "readxl",  
                            "janitor",
                            "lubridate",
                            "sf",
                            "tmap",
                            "zoo"))


list(
  tar_target(missing_files,check_for_new_files('./Data')),
  tar_target(all_rents,make_all_rents('./Data','./Outputs/Data')),
  tar_target(timeseries,make_timeseries('./Outputs/Data/all_rents_nsw.csv','./Outputs/Data'))
)