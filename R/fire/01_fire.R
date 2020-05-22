# Copyright 2020 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

#=================================
#  Script Name: 01_fire.R
#  Script Version: 1.0
#  Script Purpose: Script exploring/analysing average areas burned over a 40 yrs moving window in the caribou herd ranges 
#           
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#   
#  Script Date: 19 March 2020
#  R Version: 
#  R Packages: 
#  Data: 
#=================================


require (dplyr)
require (tidyr)
require(ggplot2)
options(scipen=999)

# read in fire data
fire.bound<-read.csv("C:\\Work\\caribou\\clus_data\\Fire\\fire_sum_crithab.csv",header=FALSE,col.names=c("area_m2","HERD_NAME","habitat","year"))
head(fire.bound)
fire.bound$Herd_name<-fire.bound$HERD_NAME

fire.bound$Herd_name<-sub("_", " ", fire.bound$Herd_name) # this replaces the first instance of "_" it finds with " "
fire.bound$Herd_name<-sub("_", " ", fire.bound$Herd_name) # this replaces the 2nd instance

fire.bound<- fire.bound %>% mutate(Herd_name1 = if_else(Herd_name == "Itcha Ilgachuz","Itcha-Ilgachuz", Herd_name))

fire.bound<- data.table(fire.bound)
fire.bound[, herd_bounds:= paste(Herd_name1, habitat, sep=" ")]


fire.bound.dt<-fire.bound %>% select(c("herd_bounds","year","area_m2"))

# write data to the virtual machine
#conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='206.12.91.188', dbname = 'clus', port='5432', user='appuser', password='sHcL5w9RTn8ZN3kc')

#dbWriteTable(conn,c("public","fire"),fire.bound, overwrite=T,row.names = FALSE)

#dbDisconnect(conn)

Herd_name<-c("Central_Selkirks","Columbia_North","Groundhog", "Monashee", "Purcell_Central", "Purcell_South","South_Selkirks","Wells_Gray_South","Columbia_South","Hart_Ranges","North_Cariboo","Telkwa","Wells_Gray_North","Central_Rockies","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville","Narrow_Lake","Frisby_Boulder","Redrock_Prairie_Creek")
Years<-1919:2018
habitat_types<-c("HEWSR","Matrix","LEWR","LESR","HESR")

##--------------------------------------
##Creating loop to calculate the area burned over a 40 year moving window for each herd across each habitat type 
##--------------------------------------
window_size<-40

Herd_names<-list()
Year_start<-list()
Year_end<-list()
habitat<-list()
cummulative_area_m2<-list()
mean_area_m2<-list()

Fire_results_cummulative <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (Fire_results_cummulative) <- c ("herd_name","habitat","year", "cummulative_area","cummulative_area_proportion" )

for (i in 1:length(Herd_name)){
  
  for(j in 1:length(habitat_types)){
    
    for (k in 1:(length(Years)-window_size)){
      
     ave_area1<-fire.bound %>%
     filter(year<=(Years[k]+window_size), HERD_NAME==Herd_name[i],habitat==habitat_types[j])
     ave_area<-mean(ave_area1$area_m2)
     
     cummulative_area<-fire.bound %>%
       filter(year<=(Years[k]+window_size), HERD_NAME==Herd_name[i],habitat==habitat_types[j]) 
     cummulative_area_summed<-sum(cummulative_area$area_m2)
     
     
     
    # 40 yr movingwindow dataset
     Herd_names<-append(Herd_names,Herd_name[i])
     Year_start<-append(Year_start,Years[k])
     Year_end<-append(Year_end,Years[k]+window_size)
     habitat<-append(habitat,habitat_types[j])
     mean_area_m2<-append(mean_area_m2,ave_area)
     cummulative_area_m2<-append(cummulative_area_m2,cummulative_area_summed)
  
    }
  }
}

df<-cbind(Herd_names,Year_start,Year_end,habitat,mean_area_m2,cummulative_area_m2)
df2<-as.data.frame(df)
df3<-df2 %>% filter(mean_area_m2!="NaN")

df3$Herd_names<-as.character(df3$Herd_names)
df3$Year_start<-as.numeric(df3$Year_start)
df3$Year_end<-as.numeric(df3$Year_end)
df3$habitat<-as.character(df3$habitat)
df3$mean_area_m2<-as.numeric(df3$mean_area_m2)
df3$cummulative_area_m2<-as.numeric(df3$cummulative_area_m2)
str(df3)

##------------------------------------------
## Creating a table of results from a very simple linear model
##------------------------------------------
Herd_name_tab<-list()
habitat_tab<-list()
intercept<-list()
slope<-list()
r2<-list()

for(i in 1:length(Herd_name)){
  for (j in 1:length(habitat_types)){
    
  x<-df3 %>% filter(Herd_names==Herd_name[i],habitat==habitat_types[j])
  if(dim(x)[1]>0) {

  m <- lm(cummulative_area_m2 ~ Year_end, x);
  intercept_val = format(unname(coef(m)[1]), digits = 2)
  slope_val = format(unname(coef(m)[2]), digits = 2)
  r2_val = format(summary(m)$r.squared, digits = 3)
  
  Herd_name_tab<-append(Herd_name_tab,Herd_name[i])
  habitat_tab<-append(habitat_tab, habitat_types[j])
  intercept<-append(intercept,intercept_val)
  slope<-append(slope, slope_val)
  r2<-append(r2,r2_val)
  }
  }
}

lm_table<-cbind(Herd_name_tab,habitat_tab,intercept,slope,r2)
lm_table<-as.data.frame(lm_table)
lm_table$Herd_name_tab<-as.character(lm_table$Herd_name_tab)
lm_table$habitat_tab<-as.character(lm_table$habitat_tab)
lm_table$intercept<-as.numeric(lm_table$intercept)
lm_table$slope<-as.numeric(lm_table$slope)
lm_table$r2<-as.numeric(lm_table$r2)

str(lm_table)
write.csv(lm_table, "C:\\Work\\caribou\\clus_data\\Fire\\Results\\lm_table_results.csv")


##-------------------------------
## create a plot of the average area burned for each herd and habitat type
##-------------------------------

for (i in 1:length(Herd_name)){

foo<-df3 %>% filter(Herd_names==Herd_name[i])
foo_line<-lm_table %>% filter(Herd_name_tab==Herd_name[i],habitat_tab=="Matrix")
foo_line2<-lm_table %>% filter(Herd_name_tab==Herd_name[i],habitat_tab=="HEWSR")

plot<-ggplot(foo, aes(x=Year_end, y=cummulative_area_m2,colour=habitat)) +
  geom_point(size=3,alpha=0.5) +
  geom_line(alpha=0.2,size=1) +
  geom_abline(data=foo_line,aes(slope=slope,intercept=intercept,colour="Matrix"))+
  #geom_abline(data=foo_line2,aes(slope=slope,intercept=intercept,colour='HEWSR'))+
  ggtitle(Herd_name[i])

nam<-paste("p",i,sep="")
assign(nam,plot)
}

#making a multipanel plot to look at multiple plots together. This depends on a function which is provided at the bottom of this script
multiplot(p1, p2, p3, p4,p5,p6, cols=2) 
multiplot(p7,p8,p9,p10, p11, p12, cols=2)
multiplot(p13,p14,p15,p16,p17,p18,cols=2)
multiplot(p19, p20, p21, cols=2)


##-----------------------------------------------------------
## look at actual area burned number versus the average area burned across 40 yrs and plot these together 
##-----------------------------------------------------------

fire_area<-fire.bound #%>%
  #filter(habitat=="Matrix")
fire_area$type<-"orig"


fire_ave_area<-df3 %>%
  select(mean_area_m2,Herd_names,habitat,Year_end) #%>%
  #filter(Herd_names=="Central_Selkirks",habitat=="Matrix")

fire_ave_area2<-fire_ave_area %>%  rename(area_m2=mean_area_m2,
         year=Year_end,
         HERD_NAME=Herd_names) 
fire_ave_area2$type<-"ave"
  

df4<-rbind(fire_area,fire_ave_area2)

## create a plot for each herd
for (i in 1:length(Herd_name)){
  
  foo<-df4 %>% filter(HERD_NAME==Herd_name[i])
  
  plot<-ggplot(foo, aes(x=year, y=area_m2,colour=habitat,shape=type)) +
    geom_point(size=3,alpha=0.5) +
    geom_line(alpha=0.2,size=1) +
    ggtitle(Herd_name[i])
  
  nam<-paste("p",i,sep="")
  assign(nam,plot)
}

multiplot(p1, p2, p3, p4, cols=2)
multiplot(p5, p6, p7, p8, cols=2)
multiplot(p9, p10, p11, p12, cols=2)
multiplot(p13,p14,p15,p16,cols=2)



##----------------------------------------
# Multiple plot function
##----------------------------------------
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}
