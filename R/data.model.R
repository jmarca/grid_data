library(doMC)
registerDoMC(1)

curlH <- RCurl::getCurlHandle()

data.model <- function(df.mrg,formula=n.aadt.frac~1){

  site.coords<-unique(cbind(df.mrg$Longitude,df.mrg$Latitude))
    post.gp.fit <- spTimer::spT.Gibbs(formula=formula,
                                      data=df.mrg,
                                      model="GP",
                                      coords=site.coords,
                                      tol.dist=0.005,
                                      distance.method="geodetic:km",
                                      report=10,
                                      scale.transform="SQRT")
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


group.loop <- function(prediction.grid,var.models,ts.ts,ts.un){

    ## set up for saving to couchdb
    df.all.predictions = list()
    for(sim.site in 1:(length(prediction.grid[,1]))){
        df.all.predictions[[sim.site]] <- data.frame('ts'= ts.ts)
        df.all.predictions[[sim.site]]$i_cell  <- prediction.grid[sim.site,'i_cell']
        df.all.predictions[[sim.site]]$j_cell  <- prediction.grid[sim.site,'j_cell']
        df.all.predictions[[sim.site]]$geom_id <- prediction.grid[sim.site,'geo_id']
        df.all.predictions[[sim.site]]['_id']  <- paste(df.all.predictions[[sim.site]]$geom_id,
                                                        df.all.predictions[[sim.site]]$ts,
                                                        sep='_')
    }

    predictions <- plyr::llply(var.models,data.predict.generator(prediction.grid,ts.un)
                              ##,.parallel=TRUE
                               )

    for(model.name in names(var.models)){
        grid.pred <- predictions[[model.name]]
        for(sim.site in 1:(length(df.all.predictions))){
            df.all.predictions[[sim.site]][,model.name] <- grid.pred$Median[,sim.site]
        }
    }
    # gc()
    rearranger <- NULL
    doccount <- 0
    for(sim.site in 1:1:(length(df.all.predictions))){
        tempdf <- df.all.predictions[[sim.site]]
        rnm = names(tempdf)
        names(tempdf) <- gsub('.aadt.frac','',x=rnm)
        if(is.null(rearranger)){
            rearranger <- rearrange_data(names(tempdf))
        }

        storedf <- plyr::dlply(tempdf,plyr::.(ts),rearranger)
        ## strip the attributes added by plyr
        attributes(storedf) <- NULL

        print(paste(sim.site,
                    storedf[[1]]['_id']))
        res <- rcouchutils::couch.bulk.docs.save(hpms.grid.couch.db,storedf,h=curlH)
        doccount <- doccount + res
    }
    ## print(paste('saved',doccount,'docs'))

}


##' rearrange data
##'
##' In order to store data in CouchDB, need to change the records
##' around a bit, so that each has a list for the value of aadt
##'
##' @title rearrange_data
##' @param col.names what you want to rearrange
##' @return a data frame
##' @author James E. Marca
rearrange_data <- function(col.names){

    numeric.cols <-  grep( pattern="^(_id|ts|geom_id|freeway|detectors)$",x=col.names,perl=TRUE,invert=TRUE)
    aadt.cols <- grep(pattern="^(n|hh|nhh)",x=col.names[numeric.cols],perl=TRUE)
    ## so strip these out of the original, and replace with a list

    anon <- function(row){
        ## for each row, split out the aadt fraction variables
        outpt <- as.list(row)
        ##print(outpt)
        aadtlist <- list()
        for(i in 1:length(aadt.cols)){
            outpt[[col.names[numeric.cols[aadt.cols[i]]]]] <- NULL
            aadtlist[[col.names[numeric.cols[aadt.cols[i]]]]] <- row[[numeric.cols[aadt.cols[i]]]]
        }
        outpt[['aadt']] <- aadtlist
        ## print(outpt)
        return (outpt)

    }
    return(anon)

}


## send a chunk of data to this function
data.model.and.predict <- function(df.fwy.data,df.hpms.grid.locations,year){

    ## handle time from df.fwy.data
    ts2 <- strptime(df.fwy.data$ts,"%Y-%m-%d %H:%M",tz='UTC')
    ts.un <- sort(unique(ts2))
    ts.ct <- sort(unique(df.fwy.data$tsct))
    ts.ts = sort(unique(df.fwy.data$ts))
    n.times = length(ts.un)

    ## set up date to check if data in couchdb for hpms grid
    checkday <- min(df.fwy.data$day)
    if(checkday<10) checkday <- paste('0',checkday,sep='')
    checkmonth <- df.fwy.data$month[1] + 1 ## month is one less than month, because javascript
    if(checkmonth < 10) checkmonth <- paste('0',checkmonth,sep='')
    ## form date part of checking URL for couchdb

    # couch.test.date <- paste(paste(year,checkmonth,checkday,sep='-'),"00%3A00",sep='%20')
    couch.test.date <- paste(paste(year,checkmonth,checkday,sep='-'),"00:00",sep=' ')

    print(paste('checking',couch.test.date))

    ## set up hpms grid cells to check, maybe process
    geoids <- df.fwy.data$geo_id ## sort(unique(paste(df.fwy.data$i_cell, df.fwy.data$j_cell,'_')))
    overlap <- df.hpms.grid.locations$geo_id %in% geoids
    df.hpms.grid.locations <- df.hpms.grid.locations[!overlap,]


    picker <- 1:length(df.hpms.grid.locations[,1])
    couch.test.docs <- paste(df.hpms.grid.locations$geo_id,couch.test.date,sep='_')
    result = rcouchutils::couch.allDocsPost(db=hpms.grid.couch.db,
                                            keys=couch.test.docs,
                                            include.docs=FALSE,h=curlH)
    rows = result$rows
    print(length(rows))
    hpmstodo <- picker < 0 # default false
    for(cell in picker){
        row = rows[[cell]]
        if('error' %in% names(row)){
            hpmstodo[cell] <- TRUE  ##true means need to do this document
            print(df.hpms.grid.locations[cell,])
         }
    }

    if(length(picker[hpmstodo])<1){
        print(paste('all done',couch.test.date))
        return ()
    }
    picked = picker[hpmstodo]
    print(paste('still to do',length(picked),couch.test.date))


    if(length(picked)>1)    picked = sample(picked) ## randomly permute

    if(length(unique(df.fwy.data$s.idx))<2){
        print('buggy version')
        ## just assign frac to hpms cells
        for(sim.set in picked){
            df.pred.grid <- df.hpms.grid.locations[sim.set,]
            df.all.predictions <- data.frame('ts'= ts.ts)
            df.all.predictions$i_cell <- df.hpms.grid.locations[sim.set,'i_cell']
            df.all.predictions$j_cell <- df.hpms.grid.locations[sim.set,'j_cell']
            df.all.predictions$geom_id <- df.hpms.grid.locations[sim.set,'geo_id']

            for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
                df.all.predictions[,variable] <- df.fwy.data[,variable]
            }
            if(dim(df.all.predictions)[2]>4){
                ## now dump that back into couchdb
                rnm = names(df.all.predictions)
                names(df.all.predictions) <- gsub('.aadt.frac','',x=rnm)
                save.these = ! is.na(df.all.predictions$n)
                rcouchutils::couch.bulk.docs.save(hpms.grid.couch.db,df.all.predictions[save.these,],h=curlH)
            }
        }
    }else{
        df.pred.grid <- df.hpms.grid.locations[picked,] ## the grid cells I need to predict
        var.models <- plyr::llply(list('n.aadt.frac'='n.aadt.frac',
                                 'hh.aadt.frac' ='hh.aadt.frac',
                                 'nhh.aadt.frac'='nhh.aadt.frac'),
                            function(variable){
                                data.model(df.fwy.data,formula=formula(paste(variable,1,sep='~')))
                            }
                            ##.parallel=TRUE
                            )
        # gc()
        ## need to limit...can be 300+, eats up too much RAM
        ## group.loop(df.hpms.grid.locations[picked,],var.models,ts.ts,ts.un)

        num.cells = 10 ## 90 # min( 90, ceiling(80 * 11000 / length(batch.idx)))
        num.runs = ceiling(length(picked)/num.cells) ## manage RAM
        print(paste('num.runs is',num.runs,'which means number cells per run is about',floor(length(picked)/num.runs)))

        runs.index <- rep_len(1:num.runs,length=length(picked))
        runs.result <- try (
            ## this used to use plyr, but made it a loop for now to help debugging
            for (i in 1:max(runs.index)){
                idx <- runs.index == i
                group.loop(df.pred.grid[idx,],var.models,ts.ts,ts.un)

            }
            )
        if(class(runs.result) == "try-error"){
            print ("\n Error predicting, try more groups? \n")
            print(runs.result)
            stop()
        }


    }

}



process.data.by.day <- function(df.grid,df.hpms.grids,year,month){
    print (month)
    df.data <- get.raft.of.grids(df.grid,month=month,year=year)
    ## because javascript, the month is zero based.  so if month ==
    ## month, it is actually the wrong month (next month)
    drop <- df.data$month==month

    df.kp <- df.data[!drop,]

    plyr::d_ply(df.kp, plyr::.(day), data.model.and.predict,
                .parallel = TRUE,
                .progress = "none", df.hpms.grids,year)

    ## for(dy in 1:max(df.kp$day)){
    ##     print(paste('processing',dy))
    ##     day.idx <-  df.kp$day == dy
    ##     data.model.and.predict(df.fwy.data=df.kp[day.idx,],df.hpms.grids,year)
    ## }

}
