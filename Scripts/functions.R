#Author: Dominic Behrens
#Project: NSW Fair Trading Rental Data
#Purpose: Functions for {targets}-ified workflow for NSW Fair Trading Data
#Date: July 2024
#Notes:

#basic options
gc()
rm(list=ls())
options(scipen=999)
Sys.unsetenv(c('http_proxy','https_proxy'))
#helper function to extract all entries in a vector that contain 'lodgements'
filter_lodgements <- function(strings) {
  # Use str_detect to find strings containing 'Lodgements' or 'lodgements'
  filtered_strings <- strings[str_detect(strings, "(?i)lodgements")]
  return(filtered_strings)
}

#function to list all files from NSW fair trading website
#takes month (in string) and year (in numeric) of 

list_lodgement_files <- function(url){
  # Read the webpage and extract the links
  webpage <- read_html(url)
  links <- webpage %>%
    html_nodes("a") %>%
    html_attr("href")
  # Filter the links to include only the ones referring to lodgements
  filtered_links<-filter_lodgements(links)
  filtered_links<-filtered_links[!is.na(filtered_links)]
  file_names<-basename(filtered_links)
  return(file_names)
}

#function to check if any new files are available
check_for_new_files<-function(folder){
  existing_files<-list.files(folder)
  new_files<-list_lodgement_files('https://www.nsw.gov.au/housing-and-construction/rental-forms-surveys-and-data/rental-bond-data')
  missing_files<-new_files%>%
    as.data.frame()%>%
    filter(!.%in%existing_files,
           !str_detect(.,'2023'),
           !str_detect(.,'2022'),
           !str_detect(.,'2021'))
  cat('The following new files are available from NSW Fair Trading.\nThey can be downloaded from https://www.nsw.gov.au/housing-and-construction/rental-forms-surveys-and-data/rental-bond-data \n')
  return(missing_files)
  }

#function to read all .xlsx files in and join together
make_all_rents<-function(file_folder,out_folder){
rent_data_files<-list.files(path=file_folder,pattern="\\.xlsx$")
rent_data<-data.frame()
for (i in 1:length(rent_data_files)){
  cat(paste('Reading in file',i,'of',length(rent_data_files),'\n'))
  path_temp<-paste0('./Data/',rent_data_files[i])
  temp_data<-read_excel(path=path_temp, skip=2, col_names=T, col_types= c("date","numeric","text","numeric","numeric"))
  rent_data<-bind_rows(rent_data,temp_data)
}
rent_data%>%
  clean_names()%>%
  drop_na()%>%
  write_csv(paste0(out_folder,'/all_rents_nsw.csv'))
}

#function to make a monthly timeseries by postcode and dwelling type
make_timeseries<-function(all_rents_file,out_folder){
rent_data<-read.csv(all_rents_file)
rent_data%>%
  clean_names()%>%
  drop_na()%>%
  mutate(month=as.yearmon(lodgement_date))%>%
  group_by(month,postcode,dwelling_type)%>%
  summarise(average_rent=mean(weekly_rent),
            median_rent=quantile(weekly_rent,0.5),
            rent_25pc=quantile(weekly_rent,0.25),
            rent_75pc=quantile(weekly_rent,0.75))%>%
write.csv(paste0(out_folder,'/postcode_timeseries.csv'))
}
