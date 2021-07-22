#Load in data "data_lightning_trees"
dat_lightning_t<-read.csv(file.choose(), stringsAsFactors = FALSE, strip.white = TRUE, na.strings = c("NA","") )

#Libraries
library(kableExtra)
library(data.table)
library(DBI)
library(RPostgreSQL)
library(dplyr)
library(ggplot2)
library(here)
library(ggpubr)
library(arm)
library(tidyr)
library(AICcmodavg)
library(keyring)
library(caret)
library(pROC)

##We will perform separate loops those with one climate variable, and those with two
zones1<-c("ESSF", "MH", "CMA", "MS", "SBPS", "BWBS", "SBS", "SWB") 
#These are the zones with only one climate variable from previous climate selection models.
zones2<-c("ICH", "CWH",   "PP",  "IMA",  "BG")
#These are the zones with two climate variables from previous climate selection models.

##Select the proportion to test on so that we have a training dataset and a testing data set
filenames<-list()
prop<-0.75

##Create variable lists to be used in the model loop.
variables_all<-c(climate1 = "climate1", proj_height_1 = "proj_height_1", proj_age_1 = "proj_age_1", live_stand_volume_125 = "live_stand_volume_125", slope = "slope", aspect = "aspect", vegtype = "vegtype") 
vars.clim<-c("climate1")
vars.oth<-c("proj_height_1", "proj_age_1", "live_stand_volume_125", "slope", "aspect", "vegtype") 

inputs.me <- c(vars.clim, vars.oth)

##Create a list of all possible two-way interactions between all the variables.

#get the names of all possible two-way interactions
twoway.ints <- NULL
for (i in 1:(length(inputs.me)-1)) {
  for (j in (i+1):length(inputs.me)) {
     twoway.ints <- cbind(twoway.ints, paste(inputs.me[i], inputs.me[j], sep=":"))
  }
}
twoway.ints

#Create function to determine Powerset for any vector of variable names
powerSet <- function(x) {
   z.list <- NULL
   for(i in 1:length(x)) {
      z.list <- append(z.list, combn(x, m=i, simplify=F))
   }    
   return(z.list)
}

#complete list of models using non-cimate vars
mods.me.tmp <- powerSet(vars.oth) 
#add climate vars to all of the above
mods.me <- list()
for (i in 1: length(mods.me.tmp)) {
   mods.me[[i]] <- c(vars.clim, mods.me.tmp[[i]])
}

#complete list of two-way interactions
mods.twoway <- powerSet(twoway.ints)


#Finding models in mods.me that accommodate/allow interaction terms in each mods.twoway to be added
#should really use lapply instead of loop but being lazy
mods.inter <- list()
counter <- 0
for (i in 1: length(mods.twoway)) {
   s1 <- unique(unlist( strsplit(mods.twoway[[i]], split=':', fixed=TRUE) ) )
   for (j in 1: length(mods.me)) {
      if (all(s1 %in% mods.me[[j]])==TRUE) {
        counter <- counter + 1
        both <-  c(mods.me[[j]], mods.twoway[[i]])
        mods.inter[[counter]] <- both
      }
   }
}


#the list of all possible model RHSs. 
all.poss.mods <- c(1, mods.me, mods.inter)
all.poss.mods
length(all.poss.mods)

#Check
#paste(all.poss.mods[[36]], collapse=" + ") #assessing the 36th element for the test

###Subsetting data by those zones associated with one climate var
dat2 <- dat_lightning_t[dat_lightning_t$zone %in% zones1,]

##Selecting a subset of columns
model_dat<- dat2 %>% dplyr::select(fire_pres, fire_veg, !!variables_all)

# Creating training and testing datasets to assess how well models actually predicts the data e.g. AUC
# These datasets are fixed and should not change among the different models
# ...although you could do something like a k-fold partition later once this works properly
trainIndex <- createDataPartition(model_dat$fire_veg, p = prop, list = FALSE, times = 1)
dat1 <- model_dat[ trainIndex,]
Valid <- model_dat[-trainIndex,]

#Create frame of AIC table
# summary table
table.glm.bec.models <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.bec.models) <- c ("Zone", "Variable", "AIC", "AUC")

#------------keeping only the first 20 models for testing purposes---------;
all.poss.mods20 <- all.poss.mods[1:20]
   
#mods.fit <- list()
#for (i in 1: length(all.poss.mods)) {
#   rhs <- paste(all.poss.mods[[i]], collapse=" + ")
#   form <- as.formula(paste("fire_pres ~", rhs))
#   mods.fit[[i]] <- summary(glm(form, family=binomial, data=dat1))
#   #print(form)
#}

#More Efficient  
#Function to fit model and extract summary
big.mod <- function(mods.in, df.train, df.test, dep.var="fire_pres") {
   rhs <- paste(mods.in, collapse=" + ")
   form <- as.formula(paste(noquote(dep.var), " ~", rhs))
   mod.fit <- glm(form, family=binomial, data=df.train)
   mod.stuff <- summary(mod.fit)
   mod.aic <- extractAIC(mod.fit)
   mod.valid <- predict.glm(mod.fit, newdata=df.test, type="response")
   roc_obj <- roc(df.test[,dep.var], mod.valid)
   mod.auc <- auc(roc_obj)
   return(list(mod.stuff, mod.aic, mod.auc))
}

mods.fit <- lapply(all.poss.mods20, big.mod, df.train=dat1, df.test=Valid)


#----Pete stoppped here-----------;



  
  table.glm.bec.models[i+1,1]<-zones1[h]
  table.glm.bec.models[i+1,2]<-all.poss.mods[i]
  table.glm.bec.models[i+1,3]<-extractAIC(model1)[2]
  
  # lets look at fit of the Valid (validation) dataset
  Valid$model1_predict <- predict.glm(model1,newdata = Valid,type="response")
  roc_obj <- roc(Valid$fire_pres, Valid$model1_predict)
  auc(roc_obj)
  table.glm.bec.models[i+1,4]<-auc(roc_obj)
  
}


#Need to determine how to get full factoral of variables_0 and variables
table.glm.climate1<-table.glm.bec.models %>% drop_na(AIC)


#assign file names to the work
nam1<-paste("AIC",zones1[h],"run",g,sep="_") #defining the name
assign(nam1,table.glm.bec.models)
filenames<-append(filenames,nam1)
}
}