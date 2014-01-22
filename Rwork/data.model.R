library(doMC)
registerDoMC(3)

data.model <- function(df.mrg,formula=n.aadt.frac~1){

  site.coords<-unique(cbind(df.mrg$Longitude,df.mrg$Latitude))
  post.gp.fit <- spT.Gibbs(formula=formula,data=df.mrg,model="GP",coords=site.coords,tol.dist=0.005,distance.method="geodetic:km",report=10,scale.transform="SQRT")
  post.gp.fit

}


## to call from plyr, one ply per model
data.predict.generator <- function(df.pred.grid,ts.un){
    n.sites <- length(df.pred.grid[,1])
    df.pred.grid$s.idx <- 1:n.sites
    ts.psx <- as.POSIXct(ts.un)
    n.times <- length(ts.un)
    return (function(model){
        gc()
        dat.mrg <- matrix(NA,n.sites*n.times,8)
        dat.mrg[,1] <- sort(rep(df.pred.grid$s.idx,each=n.times)) ## site number
        dat.mrg[,2] <- rep(ts.un$year,n.sites)+1900
        dat.mrg[,3] <- rep(ts.un$mon,n.sites)
        dat.mrg[,4] <- rep(ts.un$mday,n.sites)
        dat.mrg[,5] <- rep(ts.un$hour,n.sites)
        dat.mrg[,6] <- rep(ts.psx,n.sites)
        dat.mrg[,7] <- sort(rep(df.pred.grid$lon,each=n.times)) ## lon
        dat.mrg[,8] <- sort(rep(df.pred.grid$lat,each=n.times))  ## lat
        dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour','tsct','Longitude','Latitude')
        df.mrg <- as.data.frame(dat.mrg)
        df.mrg$n.aadt.frac <- NA
        df.mrg$hh.aadt.frac <- NA
        df.mrg$nhh.aadt.frac <- NA
        df.mrg <-  merge(df.mrg,df.pred.grid,all=TRUE,by=c("s.idx"))
        # grid.coords<-unique(cbind(df.mrg$Longitude,df.mrg$Latitude))
        grid.coords<-as.matrix(unique(cbind(df.mrg$Longitude,df.mrg$Latitude)))
        print(grid.coords)
        predict(model,newcoords=grid.coords,newdata=df.mrg,tol.dist=0.005,distance.method="geodetic:km")
    })
}


group.loop <- function(df.pred.grid,var.models,ts.ts,ts.un){

    ## set up for saving to couchdb
    df.all.predictions = list()
    for(sim.site in 1:(length(df.pred.grid[,1]))){
        df.all.predictions[[sim.site]] <- data.frame('ts'= ts.ts)
        df.all.predictions[[sim.site]]$i_cell  <- df.pred.grid[sim.site,'i_cell']
        df.all.predictions[[sim.site]]$j_cell  <- df.pred.grid[sim.site,'j_cell']
        df.all.predictions[[sim.site]]$geom_id <- df.pred.grid[sim.site,'geo_id']
    }

    predictions <- llply(var.models,data.predict.generator(df.pred.grid,ts.un))

    for(model.name in names(var.models)){
        grid.pred <- predictions[[model.name]]
        for(sim.site in 1:(length(df.pred.grid[,1]))){
            df.all.predictions[[sim.site]][,model.name] <- grid.pred$Median[,sim.site]
        }
    }
    gc()
    for(sim.site in 1:(length(df.pred.grid[,1]))){
        rnm = names(df.all.predictions[[sim.site]])
        names(df.all.predictions[[sim.site]]) <- gsub('.aadt.frac','',x=rnm)
        couch.bulk.docs.save(hpms.grid.couch.db,df.all.predictions[[sim.site]],local=TRUE,makeJSON=dumpPredictionsToJSON)
    }
}



couch.allDocsPost <- function(db, keys, view='_all_docs', include.docs = TRUE, local=TRUE, h=getCurlHandle()){

  if(length(db)>1){
    db <- couch.makedbname(db)
  }
  cdb <- localcouchdb
  if(!local){
    cdb <- couchdb
  }
  ## docname <- '_all_docs'
  uri <- paste(cdb,db,view,sep="/");
##   print(uri)
  k <- paste('{"keys":["',
             paste(keys,collapse='","'),
             '"]}',sep='')
  if(include.docs){
      uri <- paste(uri,'include_docs=true',sep='?')
      ## }else{
      ##   q <- paste(q,sep='&')
  }
  reader <- basicTextGatherer()
  curlPerform(
              url = uri
              ,customrequest = "POST"
              ,httpheader = c('Content-Type'='application/json')
              ,postfields = k
              ,writefunction = reader$update
              ,curl=h
              )
  fromJSON(reader$value()[[1]],simplify=FALSE)
}



## send a chunk of data to this function
data.model.and.predict <- function(df.data,df.hpms.grids,year,local=TRUE){

    ## handle time from df.data
    ts2 <- strptime(df.data$ts,"%Y-%m-%d %H:%M",tz='UTC')
    ts.un <- sort(unique(ts2))
    ts.ct <- sort(unique(df.data$tsct))
    ts.ts = sort(unique(df.data$ts))
    n.times = length(ts.un)

    ## set up date to check if data in couchdb for hpms grid
    checkday <- min(df.data$day)
    if(checkday<10) checkday <- paste('0',checkday,sep='')
    checkmonth <- df.data$month[1] + 1 ## month is one less than month
    if(checkmonth < 10) checkmonth <- paste('0',checkmonth,sep='')
    ## form date part of checking URL for couchdb

    # couch.test.date <- paste(paste(year,checkmonth,checkday,sep='-'),"00%3A00",sep='%20')
    couch.test.date <- paste(paste(year,checkmonth,checkday,sep='-'),"00:00",sep=' ')

    print(paste('checking',couch.test.date))

    ## set up hpms grid cells to check, maybe process
    geoids <- df.data$geo_id ## sort(unique(paste(df.data$i_cell, df.data$j_cell,'_')))
    overlap <- df.hpms.grids$geo_id %in% geoids
    df.hpms.grids <- df.hpms.grids[!overlap,]


    picker <- 1:length(df.hpms.grids[,1])
    couch.test.docs <- paste(df.hpms.grids$geo_id,couch.test.date,sep='_')
    result = couch.allDocsPost(hpms.grid.couch.db,couch.test.docs,include.docs=FALSE,local=local)
    rows = result$rows
    print(length(rows))
    hpmstodo <- picker < 0 # default false
    for(cell in picker){
        row = rows[[cell]]
        if('error' %in% names(row)){
             hpmstodo[cell] <- TRUE  ##true means need to do this document
         }
    }

    if(length(picker[hpmstodo])<1){
        print(paste('all done',couch.test.date))
        return ()
    }
    picked = picker[hpmstodo]
    print(paste('still to do',length(picked),couch.test.date))

    if(length(picked)>1)    picked = sample(picked) ## randomly permute

    if(length(unique(df.data$s.idx))<2){
        ## just assign frac to hpms cells
        for(sim.set in picked){
            df.pred.grid <- df.hpms.grids[sim.set,]
            df.all.predictions <- data.frame('ts'= ts.ts)
            df.all.predictions$i_cell <- df.hpms.grids[sim.set,'i_cell']
            df.all.predictions$j_cell <- df.hpms.grids[sim.set,'j_cell']
            df.all.predictions$geom_id <- df.hpms.grids[sim.set,'geo_id']

            for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
                df.all.predictions[,variable] <- df.data[,variable]
            }
            if(dim(df.all.predictions)[2]>4){
                ## now dump that back into couchdb
                rnm = names(df.all.predictions)
                names(df.all.predictions) <- gsub('.aadt.frac','',x=rnm)
                save.these = ! is.na(df.all.predictions$n)
                couch.bulk.docs.save(hpms.grid.couch.db,df.all.predictions[save.these,],local=TRUE,makeJSON=dumpPredictionsToJSON)
            }
        }
    }else{
        df.pred.grid <- df.hpms.grids[picked,] ## the grid cells I need to predict
        var.models <- llply(list('n.aadt.frac'='n.aadt.frac',
                                 'hh.aadt.frac' ='hh.aadt.frac',
                                 'nhh.aadt.frac'='nhh.aadt.frac'),
                            function(variable){
                                data.model(df.data,formula=formula(paste(variable,1,sep='~')))
                            })
        gc()
        ## need to limit...can be 300+, eats up too much RAM
        ## group.loop(df.hpms.grids[picked,],var.models,ts.ts,ts.un)

        num.cells = 10 ## 90 # min( 90, ceiling(80 * 11000 / length(batch.idx)))
        num.runs = ceiling(length(picked)/num.cells) ## manage RAM
        print(paste('num.runs is',num.runs,'which means number cells per run is about',floor(length(picked)/num.runs)))

        runs.index <- rep_len(1:num.runs,length=length(picked))
        runs.result <- try (
            d_ply(df.pred.grid,.(runs.index),group.loop,var.models,ts.ts,ts.un)
            )
        if(class(runs.result) == "try-error"){
            print ("\n Error predicting, try more groups? \n")
            print(runs.result)
            stop()
        }


    }

}



process.data.by.day <- function(df.grid,df.hpms.grids,year,month,local){
    print (month)
    df.data <- get.raft.of.grids(df.grid,month=month,year=year,local=local)
    drop <- df.data$month==month
    d_ply(df.data[!drop,], .(day), data.model.and.predict, .parallel = TRUE, .progress = "none", .paropts = list(.packages=c('spTimer','plyr','RJSONIO','RCurl')), df.hpms.grids,year)


    ## d_ply(df.data[!drop,],.(day),data.model.and.predict,df.hpms.grids)

}
