#Author: Dominic Behrens
#Project: NSW Fair Trading Rental Data
#Purpose: Functions for {targets}-ified workflow for NSW Fair Trading Data
#Date: July 2024
#Notes:

#load and install required packages
if(!require("pacman", character.only = T)) install.packages("pacman")

pacman::p_load(
  tidyverse,
  magrittr, 
  readxl,  
  janitor,
  lubridate,
  sf,
  tmap
)

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
  
  base_files<-basename(filtered_links)
  return(base_files)
}

download_fil

june_24<-download.file('https://www.nsw.gov.au/sites/default/files/noindex/2024-07/rental-bond-lodgements-june-2024.xlsx',
                       destfile='./Data/rental-bond-lodgements-june-2024.xlsx')
