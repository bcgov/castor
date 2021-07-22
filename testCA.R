library(raster)
library(data.table)

#Functions------------
getMaxState<-function(x, alphaBeta){
  #Calc HV
  temp<-data.table(treatment = 0:10, age=seq(from = dat[pixelid == x, age], to = (dat[pixelid == x, age] + ph), by = 10))
  temp2<-merge(temp, ylds[yieldid == dat[pixelid == x, yieldid], c("age", "vol")], all.x =TRUE)                 
  temp3<-temp2[is.na(vol), vol:= max(temp2$vol, na.rm =T)][age == dat[pixelid == x, age], vol:=0][, hv:= vol/max(vol, na.rm =T)]
  #Apply Global constraints
  temp3$alphabeta<-append(alphaBeta, lambda, 0) #Need to append at postiion zero for a no harvest state
  #temp3$alphabeta<-append(rep(1:10,0), lambda, 0)
  
  #Calc LSN
  LSN<-lapply(adjacent_list[[x]], function(n){
    temp4<-dat[pixelid == n, c("age", "state")]
    data.table(getLS(temp4$age, temp4$state))
  })
  LSN<-sum(meanlist(LSN))
  
  #Calc LS
  LS<-lapply(0:10, function(s){
    data.table((sum(data.table(getLS(temp3$age[1], s))) + LSN)/20)
  })
  
  out<-cbind(temp3, rbindlist(LS))
  out[,value:=alphabeta*hv+(1-lambda)*V1] #Any weighting here
  return(out[value == max(value),][1]$treatment)
}


getLS<-function(age, treatment){
  numT<-rep(0, 10)
  if(treatment== 0){
    if(age >= 50){
      numT[1:10]<-1
    } else{
      numT[(10-((50-age)/10)):10]<-1
    }
  }else{
    if(treatment<= 5){
      if(age >= 50){
        numT[1:10]<-0
        numT[(treatment+5):10]<-1
        numT[1:treatment]<-1
      }else{
        if((5-(age/10)) >= treatment){
          numT[(treatment + 5):10]<-1
        }else{
          numT[(5-(age/10)):treatment]<-1
        }    
        
      }
    }else{
      if(age >= 50){
        numT[1:treatment]<-1
      }else{
        numT[(5-(age/10)):treatment]<-1
      }
    }
  }
  return(numT)
}

meanlist <- function(list) {
  n <- length(list)
  res <- 0
  for (m in seq(n)) res <- res+list[[m]]
  return(res/n)
}

getAlphaBeta<-function(){
  temp7<-dat[!(state == 0), ][,hrv_yr:= age + state*10][hrv_yr > 100, hrv_yr:= 100]
  temp8<-merge(temp7, ylds, by.x = c("yieldid", "hrv_yr") , by.y = c("yieldid", "age"), all.x = T)[, sum(vol), by = state][V1<= minVol, alpha:=minVol/V1][V1 >= maxVol, beta:=V1/maxVol]
  temp8<-temp8[is.na(alpha), alpha:= 0][is.na(beta), beta:= 0][, const:=alpha-beta]
  penalty<-rep(lambda, 10)
  for(c in 1:nrow(temp8)){
    if(!(temp8[c]$const == 0)){
      penalty[temp8[c]$state]<-lambda + temp8[c]$const
    }
  }
  return(penalty)
}


updateLandscapeValue<-function(alphaBeta){
  #Calc HV
  temp<-dat[,hrv_yr:= age + state*10][hrv_yr > 100, hrv_yr:= 100]
  temp2<-merge(temp, ylds, by.x =c("yieldid", "hrv_yr"), by.y =c("yieldid", "age"), all.x =TRUE)                 
  temp3<-merge(temp2, ylds[, max(vol), by = yieldid], by.x ="yieldid", by.y ="yieldid", all.x =TRUE)
  temp3[, hv:= vol/V1][state == 0, hv:=0]
  
  #Apply Global constraints
  temp3<-merge(temp3, cbind(data.table(state= 0:10), append(alphaBeta, lambda, 0)), by.x = "state", by.y= "state") 
  #temp3<-merge(temp3, cbind(data.table(state= 0:10), append(rep(1:10,0), lambda, 0)), by.x = "state", by.y= "state") 
  
  temp3[,hv1:=hv*V2]
  
  ls<-numeric()
  lsn<-numeric()
  #Calc local neighbourhood
  for (p in 1:nrow(temp3)){
    LSN<-lapply(adjacent_list[[temp3[p]$pixelid]], function(x){
      data.table(getLS(temp3[pixelid == x, ]$age, temp3[pixelid == x, ]$state))
     })
    lsn<-rbind(lsn, sum(meanlist(LSN)))
    ls<-rbind(ls, (sum(data.table(getLS(temp3[p]$age, temp3[p]$state)))))
  }
  temp3[,lsEst:=ls]
  temp3[,lsnEst:=lsn]
  temp3[,value:=hv +(1-lambda)*((lsEst + lsnEst)/20)] #Any weighting here
  return(temp3[, c("pixelid", "value")])
}


#Create a test forest------------
#Generate the forest attributes
dat<-data.table(pixelid= 1:100, yieldid= sample(1:4, 100, replace=T), age = round(sample(0:100, 100, replace=T)/10,0)*10)
ylds<-data.table(yieldid= rep(1:4, each = 10, len = 40), age=rep(1:10, 4)*10)
ylds[yieldid == 1, vol:= round(age*runif(1,0.1) +age,1) ]
ylds[yieldid == 2, vol:= round(age*runif(1,0.1) +age ,1)]
ylds[yieldid == 3, vol:= round(age*runif(1,0.1) +age,1) ]
ylds[yieldid == 4, vol:= round(age*runif(1,0.1) +age,1) ]

#Generate the spatial landscape of the forest
ras <- raster(extent(0, 10, 0, 10),res =1, vals =1)
ras[]<-dat$yieldid
plot(ras)

#Get Adjacency list
adj_table<-data.table(SpaDES.tools::adj(ras, cells= 1:100, directions =8 ,numCell = 100))
adjacent_list<-lapply(1:100, function(x){
  adj_table[to==x, ]$from
})


#Parameters------------
treatments<-0:10
ageThreshold<-50
ph<-100
lambda<-0.5
minVol<-1200
maxVol<-1350

##CA------------
set.seed(1)
dat[,state:=sample(0:10,100, replace = T)] #Randomly assign the state
#dat[,state:=10] #Randomly assign the state

finalPlan<-0 #flag for finishing the algorithum
obj<-as.numeric()
ab<-getAlphaBeta()
k<-0
j<-20
dat$value<-runif(100,0,1) #create a random order


for(i in 1:500){
  dat$p<-runif(100,0,1)
  dat<-dat[order(-p)] #order the cells
  
  if(k > j){
    ab<-getAlphaBeta()
    k<-0
    j<-j-1
    print(ab)
  }
  for (g in 1: nrow(dat)){
    if(dat[g]$state == getMaxState(dat[g]$pixelid, alphaBeta=ab)){
      print(paste0('stand:', dat[g]$pixelid, ' already at max state:', dat[g]$state))
    }else{ #assign the max state
      dat[g]$state <- getMaxState(dat[g]$pixelid, alphaBeta=ab)
      print(paste0('stand:', dat[g]$pixelid, ' changed state to:', dat[g]$state))
      break #go to the next iteration to allow the neighbours to react to this change
    }
    
    if(g == nrow(dat)) {
      finalPlan <-1
      break
    }
  }
  
  if(finalPlan == 1){
    print("last stand")
    dat$value<-NULL
    dat<-merge(dat, updateLandscapeValue(alphaBeta=ab), by.x = "pixelid", by.y = "pixelid") #Allow the value of each pixel to 'react' to any changes in the landscape
    obj<-rbind(obj, sum(dat$value)) # store the value of the objective function
    break
  }
  dat$value<-NULL
  dat<-merge(dat, updateLandscapeValue(alphaBeta=ab), by.x = "pixelid", by.y = "pixelid") #Allow the value of each pixel to 'react' to any changes in the landscape
  obj<-rbind(obj, sum(dat$value)) # store the value of the objective function
  
  print(paste0("interation:", i, ", objective:",sum(dat$value) ))
  k<-k+1
  
}

ras[]<-dat$state
plot(ras)

check<-dat[!(state == 0),]
check<-merge(check, ylds, by.x = c("yieldid", "hrv_yr"), by.y = c("yieldid", "age"))
check[, sum(vol), by = state]
test1<-ras

test<-dat

dat[, state:=0]
dat[pixelid==4, state:=1]
dat[pixelid==7, state:=1]
dat[pixelid==15, state:=2]
dat[pixelid==24, state:=2]
dat[pixelid==9, state:=3]
dat[pixelid==3, state:=3]
dat[pixelid==11, state:=4]
dat[pixelid==25, state:=4]
dat[pixelid==1, state:=5]
dat[pixelid==23, state:=5]
dat[pixelid==2, state:=6]
dat[pixelid==8, state:=6]
dat[pixelid==17, state:=7]
dat[pixelid==6, state:=7]
dat[pixelid==19, state:=8]
dat[pixelid==18, state:=8]
dat[pixelid==12, state:=9]
dat[pixelid==16, state:=9]
dat[pixelid==21, state:=10]
dat[pixelid==14, state:=10]

ab<-getAlphaBeta()

sum(updateLandscapeValue(ab)$value)
