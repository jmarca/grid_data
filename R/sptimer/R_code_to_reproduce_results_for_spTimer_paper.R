
################### Section 4: Simulation study ######################


## Section 4: code for Figure 1(a) (simulation) ##

   library("spTimer")
   n <- 12*12 # say, sites
   Longitude<-seq(0,1000,by=1000/(12-1))
   Latitude<-seq(0,1000,by=1000/(12-1))
   long.lat<-expand.grid(Longitude,Latitude)
   plot(long.lat,xlab="Longitude",ylab="Latitude",pch=3,col=4)

## Section 4: code for Figure 1(b) (simulation) ##

   library("spTimer")
   n <- 55*55 # say, sites
   Longitude<-seq(0,1000,by=1000/(55-1))
   Latitude<-seq(0,1000,by=1000/(55-1))
   long.lat<-expand.grid(Longitude,Latitude)
   knots.coords<-spT.grid.coords(Longitude=c(990,10),Latitude=c(990,10),by=c(10,10))
   spT.check.locations(fit.locations=as.matrix(long.lat),pred.locations=knots.coords,method="euclidean",tol=1.5)
   plot(long.lat,xlab="Longitude",ylab="Latitude",pch=3,col=4,cex=0.6)
   points(knots.coords,pch=19,col=2)

## Section 4: code for data simulation of the GP model ##
## Takes: 6.83-sec in Core-i5, 2.6GHz, RAM: 4.00GB

ptm <- proc.time()
   set.seed(11)
   library("spTimer")
   n <- 12*12 # say, sites
   Longitude<-seq(0,1000,by=1000/(12-1))
   Latitude<-seq(0,1000,by=1000/(12-1))
   long.lat<-expand.grid(Longitude,Latitude)
   site<-data.frame(s.index=1:n,Longitude=long.lat[,1],Latitude=long.lat[,2])
   d<-as.matrix(dist(site[,2:3], method="euclidean", diag = TRUE, upper = TRUE))
   library(MASS)
   r <- 1 # year
   T<- 365 # day
   N<-n*r*T
   sig2e<-0.01; sig2eta<-0.1; phi<-0.003; D1<-exp(-phi*d); beta<-5.0
   Ivec<-rep(1,n); z<-matrix(NA,r*T,n); o<-matrix(NA,r*T,n)
   for(i in 1:(r*T)){
     o[i,]<-beta+mvrnorm(1,rep(0,n),sig2eta*D1)
     z[i,]<-o[i,]+rnorm(1,0,sqrt(sig2e)) 
   }
   dat1<-matrix(NA,n*r*T,4)
   dat1[,1]<-sort(rep(1:n,r*T))
   dat1[,2]<-sort(rep(1:r,T))
   dat1[,3]<-1:T
   dat1[,4]<-c(z)
   dimnames(dat1)[[2]]<-c("s.index","year","day","y")
   dat1<-as.data.frame(dat1)
   dat1<-merge(dat1,site,by=c("s.index"),all.x=TRUE)
   dat1$y_no_mis<-dat1$y
   set.seed(11)
   dat1[sample(1:dim(dat1)[[1]],round(dim(dat1)[[1]]*0.05)),4]<-NA # 5% missing values to put
   set.seed(11)
   s<-sample(1:dim(site)[[1]],15)
   val<-spT.data.selection(data=dat1, random=FALSE, s=s) # for model validation
   fit<-spT.data.selection(data=dat1, random=FALSE, s=s, reverse=TRUE) # for model fitting
   write.table(val,"GP_toydata_val.csv",sep=',',row.names=FALSE)
   write.table(fit,"GP_toydata_fit.csv",sep=',',row.names=FALSE)
proc.time() - ptm

## Section 4: code for running the simulated data of the GP models ##
## WARNING: It will take time,  15-mins in Core-i5, 2.6GHz, RAM: 4.00GB ##

   # Read data 
   library("spTimer")
   fit<-read.table("GP_toydata_fit.csv",sep=',',header=TRUE)
   val<-read.table("GP_toydata_val.csv",sep=',',header=TRUE)
   # Define the coordinates
   coords<-as.matrix(unique(cbind(fit$Longitude,fit$Latitude)))
   newcoords<-as.matrix(unique(cbind(val$Longitude,val$Latitude)))
   # MCMC via Gibbs using defaults
   set.seed(11)
   post.gp.sim <- spT.Gibbs(formula=y~1,data=fit,model="GP",coords=coords,newcoords=newcoords,newdata=val,distance.method="euclidean",nItr=2500,nBurn=1000,report=5,spatial.decay=spT.decay(type="MH",tuning=0.9))
   print(post.gp.sim)
# Section 4.1: code for Table 2
   summary(post.gp.sim)
# Validation statistics
   spT.validation(val$y,post.gp.sim$prediction[,1])

## Section 4: code for data simulation of the AR model ##
## Takes: 6.74-sec in Core-i5, 2.6GHz, RAM: 4.00GB

ptm <- proc.time()
   set.seed(111)
   library("spTimer")
   n <- 12*12 # say, sites
   Longitude<-seq(0,1000,by=1000/(12-1))
   Latitude<-seq(0,1000,by=1000/(12-1))
   long.lat<-expand.grid(Longitude,Latitude)
   site<-data.frame(s.index=1:n,Longitude=long.lat[,1],Latitude=long.lat[,2])
   d<-as.matrix(dist(site[,2:3], method="euclidean", diag = TRUE, upper = TRUE))
   library(MASS)
   r <- 1 # year
   T<- 365 # day
   N<-n*r*T
   sig2e<-0.01; sig2eta<-0.1; phi<-0.003; D1<-exp(-phi*d); beta<-5.0; rho<-0.2; mu<-5.0; sig2<-0.5
   Ivec<-rep(1,n); z<-matrix(NA,T*r,n); o<-matrix(NA,(T+1)*r,n); 
   for(j in 1:r){
     o[1+(j-1)*T,] <- mvrnorm(1,rep(mu,n),sig2*D1)
     for(i in 1:T){
       o[(i+1)+(j-1)*T,]<-rho*o[i+(j-1)*T,]+beta*Ivec+mvrnorm(1,rep(0,n),sig2eta*D1)
       z[i+(j-1)*T,]<-o[(i+1)+(j-1)*T,]+rnorm(1,0,sqrt(sig2e)) 
     } 
   }
   dat1<-matrix(NA,n*r*T,4)
   dat1[,1]<-sort(rep(1:n,r*T))
   dat1[,2]<-sort(rep(1:r,T))
   dat1[,3]<-1:T
   dat1[,4]<-c(z)
   dimnames(dat1)[[2]]<-c("s.index","year","day","y")
   dat1<-as.data.frame(dat1)
   dat1<-merge(dat1,site,by=c("s.index"),all.x=TRUE)
   dat1$y_no_mis<-dat1$y
   set.seed(111)
   dat1[sample(1:dim(dat1)[[1]],round(dim(dat1)[[1]]*0.05)),4]<-NA # 5% missing values to put
   set.seed(111)
   s<-sample(1:dim(site)[[1]],15)
   val<-spT.data.selection(data=dat1, random=FALSE, s=s) # for model validation
   fit<-spT.data.selection(data=dat1, random=FALSE, s=s, reverse=TRUE) # for model fitting
   write.table(val,"AR_toydata_val.csv",sep=',',row.names=FALSE)
   write.table(fit,"AR_toydata_fit.csv",sep=',',row.names=FALSE)
proc.time() - ptm


## Section 4: code for running the simulated data of the AR models ##
## WARNING: It will take time,  18-mins in Core-i5, 2.6GHz, RAM: 4.00GB ##

   # Read data 
   library("spTimer")
   fit<-read.table("AR_toydata_fit.csv",sep=',',header=TRUE)
   val<-read.table("AR_toydata_val.csv",sep=',',header=TRUE)
   # Define the coordinates
   coords<-as.matrix(unique(cbind(fit$Longitude,fit$Latitude)))
   newcoords<-as.matrix(unique(cbind(val$Longitude,val$Latitude)))
   # MCMC via Gibbs using defaults
   set.seed(111)
   post.ar.sim <- spT.Gibbs(formula=y~1,data=fit,model="AR",coords=coords,newcoords=newcoords,newdata=val,distance.method="euclidean",nItr=2500,nBurn=1000,report=5,spatial.decay=spT.decay(type="MH",tuning=0.01))
   print(post.ar.sim)
# Section 4.1: code for Table 2
   summary(post.ar.sim)
# Validation statistics
   spT.validation(val$y,post.ar.sim$prediction[,1])

## Section 4: code for data simulation of the GPP based model ##
## Takes: 124.98-sec in Core-i5, 2.6GHz, RAM: 4.00GB ##

ptm <- proc.time()
   set.seed(33)
   library("spTimer"); library("MASS")
   n <- 55*55 # say, sites
   Longitude<-seq(0,1000,by=1000/(55-1))
   Latitude<-seq(0,1000,by=1000/(55-1))
   long.lat<-expand.grid(Longitude,Latitude)
   knots.coords<-spT.grid.coords(Longitude=c(990.75,9.25),Latitude=c(990.75,9.25),by=c(10,10))
   spT.check.locations(fit.locations=as.matrix(long.lat),pred.locations=knots.coords,method="euclidean",tol=0.05)
   site<-data.frame(s.index=1:n,Longitude=long.lat[,1],Latitude=long.lat[,2])
   d<-as.matrix(dist(site[,2:3], method="euclidean", diag = TRUE, upper = TRUE))
   d2<-as.matrix(dist(knots.coords, method="euclidean", diag = TRUE, upper = TRUE))
   r <- 1 # year
   T<- 365 # day
   N<-n*r*T
   sig2e<-0.01; sig2eta<-0.1; phi<-0.003; D1<-exp(-phi*d); beta<-5.0; rho<-0.2; mu<-5.0; sig2<-0.5
   D2<-exp(-phi*d2); m<-10*10; 
   dd<-as.matrix(dist(rbind(as.matrix(site[,2:3]),knots.coords), 
     method="euclidean", diag = TRUE, upper = TRUE))
   C<-dd[1:dim(site)[[1]],(dim(site)[[1]]+1):(dim(site)[[1]]+dim(knots.coords)[[1]])]
   A<-exp(-phi*C)%*%solve(D2)
   Ivec<-rep(1,n); z<-matrix(NA,T*r,n); w<-matrix(NA,(T+1)*r,m); 
   for(j in 1:r){
     w[1+(j-1)*T,] <- mvrnorm(1,rep(0,m),sig2*D2)
     for(i in 1:T){
       w[(i+1)+(j-1)*T,]<-rho*w[i+(j-1)*T,]+mvrnorm(1,rep(0,m),sig2eta*D2)
     } 
   }
   for(j in 1:r){
     for(i in 1:T){
       e<-rnorm(1,0,sqrt(sig2e))
       z[i+(j-1)*T,]<-A%*%w[(i+1)+(j-1)*T,]+beta*Ivec+e 
     }
   }
   dat1<-matrix(NA,n*r*T,4)
   dat1[,1]<-sort(rep(1:n,r*T))
   dat1[,2]<-sort(rep(1:r,T))
   dat1[,3]<-1:T
   dat1[,4]<-c(z)
   dimnames(dat1)[[2]]<-c("s.index","year","day","y")
   dat1<-as.data.frame(dat1)
   dat1<-merge(dat1,site,by=c("s.index"),all.x=TRUE)
   dat1$y_no_mis<-dat1$y
   set.seed(33)
   dat1[sample(1:dim(dat1)[[1]],round(dim(dat1)[[1]]*0.05)),4]<-NA # 5% missing 
   set.seed(33)
   s<-sample(1:dim(site)[[1]],300) 
   val<-spT.data.selection(data=dat1, random=FALSE, s=s) # for model validation
   fit<-spT.data.selection(data=dat1, random=FALSE, s=s, reverse=TRUE) # for model fitting
   write.table(val,"GPP_toydata_val.csv",sep=',',row.names=FALSE)
   write.table(fit,"GPP_toydata_fit.csv",sep=',',row.names=FALSE)
proc.time() - ptm


## Section 4: code for running the simulated data of the GPP models ##
## WARNING: It will take time,  40-mins in Core-i5, 2.6GHz, RAM: 4.00GB ##

   # Read data 
   library("spTimer")
   fit<-read.table("GPP_toydata_fit.csv",sep=',',header=TRUE)
   val<-read.table("GPP_toydata_val.csv",sep=',',header=TRUE)
   # Define the coordinates
   coords<-as.matrix(unique(cbind(fit$Longitude,fit$Latitude)))
   knots.coords<-spT.grid.coords(Longitude=c(990.75,9.25),Latitude=c(990.75,9.25),by=c(10,10))
   newcoords<-as.matrix(unique(cbind(val$Longitude,val$Latitude)))
   # MCMC via Gibbs using defaults
   set.seed(33)
   post.gpp.sim <- spT.Gibbs(formula=y~1,data=fit,model="GPP",coords=coords,knots.coords=knots.coords,newcoords=newcoords,newdata=val,distance.method="euclidean",nItr=2500,nBurn=1000,report=50)#
   print(post.gpp.sim)
# Section 4.1: code for Table 2
   summary(post.gpp.sim)
# Validation statistics
   spT.validation(val$y,post.gpp.sim$prediction[,1])
# Section 4.1: code for Figure 2 
  gpp.mis<-cbind(fit,fitted=post.gpp.sim$fitted[,1])
  gpp.mis<-gpp.mis[is.na(gpp.mis[,4]),]
  table(gpp.mis[,1]) # select site number 230 
  gpp.mis<-gpp.mis[gpp.mis[,1]==230,]
  plot(gpp.mis[,7],type='o',lty=2,xlab="Index",ylab="Values",ylim=c(4.3,5.7),main="Missing values for the GPP based model",pch=19)
  lines(gpp.mis[,8],lty=1,xlab="Index",ylab="Values",col=2,pch=0,type='o')
  legend("topright",col=c(1,2),pch=c(19,0),lty=c(2,1),legend=c("Actual values","Fitted values"),bty="n")
# Section 4.1: code for Figure 3 ##
  plot(val$y,post.gpp.sim$prediction[,1],xlab="Observed",ylab="Prediction",main="GPP based model",pch="*",ylim=c(3.8,6.2),xlim=c(3.8,6.2))
  abline(a=0,b=1,col=2)


################### Section 5: New York data example #####################


## Section 5: code for Figure 4 (NY map) ##

  library("spTimer");library("maps")
  data(DataFit);data(DataValPred)
  coords<-as.matrix(unique(cbind(DataFit[,2:3])))
  pred.coords<-as.matrix(unique(cbind(DataValPred[,2:3])))
  map(database="state",regions="new york")
  points(coords,pch=19,col=3)
  points(coords,pch=1,col=1)
  points(pred.coords,pch=3,col=4)
  legend(x=-77.5,y=41.5,col=c(3,4),pch=c(19,3),cex=0.8,legend=c("Fitted sites","Validation sites"))


## Section 5: code for GP models for NY ozone data example ##

 # Read data 
   library("spTimer")
   data(DataFit); 
 # Define the coordinates
   coords<-as.matrix(unique(cbind(DataFit[,2:3])))
   # MCMC via Gibbs using defaults
   set.seed(11)
   post.gp <- spT.Gibbs(formula=o8hrmax ~cMAXTMP+WDSP+RH,   
          data=DataFit, model="GP", coords=coords, 
          scale.transform="SQRT")
   print(post.gp)
 # Summary and plots
   summary(post.gp)
   summary(post.gp,pack="coda") # mcmc summary statistics using coda package
   plot(post.gp)
   plot(post.gp,residuals=TRUE)
 # some other R functions 
   coef(post.gp)
   formula(post.gp)
   terms(post.gp)
   model.frame(post.gp)
   model.matrix(post.gp)
 # Model selection criteria
   post.gp$PMCC 
 # MCMC diagnostics
 # autocorr diagnostics
   autocorr.diag(as.mcmc(post.gp))
 # Raftery and Lewis's diagnostic
   raftery.diag(post.gp)
 # Diagnostics using more than one chain
   set.seed(22)
   post.gp2 <- spT.Gibbs(formula=o8hrmax ~cMAXTMP+WDSP+RH,   
          data=DataFit, model="GP", coords=coords, 
          initials=spT.initials(model="GP",phi=1,sig2eta=1),
          scale.transform="SQRT")
   mcobj<-list(as.mcmc(post.gp),as.mcmc(post.gp2))
   mcobj<-as.mcmc.list(mcobj)
 # acf plot
   acfplot(mcobj)
 # Geweke's convergence diagnostic
   geweke.diag(mcobj)
 # Gelman and Rubin's diagnostic
   gelman.diag(mcobj)
   gelman.plot(mcobj)


## Section 5: Spatial prediction/interpolation for the GP model

 # Read data
   data(DataValPred)
 # Define prediction coordinates
   pred.coords<-as.matrix(unique(cbind(DataValPred[,2:3])))
 # Spatial prediction using spT.Gibbs output
   set.seed(11)
   pred.gp <- predict(post.gp, newdata=DataValPred, newcoords=pred.coords)
   print(pred.gp)
   names(pred.gp)
 # validation criteria
   spT.validation(DataValPred$o8hrmax,c(pred.gp$Median))  

 # Temporal  prediction/forecast for the GP model
 # 1. In the unobserved locations
 # Read data
   data(DataValFore);
 # define forecast coordinates
   fore.coords<-as.matrix(unique(cbind(DataValFore[,2:3])))
 # Two-step ahead forecast, i.e., in day 61 and 62 
 # in the unobserved locations using output from spT.Gibbs
   set.seed(11)
   fore.gp <- predict(post.gp, newdata=DataValFore, newcoords=fore.coords, 
           type="temporal", foreStep=2)
   print(fore.gp)
   names(fore.gp)
 # Forecast validations 
   spT.validation(DataValFore$o8hrmax,c(fore.gp$Median)) 

 # Temporal  prediction/forecast for the GP model
 # 2. In the observed/fitted locations
 # Read data
   data(DataFitFore)
 # Define forecast coordinates
   fore.coords<-as.matrix(unique(cbind(DataFitFore[,2:3])))
 # Two-step ahead forecast, i.e., in day 61 and 62, 
 # in the fitted locations using output from spT.Gibbs
   set.seed(11)
   fore.gp <- predict(post.gp, newdata=DataFitFore, newcoords=fore.coords, 
            type="temporal", foreStep=2)
   print(fore.gp)
   names(fore.gp)
 # Forecast validations 
   spT.validation(DataFitFore$o8hrmax,c(fore.gp$Median)) # 


## Section 5: Spatial prediction/interpolation for the AR model

 # Read data 
   library("spTimer")
   data(DataFit); 
 # Define the coordinates
   coords<-as.matrix(unique(cbind(DataFit[,2:3])))
 # MCMC via Gibbs
   set.seed(11)
   post.ar <- spT.Gibbs(formula=o8hrmax ~cMAXTMP+WDSP+RH,   
          data=DataFit, model="AR", coords=coords, 
          scale.transform="SQRT")
   print(post.ar)
 # Summary and plots
   summary(post.ar)
   summary(post.ar,pack="coda")
   plot(post.ar)
   plot(post.ar,residuals=TRUE)
 # Model selection criteria
   post.ar$PMCC 

 # Spatial prediction/interpolation for the AR model
 # Read data
   data(DataValPred)
 # Define prediction coordinates
   pred.coords<-as.matrix(unique(cbind(DataValPred[,2:3])))
 # Spatial prediction using spT.Gibbs output
   set.seed(11)
   pred.ar <- predict(post.ar, newdata=DataValPred, newcoords=pred.coords)
   print(pred.ar)
   names(pred.ar)
 # validation criteria
   spT.validation(DataValPred$o8hrmax,c(pred.ar$Median))  

 # Temporal  prediction/forecast for the AR model
 # 1. In the unobserved locations
 # Read data
   data(DataValFore);
 # define forecast coordinates
   fore.coords<-as.matrix(unique(cbind(DataValFore[,2:3])))
 # Two-step ahead forecast, i.e., in day 61 and 62 
 # in the unobserved locations using output from spT.Gibbs
   set.seed(11)
   fore.ar <- predict(post.ar, newdata=DataValFore, newcoords=fore.coords, 
            type="temporal", foreStep=2, predAR=pred.ar)
   print(fore.ar)
   names(fore.ar)
 # Forecast validations 
   spT.validation(DataValFore$o8hrmax,c(fore.ar$Median)) 

 # Temporal  prediction/forecast for the AR model
 # 2. In the observed/fitted locations
 # Read data
   data(DataFitFore)
 # Define forecast coordinates
   fore.coords<-as.matrix(unique(cbind(DataFitFore[,2:3])))
 # Two-step ahead forecast, i.e., in day 61 and 62, 
 # in the fitted locations using output from spT.Gibbs
   set.seed(11)
   fore.ar <- predict(post.ar, newdata=DataFitFore, newcoords=fore.coords, 
            type="temporal", foreStep=2)
   print(fore.ar)
   names(fore.ar)
 # Forecast validations 
   spT.validation(DataFitFore$o8hrmax,c(fore.ar$Median)) # 



################# Section 5: Model based interpolation maps #####################

  library(spTimer)
  data(NYdata)
  coords<-unique(cbind(NYdata$Longitude,NYdata$Latitude))

  # MCMC via Gibbs
  post.gp.fit <- spT.Gibbs(formula=o8hrmax~cMAXTMP+WDSP+RH, 
         data=NYdata, model="GP", coords=coords, nItr=5000, nBurn=2000, report=10,
         scale.transform="SQRT")

  # predict in the grid locations
  data(NYgrid)
  grid.coords<-unique(cbind(NYgrid$Longitude,NYgrid$Latitude))
  grid.pred<-predict(post.gp.fit,newcoords=grid.coords,newdata=NYgrid)


# predictive plots
  library(MBA)
  library(fields)
  library(maps)

  # plot of the grid locations
  plot(grid.coords,pch=3,col=4,xlab="Longitude",ylab="Latitude")
  map(database="state",regions="new york",add=TRUE)
  points(coords,pch=19,col=3)
  points(coords,pch=1,col=1)

# this function is used to delete values outside NY
fnc.delete.map.XYZ<-function(xyz){
	x<-xyz$x; y<-xyz$y; z<-xyz$z
	xy<-expand.grid(x, y)
	eus<-(map.where(database="state", x=xy[,1], y=xy[,2]))
	dummy<-rep(0, length(xy[,1]))
	eastUS<-NULL
	eastUS<-data.frame(lon=xy[,1],lat=xy[,2],state=eus,dummy=dummy)
	eastUS[!is.na(eastUS[,3]),4]<-1
	eastUS[eastUS[,3]=="pennsylvania" & !is.na(eastUS[,3]),4]<-0
	eastUS[eastUS[,3]=="new jersey" & !is.na(eastUS[,3]),4]<-0
	eastUS[eastUS[,3]=="connecticut" & !is.na(eastUS[,3]),4]<-0
	eastUS[eastUS[,3]=="massachusetts:main" & !is.na(eastUS[,3]),4]<-0
	eastUS[eastUS[,3]=="new hampshire" & !is.na(eastUS[,3]),4]<-0
	eastUS[eastUS[,3]=="vermont" & !is.na(eastUS[,3]),4]<-0
	a <- eastUS[, 4]
	z <- as.vector(xyz$z)
	z[!a] <- NA
	z <- matrix(z, nrow = length(xyz$x))
      xyz$z <- z
      xyz
}
##

  true.val<-matrix(NYdata$o8hrmax,62,28)
  grid.val<-matrix(grid.pred$Median,62,dim(grid.coords)[[1]])
  grid.sd<-matrix(grid.pred$SD,62,dim(grid.coords)[[1]])

# Section 5: code for Figure 5(a)
# prediction for day 60
  day<-60
  surf<-cbind(grid.coords,grid.val[day,])
  surf<-mba.surf(surf,200,200)$xyz
  surf<-fnc.delete.map.XYZ(xyz=surf)
  brk<- seq(0,45,by=(45+0)/(1000-1))
  map(database="state",regions="new york")
  image.plot(surf,breaks=brk,col=tim.colors(999),xlab="Longitude",ylab="Latitude",axes=F)
  contour(surf,nlevels=15,lty=3,add=T)
  map(database="state",regions="new york",add=T)
  text(coords,labels=round(true.val[day,],1),cex=1.1,col=1)
  axis(1);axis(2)

# Section 5: code for Figure 5(b)
# sd for day 60
  day<-60
  surf<-cbind(grid.coords,grid.sd[day,])
  surf<-mba.surf(surf,200,200)$xyz
  surf<-fnc.delete.map.XYZ(xyz=surf)
  brk<- seq(2,12,by=(12-2)/(1000-1))
  map(database="state",regions="new york") 
  image.plot(surf,breaks=brk,col=topo.colors(999),xlab="Longitude",ylab="Latitude",axes=F)
  contour(surf,nlevels=15,lty=3,add=T)
  map(database="state",regions="new york",add=T)
  points(coords,pch=19,cex=1,col=2)
  points(coords,pch=1,cex=1,col=1)
  axis(1);axis(2)


################### Section 5: Comparison of GAM, GP, and AR models #####################

## load packages

   library("spTimer"); library("mgcv");  

## load data

   data(DataFit) # this is for fitting data
   DataFit$Month <- with(DataFit, factor(Month, labels = month.abb[unique(Month)])) 
   data(DataValPred) # this is for validation
   DataValPred$Month <- with(DataValPred, factor(Month, labels = month.abb[unique(Month)])) 

## additive model using mgcv package in R

   # model 1
   set.seed(11)
   fit.gam1 <- gam(o8hrmax ~ Month + Day + cMAXTMP + WDSP + RH + s(Longitude, Latitude, k=10), data = DataFit)
   pred.gam1 <- predict(fit.gam1,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam1)

   # model 2
   set.seed(11)
   fit.gam2 <- gam(o8hrmax ~ Month + s(Day) + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, k=10), data = DataFit)
   pred.gam2 <- predict(fit.gam2,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam2)

   # model 3
   set.seed(11)
   fit.gam3 <- gam(o8hrmax ~ Month + s(Day) + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, k=15), data = DataFit)
   pred.gam3 <- predict(fit.gam3,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam3)

   # model 4
   set.seed(11)
   fit.gam4 <- gam(o8hrmax ~ Month + s(Day) + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, k=5), data = DataFit)
   pred.gam4 <- predict(fit.gam4,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam4)

   # model 5
   set.seed(11)
   fit.gam5 <- gam(o8hrmax ~ Month + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, Day, k=20), data = DataFit)
   pred.gam5 <- predict(fit.gam5,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam5)

   # model 6
   set.seed(11)
   fit.gam6 <- gam(o8hrmax ~ Month + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, Day, k=50), data = DataFit)
   pred.gam6 <- predict(fit.gam6,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam6)

   # model 7
   ## WARNING: It will take time to run ##
   set.seed(11)
   fit.gam7 <- gam(o8hrmax ~ Month + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, Day, k=100), data = DataFit)
   pred.gam7 <- predict(fit.gam7,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam7)

   # model 8
   ## WARNING: It will take time to run ##
   set.seed(11)
   fit.gam8 <- gam(o8hrmax ~ Month + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, Day, k=500), data = DataFit)
   pred.gam8 <- predict(fit.gam8,DataValPred, interval="prediction")
# Section 5: code for Table 3
   spT.validation(DataValPred$o8hrmax,pred.gam8)

   # model 9
   ## WARNING: It will take time to run ##
   set.seed(11)
   fit.gam9 <- gam(o8hrmax ~ Month + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, Day, k=600), data = DataFit)
   pred.gam9 <- predict(fit.gam9,DataValPred, interval="prediction")
   spT.validation(DataValPred$o8hrmax,pred.gam9)

   # factor: s.index
   DataFit$s.index <- with(DataFit, factor(s.index))  
   DataValPred$s.index <- with(DataValPred, factor(s.index))  

   # model 10
   set.seed(11)
   fit.gam10 <- gam(o8hrmax ~ s.index + Month + s(Day) + s(cMAXTMP) + s(WDSP) + s(RH) + s(Longitude, Latitude, k=10), data = DataFit)
   pred.gam10 <- predict(fit.gam10,DataValPred, interval="prediction")
# Error: No predictive results with factor variable s.index


## GP model

   set.seed(11)
   post.gp <- spT.Gibbs(o8hrmax ~ cMAXTMP + WDSP + RH, data = DataFit, model = "GP", coords = as.matrix(unique(cbind(DataFit[,2:3]))), scale.transform = "SQRT")
   summary(post.gp)
   set.seed(11)
   pred.gp <- predict(post.gp, newdata = DataValPred, newcoords = as.matrix(unique(cbind(DataValPred[,2:3]))))
# Section 5: code for Table 3
   spT.validation(DataValPred$o8hrmax,c(pred.gp$Median))  

## AR model

   set.seed(11)
   post.ar <- spT.Gibbs(o8hrmax ~ cMAXTMP + WDSP + RH, data = DataFit, model = "AR", coords = as.matrix(unique(cbind(DataFit[,2:3]))), scale.transform = "SQRT")
   summary(post.ar)
   set.seed(11)
   pred.ar <- predict(post.ar, newdata = DataValPred, newcoords = as.matrix(unique(cbind(DataValPred[,2:3]))))
# Section 5: code for Table 3
   spT.validation(DataValPred$o8hrmax,c(pred.ar$Median))  


############## Code for package "spBayes" ##########################

## WARNING: It will take time to run ##

start.time <- proc.time()[3]

  library(spTimer)
  library(spBayes)
  data(DataFit)
  coords<-unique(cbind(DataFit$Longitude,DataFit$Latitude))

  # spBayes cannot handle the missing values in y automatically for multivariate case
  # we replace missing observations by grand median

  y<-matrix(DataFit$o8hrmax,60,20)
  y<-cbind(c(y),rep(apply(y,1,mean,na.rm=T),20))
  y[is.na(y[, 1]), 1] <- y[is.na(y[, 1]), 2]
  y[is.na(y[, 1]), 1] <- median(y[, 2], na.rm = TRUE)
  y<-matrix(y[,1],60,20)

  x1<-matrix(DataFit$cMAXTMP,60,20)
  x2<-matrix(DataFit$WDSP,60,20)
  x3<-matrix(DataFit$RH,60,20)

  # need to supply equation for each day
  f<-NULL
  for(i in 1:60){
    f[[i]]<- as.formula(paste("y[",i,",]~x1[",i,",]+x2[",i,",]+x3[",i,",]",sep=""))
  }

  # Call spMvLM
  q<-60
  A.starting <- diag(1,q)[lower.tri(diag(1,q), TRUE)]
  # Do 2500 iterations
  n.samples <- 2500

  starting <- list("phi"=rep(3/0.5,q), "A"=A.starting, "Psi"=rep(1,q))
  tuning <- list("phi"=rep(50,q), "A"=rep(0.0001,length(A.starting)), "Psi"=rep(50,q))
  priors <- list("beta.Flat", "phi.Unif"=list(rep(3/0.75,q), rep(3/0.25,q)),
               "K.IW"=list(q+1, diag(0.1,q)), "Psi.ig"=list(rep(2,q), rep(0.1,q)))

  set.seed(11)
  m.1 <- spMvLM(f, 
     coords=coords, starting=starting, tuning=tuning, priors=priors,
     n.samples=n.samples, cov.model="exponential", n.report=10)


end.time <- proc.time()[3]
comp.time <- end.time - start.time
comp.time


#########################################################################################

