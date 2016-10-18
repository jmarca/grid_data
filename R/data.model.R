##' Model the data for coordinates
##'
##'
##' @title data.model
##' @param df.mrg merged data frame
##' @param formula the formula to fit over time and space
##' @return the fit object
##' @author James E. Marca
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


##' Set up the prediction for a model
##'
##' Call this function to call from plyr, one ply per model
##' @title data.predict.generator
##' @param df.pred.grid the prediction grid
##' @param ts.un time stamps
##' @return a function that will run the prediction given the model
##'     from within plyr loop
##' @author James E. Marca
data.predict.generator <- function(df.pred.grid,ts.un){
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
    df.mrg$nhh.aadt.frac <- NA
    df.mrg <-  merge(df.mrg,df.pred.grid,all=TRUE,by=c("s.idx"))
                                        # grid.coords<-unique(cbind(df.mrg$Longitude,df.mrg$Latitude))
    grid.coords<-as.matrix(unique(cbind(df.mrg$Longitude,df.mrg$Latitude)))
    return (function(model){
        ## gc()
        print(grid.coords)
        spTimer::predict.spT(model,newcoords=grid.coords,newdata=df.mrg,tol.dist=0.005,distance.method="geodetic:km")
    })
}

##' This is the big outer modeling loop
##'
##' This function is called from the predict.hpms routine.  It needs
##' the prediction grid (where should predictions be made), and a list
##' of models and it will run the predictions and save to couchdb.
##' Nothing is returned from this function.
##' @title group.loop
##' @param prediction.grid which cells in grid to do predictions on
##' @param var.models the models to run over each grid cell
##' @param ts.ts some sort of time series data
##' @param ts.un a different time series.  Old stuff, I just don't
##'     remember right now.
##' @param curlH the curl handle
##' @return nothing at all
##' @author James E. Marca
group.loop <- function(prediction.grid,var.models,ts.ts,ts.un,curlH){
    config <- rcouchutils::get.config()

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

    predf <- data.predict.generator(prediction.grid,ts.un)
    model.names <- names(var.models)
    for (m in 1:length(var.models)){
        grid.pred <- predf(var.models[[m]])
        for(sim.site in 1:(length(df.all.predictions))){
            df.all.predictions[[sim.site]][,model.names[m]] <- grid.pred$Median[,sim.site]
        }
        rm(grid.pred)
    }

    rm(predf)
    ## for(model.name in names(var.models)){
    ##     grid.pred <- predictions[[model.name]]
    ##     for(sim.site in 1:(length(df.all.predictions))){
    ##         df.all.predictions[[sim.site]][,model.name] <- grid.pred$Median[,sim.site]
    ##     }
    ## }
    # gc()
    rearranger <- NULL
    doccount <- 0
    for(sim.site in 1:(length(df.all.predictions))){
        rnm <- names( df.all.predictions[[sim.site]] )

        rnm  <- gsub('.aadt.frac','',x=rnm)
        if(is.null(rearranger)){
            rearranger <- rearrange_data(rnm)
        }
        names( df.all.predictions[[sim.site]] ) <- rnm
        storedf <- list()
        for(i in 1:length(df.all.predictions[[sim.site]][['ts']])){
            storedf[[i]] <- rearranger(df.all.predictions[[sim.site]][i,])
            if(config$recheck){
                storedf[[i]][['modelversion']] <- config$recheck
            }
        }
        print(paste(sim.site,
                    storedf[[1]]['_id']))

        res <- rcouchutils::couch.bulk.docs.save(config$couchdb$grid_hpms,storedf,h=curlH)

        rm(storedf)

        doccount <- doccount + res
    }
    rm(df.all.predictions)
    gc()
    ## print(paste('saved',doccount,'docs'))
    return ()

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
        outpt[['aadt_frac']] <- aadtlist
        ## print(outpt)
        return (outpt)

    }
    return(anon)

}

##' Omit grid cells in HPMS data that overlap existing fwy grids
##'
##' @title no.overlap
##' @param df.fwy.data the cells with freeway data
##' @param df.hpms.grid.locations the cells with hpms data
##' @return less than or equal to df.hpms.grid.locations
##' @author James E. Marca
no.overlap <- function(df.fwy.data,df.hpms.grid.locations){
    geoids <- df.fwy.data$geo_id ## sort(unique(paste(df.fwy.data$i_cell, df.fwy.data$j_cell,'_')))
    overlap <- df.hpms.grid.locations$geo_id %in% geoids
    return(df.hpms.grid.locations[!overlap,])
}

##' Determine the grids that need to be processed
##'
##' This routine will run the hpms grids at the database and determine
##' which ones need to be processed still.  No point duplicating
##' effort.  Any grid with midnight on the current day in the DB does
##' not need doing for the day.  Any grid cell without midnight stored
##' in the DB is assumed to need processing.
##'
##' @title necessary.grids
##' @param df.fwy.data the grid cells with freeway data
##' @param df.hpms.grid.locations the grid cells with hpms data
##' @param year the year of analysis
##' @param curlH the curl handle
##' @return a possibly reduced list of df.hpms.grid.locations
##' @author James E. Marca
necessary.grids <- function(df.fwy.data,df.hpms.grid.locations,year,curlH){

    config <- rcouchutils::get.config()
    picker <- 1:length(df.hpms.grid.locations[,1])
    hpmstodo <- picker < 0 # default false

    ## handle time from df.fwy.data

    ## set up date to check if data in couchdb for hpms grid
    checkday <- min(df.fwy.data$day)
    if(checkday<10) checkday <- paste('0',checkday,sep='')
    checkmonth <- df.fwy.data$month[1] + 1
    ## month is one less than month, because javascript
    if(checkmonth < 10) checkmonth <- paste('0',checkmonth,sep='')
    ## form date part of checking URL for couchdb

    couch.test.date <- paste(paste(year,checkmonth,checkday,sep='-'),"23:00",sep=' ')
    ## note just checking a single date, the zero hour of the day.  If
    ## not there, assume whole day is missing.  If there, assume whole
    ## day is there too.
    ##
    ## couchdb library routine will escape ascii stuff if needed.

    print(paste('checking',couch.test.date))

    picker <- 1:length(df.hpms.grid.locations[,1])
    couch.test.docs <- paste(df.hpms.grid.locations$geo_id,couch.test.date,sep='_')
    incl.docs <- FALSE
    if(! is.null(config$recheck)){
        incl.docs <- TRUE
    }
    if(length(couch.test.docs) == 1){
        ## use get not alldocs
        doc <- rcouchutils::couch.get(db=config$couchdb$grid_hpms,
                                         docname=couch.test.docs)
        if('error' %in% names(doc)){
            ## error means doc not found, need to do this grid
            hpmstodo[1] <- TRUE
        }else{
            if(! is.null(config$recheck)){
                if(is.null(doc$modelversion)
                   || doc$modelversion < config$recheck){
                    ## done but needs redoing
                    hpmstodo[1] <- TRUE
                }
            }
        }
        ##print(doc)
        print(paste('checked',couch.test.date,'for 1 doc, missing',length(hpmstodo[hpmstodo])))
    }else{
        result <- rcouchutils::couch.allDocsPost(db=config$couchdb$grid_hpms,
                                                 keys=couch.test.docs,
                                                 include.docs=incl.docs,h=curlH)

        rows <- result$rows
        print(length(rows))
        for(i in 1:length(rows)){
            row <- rows[[i]]
            ## print(row$key)
            if('error' %in% names(row)){
                ## error means doc not found, need to do this grid
                hpmstodo[i] <- TRUE
                ## print(paste('todo',row$key,couch.test.docs[i]))
                ##true means need to do this document
            } else {
                ## no error means there is a doc.  If config says to
                ## recheck, check if there is a date
                if(! is.null(config$recheck)){
                    if(is.null(row$doc$modelversion)
                       || row$doc$modelversion < config$recheck){
                        ## done but needs redoing
                        hpmstodo[i] <- TRUE
                    }
                }
            }
        }
        print(paste('checked',couch.test.date,'for',length(rows),'rows, missing',length(hpmstodo[hpmstodo])))
    }
    return (df.hpms.grid.locations[hpmstodo,])

}


##' Assign a fraction because just one freeway cell
##'
##' At the moment this does nothing as it hasnt been tested and I want
##' to run the other cells first.
##'
##' @title assign.fraction
##' @param df.fwy.data the freeway grid cells (but really just one)
##' @param df.hpms.grid.locations the hpms grid cells
##' @param year the year, for writing to couchdb
##' @param curlH the curl handle for couchdb
##' @return nothing
##' @author James E. Marca
assign.fraction <- function(df.fwy.data,df.hpms.grid.locations,year,curlH){
    ## just assign frac to hpms cells
    picked <- 1:length(df.hpms.grid.locations[,1])
    ts2 <- strptime(df.fwy.data$ts,"%Y-%m-%d %H:%M",tz='UTC')
    ts.un <- sort(unique(ts2))
    ts.ct <- sort(unique(df.fwy.data$tsct))
    ts.ts = sort(unique(df.fwy.data$ts))
    config <- rcouchutils::get.config()
    rearranger <-  NULL


    for(sim.site in picked){
        df.all.predictions <- data.frame('ts'= ts.ts)
        df.all.predictions$i_cell <- df.hpms.grid.locations[sim.site,'i_cell']
        df.all.predictions$j_cell <- df.hpms.grid.locations[sim.site,'j_cell']
        df.all.predictions$geom_id <- df.hpms.grid.locations[sim.site,'geo_id']
        df.all.predictions['_id']  <- paste(df.all.predictions$geom_id,
                                            df.all.predictions$ts,
                                            sep='_')

        for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
            df.all.predictions[,variable] <- df.fwy.data[,variable]
        }

        if(dim(df.all.predictions)[2]>4){
            ## now dump that back into couchdb
            rnm <-  names(df.all.predictions)
            rnm  <- gsub('.aadt.frac','',x=rnm)
            names(df.all.predictions) <- rnm
            if(is.null(rearranger)){
                rearranger <- rearrange_data(rnm)
            }

            save.these <-  ! is.na(df.all.predictions$n)
            df.all.predictions <- df.all.predictions[save.these,]
            storedf <- list()

            for(i in 1:nrow(df.all.predictions)){
                storedf[[i]] <- rearranger(df.all.predictions[i,])
                ## print(paste(storedf[[i]]))
                if(config$recheck){
                    storedf[[i]][['modelversion']] <- config$recheck
                }

            }
            print(paste(sim.site,
                        storedf[[1]]['_id']))
            res <- rcouchutils::couch.bulk.docs.save(config$couchdb$grid_hpms,storedf,h=curlH)
        }
    }
    return ()
}

##' Predict fractions at HPMS grid cells based on models
##'
##' @title predict.hpms.data
##' @param df.fwy.data the freeway grid cells
##' @param df.hpms.grid.locations the hpms grid cells
##' @param var.models the models to use for predictions
##' @param year the year, for writing to the correct db entry
##' @param curlH the curl handle for couchdb
##' @return 0 or 1+
##' @author James E. Marca
predict.hpms.data <- function(df.fwy.data,df.hpms.grid.locations,var.models,year,curlH){

    ts2 <- strptime(df.fwy.data$ts,"%Y-%m-%d %H:%M",tz='UTC')
    ts.un <- sort(unique(ts2))
    ts.ct <- sort(unique(df.fwy.data$tsct))
    ts.ts = sort(unique(df.fwy.data$ts))
    n.times = length(ts.un)

    picked <- 1:length(df.hpms.grid.locations[,1])
    if(length(picked)>1)    picked = sample(picked)

    returnval <- 0

    dolimit <-  100  # the higher this number, the more likely to run out of ram

    # dolimit <- 200 # temporary hacking for all_california run
    if(length(picked)>dolimit){
        returnval <- length(picked) - dolimit
        ## just do 100 for now
        ## by chopping down hpms.idx
        keep.idx <- picked < 0 ## all of them are FALSE, of course
        ## only keep 100 values
        keep.idx[1:dolimit] <- TRUE
        picked <- picked[keep.idx]

    }

    print(paste('processing',length(picked),'cells'))


    num.cells = 250 # 100 ## 90 # min( 90, ceiling(80 * 11000 / length(batch.idx)))
    num.runs = ceiling(length(picked)/num.cells) ## manage RAM
    print(paste('num.runs is',num.runs,'which means number cells per run is about',floor(length(picked)/num.runs)))

    runs.index <- rep_len(1:num.runs,length.out = length(picked))

    ## random permutation of the grid cells I need to predict
    df.pred.grid <- df.hpms.grid.locations[picked,]

    ## remove try block here.  Didn't help the memory leak, but I
    ## don't see what it was doing anyway...fails happen in RCurl to
    ## couchdb, which is already wrapped in a try
    for (i in 1:max(runs.index)){
        ## print(paste('run',i,'memory',pryr::mem_used()))
        idx <- runs.index == i
        ## this used to use plyr, but made it a loop for now to help debugging
        group.loop(df.pred.grid[idx,],var.models,ts.ts,ts.un,curlH)

    }

    return (returnval)
}

##' Model fraction changes in space based on hourly freeway observations
##'
##' @title model.fwy.data
##' @param df.fwy.data the freeway grid cells
##' @return the models list
##' @author James E. Marca
model.fwy.data <- function(df.fwy.data){

    var.models <- plyr::llply(list('n.aadt.frac'='n.aadt.frac',
                                   'hh.aadt.frac' ='hh.aadt.frac',
                                   'nhh.aadt.frac'='nhh.aadt.frac'),
                              function(variable){
                                  data.model(df.fwy.data,formula=formula(paste(variable,1,sep='~')))
                              }
                              ##.parallel=TRUE
                              )
    return (var.models)

}

##' Step through the jobs for modeling and predicting
##'
##' @title processing.sequence
##' @param df.fwy.grid the freeway grid cells
##' @param df.hpms.grid.locations the hpms grid cells
##' @param year the year of this analysis
##' @param month the month
##' @param day the day
##' @param max.iter max iterations.  watch RAM
##' @return number left to do
##' @author James E. Marca
processing.sequence <- function(df.fwy.grid,
                                df.hpms.grid.locations,
                                year,month,day,basin,
                                maxiter=2){

    iter <- 0
    curlH <- RCurl::getCurlHandle()

    var.models <- list() # fetch.model(year,month,day,basin)
    df.fwy.data <- fetch.fwy.data(year,month,day,basin)
    hpms <- fetch.hpms(year,month,day,basin)

    if(length(dim(hpms)) == 2 && length(hpms[,1])<1){
        print(dim(hpms))

        print(paste('not going to start, all done'))
        ## rm(df.fwy.data)

        ## in order to signal the caller that we're already done and
        ## did no work at all, set the return state to -1, not zero
        return (-1)
    }

    if(length(df.fwy.data) == 0){

        df.fwy.data <- get.raft.of.grids(df.fwy.grid
                                        ,day=day
                                        ,month=month
                                        ,year=year)
        stash.fwy.data(year,month,day,basin,df.fwy.data)
    }
    if(length(dim(hpms)) == 0){

        hpms <- no.overlap(df.fwy.data,df.hpms.grid.locations)

        hpms <- necessary.grids(df.fwy.data,hpms,year,curlH)
        stash.hpms(year,month,day,basin,hpms)


    }

    if(length(hpms[,1])<1){
        print(paste('all done'))
        ## rm(df.fwy.data)

        ## save empties to reduce space needs
        stash.fwy.data(year,month,day,basin,list())
        ## in order to signal the caller that we're already done and
        ## did no work at all, set the return state to -1, not zero
        return (-1)
    }else{
        print(length(hpms[,1]))
    }

    if(length(unique(df.fwy.data$s.idx))<2){
        ## one cell is not enough freeway grid cells to build a
        ## spatial model.
        ##
        ## just assign fraction
        while(length(hpms[,1])>0){
            assign.fraction(df.fwy.data,hpms,year,curlH)

            hpms <- necessary.grids(df.fwy.data,hpms,year,curlH)

            stash.hpms(year,month,day,basin,hpms)
        }
    }else{
        ## still here, build model, then stash
        if(length(var.models) == 0){
            ## model, then predict
            print('building models')
            var.models <- model.fwy.data(df.fwy.data)
            print('saving models')
            ## stash.model(year,month,day,var.models)
        }else{
            print('using previously computed models')
        }

        ## predict

        predict.hpms.data(df.fwy.data,hpms,var.models,year,curlH)
        hpms <- necessary.grids(df.fwy.data,hpms,year,curlH)

        stash.hpms(year,month,day,basin,hpms)
    }
    rm(curlH)
    return(length(hpms[,1]))
}

##' Process a month of data day by day
##'
##' First step is to get the hour by hour data for the freeway grid
##' cells.  The second step is to model and predict, using plyr, one
##' day at a time, by running the processing.sequence function
##'
##' This can get out of hand.  RAM bug starts here
##'
##' @title process.data.by.day
##' @param df.grid the freeway grid cells, but not the data
##' @param df.hpms.grids the hpms grid cells
##' @param year the year of analysis
##' @param month the month to run this.
##' @return nothing at all
##' @author James E. Marca
process.data.by.day <- function(df.grid,df.hpms.grids,year,month,day,basin,maxiter=2){
    print (paste(year,month,day,pryr::mem_used()))
    ## don't care about true number of days per month
    returnval <- processing.sequence(df.grid,df.hpms.grids
                                    ,year=year
                                    ,month=month
                                    ,day=day
                                    ,basin=basin
                                    ,maxiter)

    return (returnval)
}
