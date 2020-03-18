require (dplyr)
require (tidyr)
require(ggplot2)

fire.bound<-read.csv("C:\\Work\\caribou\\clus_data\\Fire\\fire_sum_crithab.csv",header=FALSE,col.names=c("area_m2","HERD_NAME","habitat","year"))
head(fire.bound)

Herd_name<-c("Central_Selkirks","Columbia_North","Groundhog", "Monashee", "Purcell_Central", "Purcell_South","South_Selkirks","Wells_Gray_South","Columbia_South","Hart_Ranges","North_Cariboo","Telkwa","Wells_Gray_North","Central_Rockies","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville","Narrow_Lake","Frisby_Boulder","Redrock_Prairie_Creek")
Years<-1919:2018
habitat_types<-c("HEWSR","Matrix","LEWR","LESR","HESR")

##--------------------------------------
##Average area burned over a 30 year moving window for each herd across all habitat types together
##--------------------------------------

Herd_names<-list()
Year_start<-list()
Year_end<-list()
habitat<-list()
mean_area_m2<-list()

for (i in 1:length(Herd_name)){
  
  for(j in 1:length(habitat_types)){
    
    for (k in 1:(length(Years)-30)){
      
     ave_area<-fire.bound %>%
     filter(year<=(Years[k]+30), HERD_NAME==Herd_name[i],habitat==habitat_types[j]) %>%
     summarise(mean(area_m2))

     Herd_names<-append(Herd_names,Herd_name[i])
     Year_start<-append(Year_start,Years[k])
     Year_end<-append(Year_end,Years[k]+30)
     habitat<-append(habitat,habitat_types[j])
     mean_area_m2<-append(mean_area_m2,ave_area)
    }
  }
}

df<-cbind(Herd_names,Year_start,Year_end,habitat,mean_area_m2)
df2<-as.data.frame(df)
df3<-df2 %>% filter(mean_area_m2!="NaN")

df3$Herd_names<-as.character(df3$Herd_names)
df3$Year_start<-as.numeric(df3$Year_start)
df3$Year_end<-as.numeric(df3$Year_end)
df3$habitat<-as.character(df3$habitat)
df3$mean_area_m2<-as.numeric(df3$mean_area_m2)
str(df3)

## create a plot for each herd
for (i in 1:length(Herd_name)){

foo<-df3 %>% filter(Herd_names==Herd_name[i])

plot<-ggplot(foo, aes(x=Year_end, y=mean_area_m2,colour=habitat))
  geom_point(size=3,alpha=0.5) +
  geom_line(alpha=0.2,size=1) +
  ggtitle(Herd_name[i])

nam<-paste("p",i,sep="")
assign(nam,plot)
}

grid_arrange_shared_legend(p1, p2, p3, p4,p5,p6,p7,p8,p9, ncol = 3, nrow = 3)
grid_arrange_shared_legend(p16, p17, p12, p13,p14,p15,p16,p17,p18, ncol = 3, nrow = 3)
 
grid_arrange_shared_legend(p16,p17,p15,p12, ncol=2, nrow=2)

library(gridExtra)
library(grid)


grid_arrange_shared_legend <- function(..., ncol = length(list(...)), nrow = 1, position = c("bottom", "right")) {
  
  plots <- list(...)
  position <- match.arg(position)
  g <- ggplotGrob(plots[[1]] + theme(legend.position = position))$grobs
  legend <- g[[which(sapply(g, function(x) x$name) == "guide-box")]]
  lheight <- sum(legend$height)
  lwidth <- sum(legend$width)
  gl <- lapply(plots, function(x) x + theme(legend.position="none"))
  gl <- c(gl, ncol = ncol, nrow = nrow)
  
  combined <- switch(position,
                     "bottom" = arrangeGrob(do.call(arrangeGrob, gl),
                                            legend,
                                            ncol = 1,
                                            heights = unit.c(unit(1, "npc") - lheight, lheight)),
                     "right" = arrangeGrob(do.call(arrangeGrob, gl),
                                           legend,
                                           ncol = 2,
                                           widths = unit.c(unit(1, "npc") - lwidth, lwidth)))
  
  grid.newpage()
  grid.draw(combined)
  
  # return gtable invisibly
  invisible(combined)
  
}

