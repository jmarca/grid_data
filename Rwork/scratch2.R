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
library(sptimeR)
library(spTimer)
data(DataFit)
summary(DataFit)
data(DataValPred)
summary(DataValPred)
dim(DataValPred)
dim(DataFit)
DataFit[1:10,]
DataValPred[1:10,]
summary(as.factor(DataFit[,1:3]))
summary(as.factor(DataFit[,c('s.index','Longitude','Latitude')]))
library(RJSONIO)
library(RCurl)

source('safetylib/couchUtils.R')
library(plyr)
couchenv[1]=couchenv[5]='127.0.0.1'
couchenv[2]=couchenv[6]='james'
couchenv[3]=couchenv[7]='mgicn0mb3r'

couchenv[4]=5985

couchenv[8]=5984
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

library(plyr)
default.header =c("ts","freeway","n","hh","not_hh","o","avg_veh_spd","avg_hh_weight","avg_hh_axles","avg_hh_spd","avg_nh_weight","avg_nh_axles","avg_nh_spd","miles","lane_miles","detector_count","detectors")
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

result <- get.grid.file.from.couch(130,160,st,et,TRUE)

st <- strptime("2007-01-01 00:00","%Y-%m-%d %H:%M")
st
et <- strptime("2007-02-01 00:00","%Y-%m-%d %H:%M")

result <- get.grid.file.from.couch(130,160,st,et,TRUE)

df.130.160 <- parseGridRecord(result)
result <- get.grid.file.from.couch(129,160,st,et,TRUE)
get.grid.file.from.couch <- function(i,j,start,end,local=TRUE){
get.grid.file.from.couch <- function(i,j,start,end,local=TRUE){
;
get.grid.file.from.couch <- function(i,j,start,end,local=TRUE){
get.grid.file.from.couch <- function(i,j,start,end,local=TRUE){
}
}
}}}}}}}}}}}}
result <- get.grid.file.from.couch(129,160,st,et,TRUE)
df.129.160 <- parseGridRecord(result)
summary(df.129.160160)
summary(df.129.160)
time.data<-spT.time(t.series=31,segment=2)
time.data
summary(time.data)


data(NYgrid)
dim(NYgrid)
summary(NYgrid)
data(NYdata)
summary(NYdata)
dim(NYdata)
   n <- 12*12 # say, sites
   Longitude<-seq(0,1000,by=1000/(12-1))
   Latitude<-seq(0,1000,by=1000/(12-1))
   long.lat<-expand.grid(Longitude,Latitude)

long.lat
   n <- 12*12 # say, sites
   Longitude<-seq(1,3,by=1000/(12-1))
   Latitude<-seq(1,3,by=1000/(12-1))
   long.lat<-expand.grid(Longitude,Latitude)
long.lat
   Latitude<-seq(1,3,by=3/(12-1))
   Longitude<-seq(1,3,by=3/(12-1))
   long.lat<-expand.grid(Longitude,Latitude)
long.lat
   plot(long.lat,xlab="Longitude",ylab="Latitude",pch=3,col=4)

dev.off()
   knots.coords<-spT.grid.coords(Longitude=c(125,10),Latitude=c(155,10),by=c(10,10))
plot(knots.coords)
   Longitude<-seq(,by=1000/(55-1))
   Latitude<-seq(0,1000,by=1000/(55-1))
   long.lat<-expand.grid(Longitude,Latitude)


c(125,10)
?spT.grid.coords
spT.grid.coords
   knots.coords<-spT.grid.coords(Longitude=c(135,125),Latitude=c(165,155),by=c(10,10))
plot(knots.coords)
lon <- c(129,130)
lat <- c(160,160)
lon.lat <- expand.grid(lon,lat)
lon.lat
   spT.check.locations(fit.locations=as.matrix(long.lat),pred.locations=knots.coords,method="euclidean",tol=1.5)

points(lon.lat,pch=19,col=2)
n <- 2
   site<-data.frame(s.index=1:n,Longitude=lon.lat[,1],Latitude=lon.lat[,2])
site
n
lon.lat
lat <- 160
lon.lat <- expand.grid(lon,lat)
lon.lat
   site<-data.frame(s.index=1:n,Longitude=lon.lat[,1],Latitude=lon.lat[,2])
site
   r <- 1 # year
   T<- 365 # day
   N<-n*r*T

N
r
T
H <- 24
   N<-n*r*T*H
T <- 31
   N<-n*r*T*H
N
   dat1<-matrix(NA,n*r*T*H,5)
   dat1[,1]<-sort(rep(1:n,r*T*H))
   dat1[,2]<-sort(rep(1:r,r*T))
   dat1[,3]<-sort(rep(1:r,r*T))
   dat1[,1]<-sort(rep(1:n,r*T*H))
   dat1<-matrix(NA,n*r*T*H,5)
   dat1[,1]<-sort(rep(1:n,r*T*H))
   dat1[,1]<-sort(rep(1:n,T*H))
   dat1[,1]<-sort(rep(1:n,H))
   dat1<-matrix(NA,n*r*T*H,5)
   dat1[,1]<-sort(rep(1:n,r*T*H))
   dat1[,2]<-sort(rep(1:r,T*H))
   dat1[,3]<-sort(rep(1:r*T,H))
   dat1[,4]<-1:H
   dimnames(dat1)[[2]]<-c("s.index","year","day","hour","y")
dat1 <- as.data.frame(dat1)
summary(dat1)
   dat1<-matrix(NA,n*r*T*H,5)
   dat1[,1]<-sort(rep(1:n,r*T*H))
n
r
dat1[,2] <- 2007
  sort(rep(1:r*T,H))
1:31
?sort
H
   dat1[,3]<-sort(rep(1:r*T,H*T))
summary(dat1)
?rep
  sort(rep(1:r*T,H*T))
  sort(rep(c(1:r*T),H*T))
   dat1[,1]<-sort(rep(1:n,r*T*H))[1:10]
   dat1[,1]<-sort(rep(1:n,r*T*H))[1]
   sort(rep(1:n,r*T*H))[1:10]
   dat1<-matrix(NA,n*r*T*H,5)
   dat1[,1]<-sort(rep(1:n,r*T*H))
summary(dat1)
T
   dat1[,2]<-2007
   dat1[,1]<-sort(rep(1:T,r*H))
summary(dat1)
   dat1[,1]<-sort(rep(1:n,r*T*H))
   dat1[,3]<-sort(rep(1:T,r*H))
summary(dat1)
   dat1[,4]<-sort(rep(1:H,r*T))
summary(dat1)
dat1[dat1[,1]==1,5] <- df.129.160$n
dim(dat1[dat1[,1]==1,5])
   dimnames(dat1)[[2]]<-c("s.index","year","day","hour","y")
   dat1<-as.data.frame(dat1)

dim(dat1)
dim(df.129.160)
31*24
summary(df.129.160)
site
summary(df.130.160)
result <- get.grid.file.from.couch(131,160,st,et,TRUE)
df.131.160 <- parseGridRecord(result)
summary(df.130.160)
summary(df.131.160$ts2)
> unique.ts <- unique(rbind(df.131.160$ts,df.130.160$ts,df.129.160$ts)
unique.ts <- unique(rbind(df.131.160$ts,df.130.160$ts,df.129.160$ts))
unique.ts <- unique(c(df.131.160$ts2,df.130.160$ts2,df.129.160$ts2))
length(unique.ts)
dim(df.131.160)
dim(df.130.160)
dim(df.129.160)
unique.ts[745]
unique.ts[746]
unique.ts <- sort(unique.ts)
unique.ts[745]
env()
env
unique.ts[745]$mon
unique.ts[745]$day
unique.ts[745]$mday
?TZ
Sys.timezone())
Sys.timezone()
Sys.timezone('UTC')
?POSIXlt
unique.ts[1]$tzone
unique.ts[1]
df$ts2[1]
df.129.160$ts2[1]
ts.test <- df.129.160$ts2[1]
ts.test
ts.test <- df.129.160$ts2
?unique
?unique.POSIXlt
?unique.POSIXlt
unique.POSIXlt
?duplicated
ts.u <- c(df.129.160$ts2,df.130.160$ts2,df.131.160$ts2)
ts.u[1]
ts.u <- rbind(df.129.160$ts2,df.130.160$ts2,df.131.160$ts2)
ts.u[1]
ts.u <- merge(df.129.160$ts2,df.130.160$ts2,df.131.160$ts2)
ts.u <- merge(df.129.160$ts2,df.130.160$ts2,df.131.160$ts2,by(ts)
)
ts.u <- merge(df.129.160$ts2,df.130.160$ts2,df.131.160$ts2,by(1))
ts.u <- merge(df.129.160$ts2,df.130.160$ts2,df.131.160$ts2,by('ts'))
?c
?rbind
ts.u <- rbind(df.129.160,df.130.160,df.131.160)
ts.u[1,1]
ts.un <- unique(ts.u[,1])
ts.un[1]
sort(ts.un)
ts.un <- sort(unique(ts.u[,1]))
%% that was good
dat.mrg <- matrix(NA,length(ts.un)*3,5)
N <- length(ts.un)
n <- 3
dat.mrg[,1] <- sort(rep(1:n,N)
)
summary(dat.mrg)
dat.mrg[,2] <- rep(ts.un$year,n)
ts.un[1]
ts.un[1]$year
ts.u <- rbind(df.129.160,df.130.160,df.131.160)
dim(ts.u)
ts.u$ts2[1]
ts.un <- sort(unique(ts.u$ts2))
ts.un[1]
ts.un[1]$year
%% no, this one was the good one!
dat.mrg[,2] <- rep(ts.un$year,n)
summary(dat.mrg)
dat.mrg[,2] <- rep(ts.un$year,n)+1900
summary(dat.mrg)
dat.mrg[,3] <- rep(ts.un$mon,n)
summary(dat.mrg)
dat.mrg[,4] <- rep(ts.un$mday,n)
summary(dat.mrg)
dat.mrg[,5] <- rep(ts.un$hour,n)
summary(dat.mrg)
?merge
df.129.160$s.idx = 1
df.130.160$s.idx = 2
df.131.160$s.idx = 3
dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour')
dat.mrg <-  as.data.frame(dat.mrg)
dat.mrg <- merge(dat.mrg,df.129.160,by=c('ts2','site'))
dat.mrg$ts2 <- rep(ts.un,n)
dat.mrg <- merge(dat.mrg,df.129.160,by=c('ts2','s.idx'))
dat.mrg <- merge(dat.mrg,df.130.160,by=c('ts2','s.idx'))
dat.mrg <- merge(dat.mrg,df.131.160,by=c('ts2','s.idx'))
summary(dat.mrg)
?merge
dim(dat.mrg)
dat.mrg[,1] <- sort(rep(1:n,N))
dat.mrg <- matrix(NA,length(ts.un)*3,6)
dat.mrg[,1] <- sort(rep(1:n,N))
dat.mrg[,2] <- rep(ts.un$year,n)+1900
dat.mrg[,3] <- rep(ts.un$mon,n)
dat.mrg[,4] <- rep(ts.un$mday,n)
dat.mrg[,5] <- rep(ts.un$hour,n)
dat.mrg[,6] <- rep(ts.un,n)
dim(dat.mrg)
dim(ts.un)
length(ts.un)
745*3
length(dat.mrg[,6])
length(rep(ts.un,n))
dat.mrg[,6] <- rep(ts.un,n)
dat.mrg[,6] <- ts.un
?DateTimeClasses
dat.mrg[,6] <- as.POSIXct(ts.un)
dat.mrg[1,]
dat.mrg[1:10,]
  df.129.160$tsct <- as.POSIXct(df.129.160$ts2)
  df.130.160$tsct <- as.POSIXct(df.130.160$ts2)
  df.131.160$tsct <- as.POSIXct(df.131.160$ts2)
dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour','tsct')
df.mrg <-  as.data.frame(dat.mrg)
?merge
df.mrg <- merge(df.mrg,df.129.160,all=TRUE,by=c("s.idx","tsct"))
summary(df.mrg)
df.mrg <- merge(df.mrg,df.130.160,all=TRUE,by=c("s.idx","tsct"))
df.mrg <- merge(df.mrg,df.131.160,all=TRUE,by=c("s.idx","tsct"))
summary(df.mrg)
df.mrg <-  as.data.frame(dat.mrg)
?merge
df.mrg <- merge(df.mrg,rbind(df.129.160,df.130.160,df.131.160),all=TRUE,by=c("s.idx","tsct"))
summary(df.mrg)
spT.grid.coords
   coords<-as.matrix(unique(cbind(c(129,130,131),c(160))))
coords
df.mrg$Latitude=160
df.mrg$Longitude=129
df.mrg[df.mrg$s.idx==2,'Longitude'] <- 130
df.mrg[df.mrg$s.idx==3,'Longitude'] <- 131
summary(df.mrg$Longitude)
post.gp.fit <- spT.Gibbs(formula=n~1,data=df.mrg,model="GP",coords=coords,distance.method="euclidean",nItr=5000,nBurn=1000,report=10,scale.transform="SQRT")
lon.lat
   knots.coords<-spT.grid.coords(Longitude=c(135,125),Latitude=c(165,155),by=c(10,10))
knots.coords
pred.sites <- data.frame(s.index=1:100,Longitude=knots.coords[,1],Latitude=knots.coords[,2])
n.pred <- 100
dat.mrg <- matrix(NA,length(ts.un)*n,6)
 dat.mrg[,1] <- sort(rep(1:n,N))
 dat.mrg[,2] <- rep(ts.un$year,n)+1900
 dat.mrg[,3] <- rep(ts.un$mon,n)
 dat.mrg[,4] <- rep(ts.un$mday,n)
 dat.mrg[,5] <- rep(ts.un$hour,n)

 names(site)
dim(site)
dat.pred <- merge(dat.mrg,site,by=c("s.index"),all.x=TRUE)
names(site) <- c("s.idx" ,  "Longitude", "Latitude" )
dat.pred <- merge(dat.mrg,site,by=c("s.idx"),all.x=TRUE)
dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour','n')
dat.pred <- merge(dat.mrg,site,by=c("s.idx"),all.x=TRUE)
dim(dat.pred)
dim(dat.mrg)
n
N
n.pred
dat.mrg <- matrix(NA,length(ts.un)*n.pred,6)
  dat.mrg[,1] <- sort(rep(1:n.pred,N))
  dat.mrg[,2] <- rep(ts.un$year,n.pred)+1900
  dat.mrg[,3] <- rep(ts.un$mon,n.pred)
  dat.mrg[,4] <- rep(ts.un$mday,n.pred)
 dat.mrg[,5] <- rep(ts.un$hour,n.pred)
dim(dat.mrg)
dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour','n')
dat.pred <- merge(dat.mrg,site,by=c("s.idx"),all.x=TRUE)
dim(dat.mrg)
dim(dat.pred)
summary(post.gp.fit)
post.gp.fit
    grid.coords<-unique(cbind(dat.pred$Longitude,dat.pred$Latitude))
grid.pred<-predict(post.gp.fit,newcoords=grid.coords,newdata=dat.pred)
data.pred.small <- dat.pred[dat.pred$s.idx <4,]
dim(data.pred.small)
    grid.coords<-unique(cbind(data.pred.small$Longitude,data.pred.small$Latitude))
grid.pred<-predict(post.gp.fit,newcoords=grid.coords,newdata=data.pred.small)
grid.coords
    grid.coords<-unique(cbind(dat.pred$Longitude,dat.pred$Latitude))
grid.coords
site
pred.sites <- data.frame(s.index=1:100,Longitude=knots.coords[,1],Latitude=knots.coords[,2])
pred.sites
dat.mrg <- matrix(NA,length(ts.un)*n.pred,6)
  dat.mrg[,1] <- sort(rep(1:n.pred,N))
  dat.mrg[,2] <- rep(ts.un$year,n.pred)+1900
  dat.mrg[,3] <- rep(ts.un$mon,n.pred)
  dat.mrg[,4] <- rep(ts.un$mday,n.pred)
 dat.mrg[,5] <- rep(ts.un$hour,n.pred)
dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour','n')
df.pred <- merge(dat.mrg,pred.sites,by=c("s.idx"),all.x=TRUE)
dimnames(pred.sites)
dim.names(pred.sites[[2]]) <- c("s.idx" ,  "Longitude", "Latitude" )
dimnames(pred.sites[[2]]) <- c("s.idx" ,  "Longitude", "Latitude" )
names(pred.sites)
names(pred.sites) <- c("s.idx" ,  "Longitude", "Latitude" )
names(pred.sites)
df.pred <- merge(dat.mrg,pred.sites,by=c("s.idx"),all.x=TRUE)
grid.coords<-unique(cbind(dat.pred$Longitude,dat.pred$Latitude))
grid.coords<-unique(cbind(df.pred$Longitude,df.pred$Latitude))
dim(grid.coords)
grid.pred<-predict(post.gp.fit,newcoords=grid.coords,newdata=df.pred)
q()
y
problem.sites <-  sort(unique(c(45,46,54,55,56,57,64,65,66,67,75,76,35,36,44,45,46,47,54,55,56,57,65,66,25,26,34,35,36,37,44,45,46,47,55,56)))
## 25 26 34 35 36 37 44 45 46 47 54 55 56 57 64 65 66 67 75 76
filter <- is.element(df.pred$s.idx,problem.sites)
df.pred <- df.pred[!filter,]
## still fails
current.sites <- sort(unique(df.pred$s.idx))
more.drop <- rep(1)


keep.sites <- current.sites[seq(from=1,to=length(current.sites),by=4)]
filter <- is.element(df.pred$s.idx,keep.sites)
df.pred <- df.pred[filter,]
grid.coords<-unique(cbind(df.pred$Longitude,df.pred$Latitude))
grid.pred<-predict(post.gp.fit,newcoords=grid.coords,newdata=df.pred)
