
data.model <- function(df.mrg,formula=n.aadt.frac~1){

  site.coords<-unique(cbind(df.mrg$Longitude,df.mrg$Latitude))
  post.gp.fit <- spT.Gibbs(formula=formula,data=df.mrg,model="GP",coords=site.coords,tol.dist=0.005,distance.method="geodetic:km",report=10,scale.transform="SQRT")
  post.gp.fit

}


## to call from plyr, one ply per model

data.predict <- function(model,df.pred.grid,ts.un){
  n.sites <- length(df.pred.grid[,1])
  df.pred.grid$s.idx <- 1:n.sites

  ts.psx <- as.POSIXct(ts.un)

  n.times <- length(ts.un)
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
  df.mrg$hh.aadt.frac <- NA
  df.mrg <-  merge(df.mrg,df.pred.grid,all=TRUE,by=c("s.idx"))
  grid.coords<-unique(cbind(df.mrg$Longitude,df.mrg$Latitude))
  print(grid.coords)
  grid.pred<-predict(model,newcoords=grid.coords,newdata=df.mrg,tol.dist=0.005,distance.method="geodetic:km")
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

    predictions <- llply(var.models,function(model){
        data.predict(model,df.pred.grid,ts.un)
    })

    for(model.name in names(var.models)){
        grid.pred <- predictions[[model.name]]
        for(sim.site in 1:(length(some.picked))){
            df.all.predictions[[sim.site]][,model.name] <- grid.pred$Median[,sim.site]
        }
    }
    gc()
    for(sim.site in 1:(length(some.picked))){
        rnm = names(df.all.predictions[[sim.site]])
        names(df.all.predictions[[sim.site]]) <- gsub('.aadt.frac','',x=rnm)
        couch.bulk.docs.save(hpms.grid.couch.db,df.all.predictions[[sim.site]],local=TRUE,makeJSON=dumpPredictionsToJSON)
    }
}

## send a chunk of data to this function
data.model.and.predict <- function(df.data,df.hpms.grids){

    ## handle time from df.data
    ts.un <- sort(unique(df.data$ts2))
    ts.ct <- sort(unique(df.data$tsct))
    ts.ts = sort(unique(df.data$ts))
    n.times = length(ts.un)

    ## set up date to check if data in couchdb for hpms grid
    checkday <- min(df.data$day)+1
    if(checkday<10) checkday <- paste('0',checkday,sep='')
    checkmonth <- df.data$month[1] + 1 ## month is one less than month
    if(checkmonth < 10) checkmonth <- paste('0',checkmonth,sep='')
    print(paste('checking',couch.test.date))

    ## set up hpms grid cells to check, maybe process
    geoids <- sort(unique(paste(df.data$i_cell, df.data$j_cell,'_')))
    overlap <- df.hpms.grids$geo_id %in% geoids
    df.hpms.grids <- df.hpms.grids[!overlap,]

    ## loop over hpms cells,  and simulate what should be there
    simlim <- length(df.hpms.grids[,1])
    picker <- 1:simlim
    hpmstodo <- picker > 0
    for(cell in picker){
        ## abort if already done in couchdb
        df.pred.grid <- df.hpms.grids[cell,]
        couch.test.doc <- paste(df.pred.grid$geo_id,couch.test.date,sep='_')
        test.doc.json <- couch.get(hpms.grid.couch.db,couch.test.doc,local=TRUE)
        if('error' %in% names(test.doc.json) ){
            hpmstodo[cell] <- TRUE  ##true means need to do this document
        } else {
            hpmstodo[cell] <- FALSE ##false means doc is dropped from index
        }
    }
    print(length(picker[hpmstodo]))
    if(length(picker[hpmstodo])<1){
        return ()
    }
    picked = picker[hpmstodo]
    if(length(picked)>1)    picked = sample(picked) ## randomly permute
    if(length(unique(df.data$s.idx))<2){
        ## just assign frac to hpms cells
        for(sim.set in picked){
            df.pred.grid <- df.hpms.grids[sim.set,]
            ## this following test seems redundant
            ##couch.test.doc <- paste(df.pred.grid$geo_id,couch.test.date,sep='_')
            ##test.doc.json <- couch.get(hpms.grid.couch.db,couch.test.doc,local=TRUE)
            ##if('error' %in% names(test.doc.json) ){
            print(paste('processing',couch.test.doc))
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
        var.models <- llply(list('n.aadt.frac'='n.aadt.frac',
                                 'hh.aadt.frac' ='hh.aadt.frac',
                                 'nhh.aadt.frac'='nhh.aadt.frac'),
                            function(variable){
                                data.model(df.data,formula=formula(paste(variable,1,sep='~')))
                            })
        gc()

        num.cells = 30 ## 90 # min( 90, ceiling(80 * 11000 / length(batch.idx)))
        num.runs = ceiling(length(picked)/num.cells) ## manage RAM
        print(paste('num.runs is',num.runs,'which means number cells per run is about',floor(length(picked)/num.runs)))
        done.runs <- FALSE
        while(!done.runs){

            index=rep_len(1:num.runs,length=length(picked))

            runs.result <- try (
                d_ply(data.frame(picked=picked,group=index),'group',
                      function(pick.group){
                          group.loop(df.hpms.grids[pick.group$picked,],var.models,ts.ts,ts.un)
                      })
                )
            if(class(runs.result) == "try-error"){
                print ("\n Error predicting, try more groups \n")
                num.runs <- num.runs + 1
            }else{
                done.runs = TRUE
            }

        }

    }

}
