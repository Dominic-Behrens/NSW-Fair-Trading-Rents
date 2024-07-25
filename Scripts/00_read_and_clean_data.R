#Author: Dominic Behrens
#Project: General Use 
#Purpose: Clean and organise NSW Fair Trading Rental Bond Data for Further Analysis
#Date: October 2023
#Notes: This script reads in and tidies the rental bond data for further analysis.
# it can take quite a while to run, and will only need to be updated when there's new data. 
# For further analysis, it's probably easiest to just use the outputs- all_rents_nsw or 
# postcode_rent_timeseries 

#load and install required packages
if(!require("pacman", character.only = T)) install.packages("pacman")

pacman::p_load(
  tidyverse,
  magrittr, 
  readxl, 
  openxlsx, 
  janitor,
  lubridate,
  readtext,
  rvest,
  scales,
  strayr,
  httr2,
  jsonlite
)

#basic options
gc()
rm(list=ls())
options(scipen=999)
Sys.unsetenv(c('http_proxy','https_proxy'))
#check to see if more recent data is available
#this will only work if you're at home- Deloitte IT in their wisdom blocks R from 
#accessing the internet when you're in the office. Just skip this section if it's throwing errors. ----

fair_trading_website<-read_html("https://www.fairtrading.nsw.gov.au/about-fair-trading/rental-bond-data")

latest_data_online<-html_element(fair_trading_website,'td a')%>%
  html_text()

date_clean<-gsub('.* - (\\w+ \\d{4}).*', '\\1', latest_data_online)
prompt_for_cat<-paste0("The latest data available from Fair Trading is from ",date_clean,
              ",\n if this is more recent than existing data, consider downloading the new data from:\n
              https://www.fairtrading.nsw.gov.au/about-fair-trading/rental-bond-data")
#Remind that this is the latest data- and check if they want to update
cat(prompt_for_cat)
Sys.sleep(5)
#loop through data and read, then join together----
rent_data_files<-list.files(path='./Data',pattern="\\.xlsx$")
rent_data<-data.frame()

for (i in 1:length(rent_data_files)){
  cat(paste('Reading in file',i,'of',length(rent_data_files),'\n'))
  path_temp<-paste0('./Data/',rent_data_files[i])
  temp_data<-read_excel(path=path_temp, skip=2, col_names=T, col_types= c("date","numeric","text","numeric","numeric"))
  rent_data<-bind_rows(rent_data,temp_data)
  rm(temp_data)
}
#clean, drop unknowns and write into clean csv for further analysis----
rent_data%>%
  clean_names()%>%
  drop_na()%>%
write_csv('./Outputs/Data/all_rents_nsw.csv')

#make monthly time series by dwelling type----
rent_timeseries<-rent_data%>%
  clean_names()%>%
  drop_na()%>%
  mutate(month=as.yearmon(lodgement_date))%>%
  group_by(month,postcode,dwelling_type)%>%
  summarise(average_rent=mean(weekly_rent),
            median_rent=quantile(weekly_rent,0.5),
            rent_25pc=quantile(weekly_rent,0.25),
            rent_75pc=quantile(weekly_rent,0.75))

#write into CSV for further analysis

write_csv(rent_timeseries,'./Outputs/Data/postcode_rent_timeseries.csv')

