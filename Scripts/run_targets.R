#Author:Dominic Behrens
#Project:Fair Trading Rent Data
#Purpose:Run {Targets} Pipeline
#Date: July 2024
#Notes:

#load targets
library(targets)
#basic options
gc()
rm(list=ls())
options(scipen=999)
#vis network to make sure all working
tar_visnetwork()
#run pipeline
tar_make(callr_function = NULL)

