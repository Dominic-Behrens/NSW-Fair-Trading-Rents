#Author: Dominic Behrens
#Project: General Use
#Purpose: Convert Rental Bond Data to LGA and Greater Sydney/Rest of Sydney level. 
#Date: October 2023
#Notes:

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

#read in rental data

rent_data<-read_csv('./Outputs/Data/all_rents_nsw.csv')%>%
  clean_names()


#read in postcode shapefile

postcode_shape<-strayr::read_absmap(area='postcode',year='2021')

#read in LGA shapefile

lga_shape<-lga2021%>%
  filter(state_name_2021=='New South Wales')

#allocate postcodes to LGA based on location of postcode's centroid

postcode_lga_concordance<-postcode_shape%>%
  st_point_on_surface()%>%
  st_intersection(lga_shape)%>%
  select(c('postcode_num_2021','lga_name_2021'))%>%
  rename(postcode=postcode_num_2021)%>%
  st_drop_geometry()


#join to data

lga_rent_data<-rent_data%>%
  left_join(postcode_lga_concordance)
#check errors

problem_postcodes<-lga_rent_data%>%
  filter(is.na(lga_name_2021))
# 200ish rental properties that don't match to a real postcode. Mostly in Canberra (presumably typos)
# or non-geographic postcodes that only have PO boxes. So minor it's worth ignoring. 

# drop these observations

lga_rent_data%<>%drop_na()

#make lga-level time series
lga_rent_timeseries<-lga_rent_data%>%
  mutate(month=as.yearmon(lodgement_date))%>%
  group_by(month,lga_name_2021,dwelling_type)%>%
  summarise(average_rent=mean(weekly_rent),
            median_rent=quantile(weekly_rent,0.5),
            rent_25pc=quantile(weekly_rent,0.25),
            rent_75pc=quantile(weekly_rent,0.75))

#save data

write_csv(lga_rent_timeseries,'./Outputs/Data/lga_rent_timeseries.csv')


gcc_shape<-strayr::read_absmap(area="gcc",year='2021')%>%
  filter(state_name_2021=='New South Wales')
#allocate postcodes to GCC based on location of postcode's centroid

postcode_gcc_concordance<-postcode_shape%>%
  st_point_on_surface()%>%
  st_intersection(gcc_shape)%>%
  select(c('postcode_num_2021','gcc_name_2021'))%>%
  rename(postcode=postcode_num_2021)%>%
  st_drop_geometry()
#join to data

gcc_rent_data<-rent_data%>%
  left_join(postcode_gcc_concordance)%>%
  drop_na()
#make gcc-level time series
gcc_rent_timeseries<-gcc_rent_data%>%
  mutate(month=as.yearmon(lodgement_date))%>%
  group_by(month,gcc_name_2021,dwelling_type)%>%
  summarise(average_rent=mean(weekly_rent),
            median_rent=quantile(weekly_rent,0.5),
            rent_25pc=quantile(weekly_rent,0.25),
            rent_75pc=quantile(weekly_rent,0.75))


#make a chart
gcc_rent_timeseries%>%
  filter(dwelling_type=='F')%>%
ggplot()+
  geom_line(aes(x=month,y=median_rent,colour=gcc_name_2021))+
  theme_minimal()+
  labs(y='Median Weekly Rent, Units',
       x=element_blank(),
       colour='Location')


gcc_rent_timeseries%>%
  filter(dwelling_type=='H')%>%
  ggplot()+
  geom_line(aes(x=month,y=median_rent,colour=gcc_name_2021))+
  theme_minimal()


#save data
write_csv(gcc_rent_timeseries,'./Outputs/Data/gcc_rent_timeseries.csv')


