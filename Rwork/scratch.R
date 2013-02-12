  coords<-unique(cbind(NYdata$Longitude,NYdata$Latitude))

summary(NYdata)
dims(NYdata)
dim(NYdata)
NYdata[1:10,]
?spT.Gibbs
library(RJSONIO)
library(RCurl)
source('safetylib/couchUtils.R')
source('safetylib/remoteFiles.R')
?file
rawfile <- file('../../geo_bbox/test/grid/monthly/2009/100/263.json')
firstCut <- fromJSON(rawfile)
lines <- readLines(rawfile)
rawfile <- file('../../geo_bbox/test/grid/monthly/2009/100/263.json')
lines <- readLines(rawfile)
lines
firstCut
properties <- firstCut$features
gridData <- properties$data
gridData
properties


> properties <- firstCut$features

properties <- firstCut$features[[1]]
names(properties)
dim(properties)
properties
gridData <- properties$properties$data
summary(gridData)
data.matrix <- matrix(unlist(gridData[1:12],usenames=FALSE),nrow=12)
data.matrix <- matrix(unlist(gridData[1:12]),usenames=FALSE),nrow=12)
data.matrix <- matrix(unlist(gridData[1:12]),usenames=FALSE,nrow=12)
data.matrix <- matrix(unlist(gridData[1:12]),nrow=12)
data.matrix
data.matrix <- matrix(unlist(gridData[1:12]),byrow=FALSE,nrow=12)
data.matrix
data.matrix <- matrix(unlist(gridData[1:12]),byrow=FALSE,ncol=12)
data.matrix
q()
y
gridData <- properties$properties$data
header <- properties$header
header
length(header)
  ncol = length(header)
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)

gridData
properties$data[[1]]
  gridData <- properties[[1]]$data
  gridData <- properties$data
gridData
  ncol = length(header)
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)

data.matrix
df <- data.frame(data.matrix,names=header)
?data.frame
?matrix
df <- data.frame(data.matrix)
names(df) <- header
df
y
library(sptimer)
library(spTimer)
fileref <- file('../../geo_bbox/test/grid/monthly/2009/100/263.json')
  firstcut <- fromJSON(fileref)

library(RJSONIO)
  firstcut <- fromJSON(fileref)

  properties <- firstCut$features[[1]]$properties

  gridData <- properties$data

  header <- properies$header
  ncol = length(header)

  header <- properties$header
  ncol = length(header)

ncol
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)

names(data.matrix) <- header
data.matrix
colnames(data.matrix) <- header
data.matrix
  colnames(data.matrix) <- header

  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)
  colnames(data.matrix) <- header

data.matrix
as.numeric(data.matri$n)
as.numeric(data.matrix$n)
data.matrix
  df <- data.frame(data.matrix)

df
as.numeric(df.n)
summary(df)
data.matrix <- as.numeric(data.matrix)
data.matrix
  df <- data.frame(as.numeric(data.matrix),names=header)
df
  df <- data.frame(data.matrix,colnames=header)
df
  df <- data.frame(data.matrix)
df
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)

  df <- data.frame(data.matrix,colnames=header)
data.matrix
  df <- data.frame(data.matrix,names=header)
?data.frame
?lapply
sapply(data.matrix,as.numeric)
sapply(data.matrix,as.numeric,simplify=FALSE)
df
  df <- data.frame(data.matrix)

df
summary(df)
df.2 <- lapply(df,as.numeric)
df.2
summary(df.2)
df.2 <- sapply(df,as.numeric)
df.2
summary(df.2)
df
summary(df.2)
df.2 <- sapply(2:17,function(i){return df.2[header[i]]=as.numeric(df[i,])}
df.2 <- data.frame
lapply(2:17,function(i){return df.2[header[i]]=as.numeric(df[i,])}
lapply(2:17,function(i){return df.2[header[i]]=as.numeric(df[i,])})
help())
help()
?
?


grlk;
library(plyr)
?plyr
?ddply
fileref
firstcut
properties
gridData
as.numeric(gridData)
data.matrix <- matrix(as.numeric(unlist(gridData[2:12]),byrow=TRUE,ncol=ncol-1)))
data.matrix <- matrix(as.numeric(unlist(gridData[2:12]),byrow=TRUE,ncol=ncol-1))
data.matrix
gridData
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)

data.matrix
?unlist
gridData
unlist(gridData,recursive=FALSE)
gridData[1]
gridData[[1]]
unlist(gridData[[1]])
df
  df[,3:17] <- apply(df[,3:17],1,as.numeric)
df
summary(df)
  df[,3:17] <- apply(df[,3:17],1,as.numeric)
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)
  colnames(data.matrix) <- header
  df <- data.frame(data.matrix)
  df[,3:17] <- apply(df[,3:17],1,as.numeric)

df
  df$dashts <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')

df
summary(df)
df
  properties <- firstCut$features[[1]]$properties
  gridData <- properties$data
  header <- properties$header
  ncol = length(header)
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)

  colnames(data.matrix) <- header

data.matrix
  df <- data.frame(data.matrix)

df
  df[,3:17] <- apply(df[,3:17],1,as.numeric)
  df$dashts <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')

df
?apply
  df[,3:17] <- apply(df[,3:17],2,as.numeric)
df
  df <- data.frame(data.matrix)

df
  df[,3:17] <- apply(df[,3:17],2,as.numeric)
df
  df$dashts <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')

df
  firstcut <- fromJSON(fileref)
  ## trim it down
  properties <- firstCut$features[[1]]$properties
  gridData <- properties$data
  header <- properties$header
  ncol = length(header)
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)
  colnames(data.matrix) <- header
  df <- data.frame(data.matrix)
  df[,3:17] <- apply(df[,3:17],2,as.numeric)
  df$dashts <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')

df
plot(df$dashts,df$n)
plot(df$dashts,df$n/df$lane_miles)
dev.off())
dev.off()
q()
n
source('./fetchFiles.R')
source('RJSONIO')
library('RJSONIO')
library(RCurl)
couchenv
couchenv[1]=couchenv[5]='127.0.0.1'
couchenv[2]=couchenv[6]='james'
couchenv[3]=couchenv[7]='mgicn0mb3r'
couchenv[4]=5985
couchenv[5]=5984
couchdb = paste("http://",couchenv[1],":",couchenv[4],sep='')
privcouchdb = paste("http://",couchenv[2],":",couchenv[3],"@",couchenv[1],":",couchenv[4],sep='')
localcouchdb = paste("http://",couchenv[5],":",couchenv[8],sep='')
localprivcouchdb = paste("http://",couchenv[6],":",couchenv[7],"@",couchenv[5],":",couchenv[8],sep='')

get.grid.file.from.couch <- function(i,j,start,end,local=TRUE){

  start.date.part <- format(start,"%Y-%m-%d %H:00")
  end.date.part <- format(end,"%Y-%m-%d %H:00")
  
  query=list(
    'startkey'=paste('%22',paste(i,j,start.date.part,sep='_'),'%22',sep=''),
    'endkey'=paste('%22',paste(i,j,end.date.part,sep='_'),'%22',sep='')
    )
  json <- couch.allDocs('carb%2fgrid%2fstate4k' , query=query, local=local)
  return(json)
}

?format
?strptime
st <- strptime("2007-01-01 00:00","%Y-%m-%d %H:%M")
st
et <- strptime("2007-02-01 00:00","%Y-%m-%d %H:%M")
get.grid.file.from.couch(126,160,st,et,FALSE)
result <- get.grid.file.from.couch(129,160,st,et,FALSE)
library(plyr)
default.header =c("ts","freeway","n","hh","not_hh","o","avg_veh_spd","avg_hh_weight","avg_hh_axles","avg_hh_spd","avg_nh_weight","avg_nh_axles","avg_nh_spd","miles","lane_miles","detector_count","detectors")
parseGridRecord <- function(rawjson){
  ## trim it down
  rows = rawjson$rows
  df <- ldply(rows,.fun=function(x){unlist(x$doc$data)[1:16]})
  names(df) <- default.header[1:16]
  df
}

df <- parseGridRecord(result)
df
summary(df)
q()
y
couchenv
summary(df)
library(plyr)
  df[,3:16] <- apply(df[,3:16],2,as.numeric)

library(plyr)
summary(df)
df[,2] <- as.factor(df[,2])
summary(df)
?strptime
?DateTimeClasses
st$sec
st$yday
st$year
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')

summary(df)
library(RJSONIO)
library(RCurl)
result <- get.grid.file.from.couch(130,160,st,et,TRUE)
couchenv
couchenv[5]=couchenv[1]
result <- get.grid.file.from.couch(130,160,st,et,TRUE)
couchenv
couchenv[8]="5984"
result <- get.grid.file.from.couch(130,160,st,et,TRUE)
couchenv
couchdb = paste("http://",couchenv[1],":",couchenv[4],sep='')
privcouchdb = paste("http://",couchenv[2],":",couchenv[3],"@",couchenv[1],":",couchenv[4],sep='')
localcouchdb = paste("http://",couchenv[5],":",couchenv[8],sep='')
localprivcouchdb = paste("http://",couchenv[6],":",couchenv[7],"@",couchenv[5],":",couchenv[8],sep='')

result <- get.grid.file.from.couch(130,160,st,et,TRUE)
result$rows
result$total_rows
result <- get.grid.file.from.couch(130,160,st,et,FALSE)
result$total_rows
length(result$rows)
result <- get.grid.file.from.couch(130,160,st,et,TRUE)
length(result$rows)
parseGridRecord <- function(rawjson){
  ## trim it down
  rows = rawjson$rows
  df <- ldply(rows,.fun=function(x){unlist(x$doc$data)[1:16]})
  names(df) <- default.header[1:16]
  df[,3:16] <- apply(df[,3:16],2,as.numeric)
  df[,2] <- as.factor(df[,2])
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
  df
}

df.130.160 <- parseGridRecord(result)
summary(df.130.160)
summary(df)
  library(spTimer)

df.129.160 <- df
rm(df)
coords <- unique(cbind(c(129,130),c(160,160)))
coords
  post.gp.fit <- spT.Gibbs(formula=o8hrmax~cMAXTMP+WDSP+RH, 
         data=df, model="GP", coords=coords, nItr=5000, nBurn=2000, report=10,

         scale.transform="SQRT")

df <-  rbind(df.129.160,df.130.160)
summary(df)
   post.gp.fit <- spT.Gibbs(formula=o8hrmax~cMAXTMP+WDSP+RH, 
         data=df, model="GP", coords=coords, nItr=5000, nBurn=2000, report=10,       scale.transform="SQRT")

df.month = df.ts2$month
df.month = df$ts2$month
summary(df)
df$day = df$ts2$day
summary(df)
?DateTimeClasses
df$day = df$ts2$mday
summary(df)
df$hour = df$ts2$hour
data(NYgrid)
names(NYgrid)
summary(NYgrid)
NYgrid[1,1:10]
NYgrid[1:10,1:4]
NYgrid[1:10,]
?rbind
df.129.60$icell=129
df.129.160$icell=129
df.129.160$jcell=160
df.130.160$icell=130
df.130.160$jcell=160
df.129.160$s.index=1
df.130.160$s.index=2
df <- rbind(df.129.160,df.130.160)
?DateTimeClasses
df$Year <- df$ts2$year
df$Month <- df$ts2$mon
df$Day <- df$ts2$mday
df$Hour <- df$ts2$hour
   post.gp.fit <- spT.Gibbs(formula=o8hrmax~cMAXTMP+WDSP+RH, 

         data=df, model="GP", coords=coords, nItr=5000, nBurn=2000, report=10,       scale.transform="SQRT")

post.gp.fit <- spT.Gibbs(formula=o8hrmax~cMAXTMP+WDSP+RH, 
         data=df, model="GP", coords=coords, nItr=5000, nBurn=2000, report=10,       scale.transform="SQRT")

names(df)
?plyr
?ddply
df2 <- ddply(df,.(s.index),mutate,monthly_vol=sum(n))
?mutate
?baseball
?baseball
data(baseball)
calculate_monthsum <- function(df){}
calculate_monthsum <- function(df){
mutate(df,
msum = sum(n)
)
}
df2 <- ddply(df,.(s.index),calculate_monthsum)
subdf = df[1:100,]
names(subdf)
mutate(subdf,.(s.index),stot=sum(n))
subdf2 = mutate(subdf,.(s.index),stot=sum(n))
summary(subdf2)
calculate_monthsum <- function(d){mutate(d,.(s.index),stot=sum(n))}
df2 <- ddply(df,)
calculate_monthsum <- function(d){mutate(d,stot=sum(n))}
subdf2 = mutate(subdf,stot=sum(n))
summary(subdf2)
calculate_monthsum <- function(d){mutate(d,stot=sum(n))}
df2 <- ddply(df,.(s.index),calculate_monthsum)
df2 <- ddply(df[,c('n','s.index')],.(s.index),calculate_monthsum)
summary(df2)
df$monthsum = df2$stot
df$hourlyfrac <-  df$n / df$monthsum
post.gp.fit <- spT.Gibbs(formula=hourlyfrac~lane_miles, 

         data=df, model="GP", coords=coords, nItr=5000, nBurn=2000, report=10,       scale.transform="SQRT")

data(NYgrid)
names(NYgrid)
names(NYdata)
plot(post.gp.fit)
dev.off()
library(MBA)
library(fields)
library(maps)
plot(coords,pch=3,col=4,xlab='i_cell',ylab='j_cell')
grid.coords
summary(NYgrid)
dim(NYgrid)
dev.off()
?demo(fields)
library(spatial)
demo(spatial)
demo()
demo(graphics)
dev.off())
dev.off()
summary(volcano)
?combn
?permutation
A <- spam(1:12,3)
A
P <- c(3,1,2)
Q <- c(2,3,1,4)
permutation(A,P,Q)
?rep
?sequence
?seq
?matrix
df.grid = data.frame(days=c(1:31)
)
df.grid
names(df)
df.grid.base <- data.frame(Day=rep(1:31,24),Hour=c(1:24),Year=2007,Month=1,lane_miles=0)
summary(df.grid.base)
dim(df.grid.base)
df.grid <- rbind(rep(df.grid.base,9))
dim(df.grid)
dim(df.grid.base)
df.grid <- rbind(df.grid.base,df.grid.base,df.grid.base,df.grid.base,df.grid.base,df.grid.base,df.grid.base,df.grid.base,df.grid.base)
dim(df.grid)
dim(df.grid.base)
?rep
rep(1:3,times=4)
rep(1:3,times=4,each=1)
rep(1:3,times=4,each=2)
rep(1:3,times=4,each=4)
df.grid.coords=data.frame(rep(128:130,times=24*60),rep(159:161,each=24*60))
24*60
24*31
df.grid.coords=data.frame(rep(128:130,times=24*31),rep(159:161,each=24*31))
dim(df.grid.coords)
744 * 9
df.grid.coords=data.frame(rep(128:130,times=24*31*3),rep(159:161,each=24*31*3))
dim(df.grid.coords)
df.grid <- cbind(df.grid.base,df.grid.coords)
dim(df.grid)
df.grid.coords[1:10,]
df.grid.coords=data.frame(rep(128:130,times=3,each=24*31),rep(159:161,times=3,each=24*31*3))
df.grid.coords[1:10,]
df.grid.coords=data.frame(i_cell=rep(128:130,times=3,each=24*31),j_cell=rep(159:161,times=3,each=24*31*3))
df.grid.coords[1:10,]
df.grid.coords=data.frame(i_cell=rep(128:130,times=3,each=24*31),j_cell=rep(159:161,times=3,each=24*31*3),s.index=rep(1:9,each=24*31))
df.grid.coords[1:10,]
df.grid.predict <- cbind(df.grid.base,df.grid.coords)
dim(df.grid.predict)
df.grid.predict[1:10,]
grid.corrds <- unique(c(128:130),c(159:161))
grid.pred <- predict(post.gp.fit,newcoords=grid.corrds,newdata=df.grid.predict)
grid.corrds
grid.corrds <- unique(cbind(c(128:130),c(159:161)))
grid.corrds
grid.pred <- predict(post.gp.fit,newcoords=grid.corrds,newdata=df.grid.predict)
summary(post.gp.fit)
summary(post.gp.fit)
summary(df2)
summary(df)
df.grid.coords=data.frame(i_cell=rep(c(129,130,128),times=3,each=24*31),j_cell=rep(c(160,161,159),each=3*24*31*3),s.index=rep(c(1,2,3,4,5,6,7,8,9),each=24*31))
drop.index <- df.grid.coords$i_cell==129 & df.grid.coords$j_cell=160
drop.index <- df.grid.coords$i_cell==129 && df.grid.coords$j_cell==160
dim(drop.index)
length(drop.index)
df.grid.coords=data.frame(i_cell=rep(c(129,130,128),times=3,each=24*31),j_cell=rep(c(160,161,159),each=3*24*31*3),s.index=rep(c(1,2,3,4,5,6,7,8,9),each=24*31))
drop.index <- df.grid.coords$i_cell==129 & df.grid.coords$j_cell==160
length(drop.index)
summary(drop.index)
drop.index <- drop.index | df.grid.coords$i_cell==130 & df.grid.coords$j_cell==160
summary(drop.index)
grid.pred <- predict(post.gp.fit,newcoords=grid.corrds,newdata=df.grid.predict)
df.grid.predict <- cbind(df.grid.base,df.grid.coords)
df.grid.predict <- df.grid.predict[drop.index]
df.grid.predict <- cbind(df.grid.base,df.grid.coords)
df.grid.predict <- df.grid.predict[drop.index,]
dim(df.grid.predict)
df.grid.predict <- cbind(df.grid.base,df.grid.coords)
df.grid.predict <- df.grid.predict[!drop.index,]
dim(df.grid.predict)
grid.corrds <- unique(cbind(df.grid.predict$i_cell,df.grid.predict$j_cell)))
grid.corrds <- unique(cbind(df.grid.predict$i_cell,df.grid.predict$j_cell))
grid.corrds
grid.pred <- predict(post.gp.fit,newcoords=grid.corrds,newdata=df.grid.predict)
q())
q()
y
