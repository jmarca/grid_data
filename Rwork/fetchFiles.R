library(spTimer)
source('./safetylib/remoteFiles.R')
source('./safetylib/couchUtils.R')
source('./loadJSON.R')
get.grid.file <- function(i,j,server='http://calvad.ctmlabs.net'){

   load.remote.file(server,service='grid',root=paste('hourly',i,sep='/'),file=paste(j,'json',sep='.'))
}

get.grid.file.from.couch <- function(i,j,start,end,local=TRUE){

  start.date.part <- start
  end.date.part <-  end
  if(!is.character(start)){
    start.date.part <- format(start,"%Y-%m-%d %H:00")
    end.date.part <- format(end,"%Y-%m-%d %H:00")
  }
  
  query=list(
    'startkey'=paste('%22',paste(i,j,start.date.part,sep='_'),'%22',sep=''),
    'endkey'=paste('%22',paste(i,j,end.date.part,sep='_'),'%22',sep='')
    )
  json <- couch.allDocs('carb%2fgrid%2fstate4k' , query=query, local=local)
  return(json)
}

get.grid.aadt.from.couch <- function(i,j,year,local=TRUE){
    ## when bug is fixed, make this i,j,year,aadt
    doc=paste(i,j,'aadt',sep='_')
    print('bug in aadt still')
    print(doc)
  json <- couch.get('carb%2fgrid%2fstate4k' , docname=doc, local=local)
  return(json)
}

get.raft.of.grids <- function(df.grid.subset,year,month,local=TRUE){
  ## df.grid.subset has a bunch of grids to get
  ## i_cell, j_cell
  ## make a start and end date
  month.padded=paste(month)
  if(month<10) month.padded=paste('0',month,sep='')
  start.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')
  month.padded=paste(month+1)
  if(month+1<10) month.padded=paste('0',month+1,sep='')
  end.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')
  df.bind <<- data.frame()

  for(i in 1:length(df.grid.subset[,1])){
    aadt.json <- get.grid.aadt.from.couch(df.grid.subset[i,'i_cell'],
                                          df.grid.subset[i,'j_cell'],
                                          year,
                                          local=local)
    if('error' %in% names(aadt.json)) next
    aadt.df <- parseAADTRecord(aadt.json)
    json.data <- get.grid.file.from.couch(df.grid.subset[i,'i_cell'],
                                          df.grid.subset[i,'j_cell'],
                                          start.date,
                                          end.date,
                                          local=FALSE)
    if('error' %in% names(json.data) || length(json.data$rows)==0) next
    print(length(json.data$rows))
    df <- parseGridRecord(json.data)
    rm(json.data)
    df$Latitude  <- df.grid.subset[i,'lat']
    df$Longitude <- df.grid.subset[i,'lon']
    df$i_cell <- df.grid.subset[i,'i_cell']
    df$j_cell <- df.grid.subset[i,'j_cell']
    df$s.idx <- i
    ## patch aadt onto df
    df$aadt.n <- aadt.df$aadt.n
    df$aadt.hh <- aadt.df$aadt.hh
    df$aadt.nhh <- aadt.df$aadt.nhh
    if(dim(df.bind)[1]==0){
      df.bind <<- df
    }else{
      df.bind <<- rbind(df.bind,df)
    }
  }
  ## need time to be uniform for all sites
  ts.un <<- sort(unique(df.bind$ts2))
  print(summary(ts.un))
  print('do posix')
  ts.psx <<- as.POSIXct(ts.un)
  print('done posix')
  ## site.index <- sort(unique(df.bind$s.idx))
  site.lat.lon <- ddply(df.bind,"s.idx",function(x){ 
     x[1,c("s.idx","Latitude","Longitude")]
  })
  n <- length(ts.un)
  N <- length(site.lat.lon[,1])
  dat.mrg <- matrix(NA,n*N,8)
  dat.mrg[,1] <- sort(rep(site.lat.lon$s.idx,each=n)) ## site number
  dat.mrg[,2] <- rep(ts.un$year,N)+1900
  dat.mrg[,3] <- rep(ts.un$mon,N)
  dat.mrg[,4] <- rep(ts.un$mday,N)
  dat.mrg[,5] <- rep(ts.un$hour,N)
  dat.mrg[,6] <- rep(ts.psx,N)
  dat.mrg[,7] <- sort(rep(site.lat.lon$Longitude,each=n)) ## lon
  dat.mrg[,8] <- sort(rep(site.lat.lon$Latitude,each=n)) ## lat
  dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour','tsct','Longitude','Latitude')
  df.mrg <- as.data.frame(dat.mrg)
  df.bind$Longitude <- NULL
  df.bind$Latitude <- NULL
  df.mrg <- merge(df.mrg,df.bind,all=TRUE,by=c("s.idx","tsct"))
  
  frac.filter <- !(df.mrg$aadt.n == 0 | is.na(df.mrg$aadt.n))
  df.mrg$aadt.fraction <- NA
  df.mrg$aadt.fraction[frac.filter] = df.mrg$n[frac.filter] / df.mrg$aadt.n[frac.filter] 
  df.mrg
}

data.model=function(df.mrg){
  
  site.coords<-unique(cbind(df.mrg$Longitude,df.mrg$Latitude))
  post.gp.fit <- spT.Gibbs(formula=aadt.fraction~1,data=df.mrg,model="GP",coords=site.coords,distance.method="geodetic:km",report=10,scale.transform="SQRT")
  post.gp.fit
  
}
