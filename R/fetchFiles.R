##' Get the grid file from a remote server.
##'
##' This function probably won't work because there aren't currently
##' any remote servers that are live for serving files.  However if
##' you do make one of those, then pass the URL of the server as the
##' 'server' argument.
##'
##' @title get.grid.file
##' @param i the i cell
##' @param j the j cell
##' @param server the URL of the file server you want to hit
##' @param service defaults to 'grid'.  The service on the remote server (the path)
##' @return the result of calling remoteFiles::load.remote.file, which
##'     at the moment isn't a real package so you'll probably be
##'     disappointed.
##' @author James E. Marca
get.grid.file <- function(i,j,server,service='grid'){

    remoteFiles::load.remote.file(server,service=service,root=paste('hourly',i,sep='/'),file=paste(j,'json',sep='.'))
}

# one connection per thread
# couchdb.handle = getCurlHandle()

##' Get the grid file from CouchDB
##'
##' This function is currently the one to use.  It gets the specified
##' grid cell data from a CouchDB database.
##'
##' @title get.grid.file.from.couch
##' @param i the i cell
##' @param j the j cell
##' @param start the start time
##' @param end the end time
##' @param include.docs boolean, defaults to TRUE.
##' @param curlH curl handle for couchdb
##' @return The result of calling rcouchutils::couch.allDocs()
##' @author James E. Marca
get.grid.file.from.couch <- function(i,j,start,end,include.docs=TRUE,curlH=NULL){

    config <- rcouchutils::get.config()
    start.date.part <- start
    end.date.part <-  end
    if(!is.character(start)){
        start.date.part <- format(start,"%Y-%m-%d %H:00")
        end.date.part <- format(end,"%Y-%m-%d %H:00")
    }

    query=list(
        'startkey'=paste(paste(i,j,start.date.part,sep='_'),sep=''),
        'endkey'=paste(paste(i,j,end.date.part,sep='_'),sep='')
    )
    json <- NULL
    if(is.null(curlH)){
        json <- rcouchutils::couch.allDocs(config$couchdb$grid_detectors, query=query, include.docs=include.docs)
    }else{
        json <- rcouchutils::couch.allDocs(config$couchdb$grid_detectors, query=query, include.docs=include.docs,h=curlH)
    }
    return(json)

}

##' Get the AADT value for a grid cell from CouchDB
##'
##' This function will get the AADT from the specified grid cell from
##' a CouchDB database.
##'
##' @title get.grid.aadt.from.couch
##' @param i the i cell
##' @param j the j cell
##' @param year the year
##' @return the result of rcouchutils::couch.get
##' @author James E. Marca
get.grid.aadt.from.couch <- function(i,j,year){
    config <- rcouchutils::get.config()
    ## when bug is fixed, make this i,j,year,aadt
    doc=paste(i,j,'aadt',sep='_')
    print('bug in aadt still')
    print(doc)
    json <- rcouchutils::couch.get(config$couchdb$grid_detectors ,
                                   docname=doc)
    return(json)
}

##' Get a raft of grids
##'
##' Get a raft of grids. Lots of them.  pass a subset
##' @title get.raft.of.grids
##' @param df.grid.subset a list of cells to grab
##' @param year the year
##' @param month the month
##' @return a dataframe built from repeated calls to get.grid.file.from.couch
##' @author James E. Marca
get.raft.of.grids <- function(df.grid.subset,year,month,day){

    curlH <- RCurl::getCurlHandle()

    ## df.grid.subset has a bunch of grids to get
    ## i_cell, j_cell
    ## make a start and end date
    month.padded <- paste(month)
    if(month<10) month.padded <- paste('0',month,sep='')
    day.padded <- paste(day)
    if(day<10) day.padded <- paste('0',day,sep='')
    start.date <- paste( paste(year,month.padded,day.padded,sep='-'),'00:00')
    day.padded <- paste(day+1)
    if(day+1<10) day.padded <- paste('0',day+1,sep='')
    end.date <- paste( paste(year,month.padded,day.padded,sep='-'),'00:00')
    df.bind <- data.frame()

    for(i in 1:length(df.grid.subset[,1])){
        json.data <- get.grid.file.from.couch(df.grid.subset[i,'i_cell'],
                                              df.grid.subset[i,'j_cell'],
                                              start.date,
                                              end.date,
                                              curlH=curlH)
        if('error' %in% names(json.data) || length(json.data$rows)<2) next
        ## print(length(json.data$rows))
        df <- parseGridRecord(json.data)
        rm(json.data)
        df$s.idx <- i
        ## patch aadt onto df
        if(dim(df.bind)[1]==0){
            df.bind <- df
        }else{
            df.bind <- rbind(df.bind,df)
        }
    }
    rm(curlH)

    ## maybe there is no data..
    df.mrg = data.frame()
    if(dim(df.bind)[1]>0){
        ## need time to be uniform for all sites
        ts.un <- sort(unique(df.bind$ts2))
        ##print(summary(ts.un))
        ##print('do posix')
        ts.psx <- as.POSIXct(ts.un)
        ##print('done posix')

        site.lat.lon <- unique(df.bind[,c('s.idx','i_cell','j_cell')])
        n <- length(ts.un)
        N <- length(site.lat.lon[,1])
        dat.mrg <- matrix(NA,n*N,6)
        dat.mrg[,1] <- sort(rep(site.lat.lon$s.idx,each=n)) ## site number
        dat.mrg[,2] <- rep(ts.un$year,N)+1900
        dat.mrg[,3] <- rep(ts.un$mon,N)
        dat.mrg[,4] <- rep(ts.un$mday,N)
        dat.mrg[,5] <- rep(ts.un$hour,N)
        dat.mrg[,6] <- rep(ts.psx,N)
        ##dat.mrg[,7] <- sort(rep(site.lat.lon$i_cell,each=n)) ## i_cell
        ##dat.mrg[,8] <- sort(rep(site.lat.lon$j_cell,each=n)) ## j_cell
        dimnames(dat.mrg)[[2]] <- c('s.idx','year','month','day','hour','tsct')##,'i_cell','j_cell')
        df.mrg <- as.data.frame(dat.mrg)
        ## first, slap in the correct i_cell, j_cell, for every cell
        ##print('adding i_cell, j_cell back in')
        df.mrg   <- merge(df.mrg,site.lat.lon  ,all=TRUE,by=c("s.idx"))
        ##print('merging data from couchdb')
        df.mrg   <- merge(df.mrg,df.bind       ,all=TRUE,by=c("s.idx","tsct",'i_cell','j_cell'))
        ##print('merging Lat, Lon')
        df.mrg <- merge(df.mrg,df.grid.subset,all.x=TRUE,all.y=FALSE,by=c('i_cell','j_cell'))
        names(df.mrg)[names(df.mrg) == 'lon'] <- 'Longitude'
        names(df.mrg)[names(df.mrg) == 'lat'] <- 'Latitude'
    }
    rm (df.bind)

    keep <- df.mrg$day == day
    return(df.mrg[keep,])
}

##' Make a canonical attachment name
##'
##' @title make.att.name
##' @param basin the basin, two letters
##' @param year the year.  Actually any year will do
##' @return the name, as a string
##' @author James E. Marca
make.att.name <- function(str,basin,year){
    return (paste(basin,str,year,'RData',sep='.'))
}

##' Retrieve the grid data dataframe from local filesystem
##'
##' Note that this uses RCurl to fetch a dataframe from couchdb as a
##' binary.  This works well in test, but under load I've had
##' craziness with RCurl, so if you start getting flaky errors check
##' here
##'
##' @title load.grid.data.from.fs
##' @param typ some string uniquifying the type of data to load.
##'     either 'hwy' or 'hpms' at the moment
##' @param basin the basin, two letter code
##' @param year the year
##' @return a data frame, retrieved from couchdb
##' @author James E. Marca
load.grid.data.from.fs <- function(typ,basin,year){
    df <- data.frame()
    dot_is <- getwd()
    attname <- make.att.name(typ,basin,year)
    file.path <- paste(dot_is,'data',attname,sep='/')
    exists.file <- dir(path=paste(dot_is,'data',sep='/'),pattern=attname)
    print(exists.file)
    if(length(exists.file) != 0){
        env <- new.env()
        res <- load(file=file.path,envir = env)
        df <- env[[res]]
    }
    return(df)
}

##' Save grid data for a basin to couchdb
##'
##' Rather than hitting PostgreSQL over and over and over again for
##' the same exact data with a rather expensive call, instead just do
##' it once and save it and use it from CouchDB
##'
##' @title attach.grid.data.to.couchdb
##' @param uniquestr some unique string.  'hwy' or 'hpms'
##' @param df.grid the data to save to couchdb as an attachment
##' @param basin the basin, two letter code
##' @param year the year
##' @return the result of the attach call.  Res is a list, wth members
##'     ok, id, rev, and ok should be TRUE
##' @author James E. Marca
attach.grid.data.to.couchdb <- function(uniquestr,df.grid,basin,year){
    config <- rcouchutils::get.config()
    db <- config$couchdb$grid_detectors
    docid <- paste(basin,sep='_')
    ## save the dataframe to a temp file
    ## attach sample RData file
    attname <- make.att.name(uniquestr,basin,year)

    dot_is <- getwd()
    file.path <- paste(dot_is,'data',attname,sep='/')
    print(file.path)
    save(df.grid,file=file.path,compress='xz')
    res <- rcouchutils::couch.attach(db,docid,file.path)

    return (res)
}
##' Un-Save grid data for a basin to couchdb
##'
##' Rather than hitting PostgreSQL over and over and over again for
##' the same exact data with a rather expensive call, instead just do
##' it once and save it and use it from CouchDB.  But then you have
##' more HPMS data , or more highway data, and you suddenly don't want
##' to use this data, but rather get new data.  So call this function
##'
##' @title detach.grid.data.from.couchdb
##' @param uniquestr some unique string.  'hwy' or 'hpms'
##' @param basin the basin, two letter code
##' @param year the year
##' @return the result of the attach call.  Res is a list, wth members
##'     ok, id, rev, and ok should be TRUE
##' @author James E. Marca
detach.grid.data.from.couchdb <- function(uniquestr,basin,year){
    config <- rcouchutils::get.config()
    db <- config$couchdb$grid_detectors
    docid <- paste(basin,sep='_')
    ## save the dataframe to a temp file
    ## attach sample RData file
    attname <- make.att.name(uniquestr,basin,year)

    res <- rcouchutils::couch.detach(db,docid,attname)
    return (res)
}
##' Retrieve the grid data dataframe from couchdb as an attachment
##'
##' Note that this uses RCurl to fetch a dataframe from couchdb as a
##' binary.  This works well in test, but under load I've had
##' craziness with RCurl, so if you start getting flaky errors check
##' here
##'
##' @title load.grid.data.from.couchdb
##' @param uniquestr the identifying string.  'hwy' or 'hpms'
##' @param basin the basin, two letter code
##' @param year the year
##' @return a data frame, retrieved from couchdb
##' @author James E. Marca
load.grid.data.from.couchdb <- function(uniquestr,basin,year){
    config <- rcouchutils::get.config()
    db <- config$couchdb$grid_detectors
    docid <- paste(basin,sep='_')
    attname <- make.att.name(uniquestr,basin,year)
    getres <- rcouchutils::couch.get.attachment(db,docid,attname)
    if(is.null(getres)){
        return (data.frame())
    }
    varnames <- names(getres)
    barfl <- getres[[1]][[varnames[1]]]
    dot_is <- getwd()
    file.path <- paste(dot_is,'data',attname,sep='/')
    exists.file <- dir(path=paste(dot_is,'data',sep='/'),pattern=varnames[1])
    ## print(exists.file)
    if(length(exists.file) == 0){
        save(barfl,file=file.path,compress='xz')
    }
    return(barfl)
}


##' Get rowcount of grids
##'
##' Calls get.grid.file.from.couch and
##' then returns the number of rows for the grid subset passed.  Seems
##' like a big waste of IO at this point, but maybe it is a great
##' idea.  Been a while since I've written this.
##'
##' passable idea.  the point is to only process cells that actually
##' have data.  No sense clustering on a cell if there is nothing in
##' it
##'
##' @title get.rowcount.of.grids
##' @param df.grid.subset a subset of grids to get
##' @param year the year
##' @param month the month
##' @return a list of row counts for each of the cells in the grid subset
##' @author James E. Marca
get.rowcount.of.grids <- function(df.grid.subset,year,month,day){

    ## df.grid.subset has a bunch of grids to get
    ## i_cell, j_cell
    ## make a start and end date
    month.padded <- paste(month)
    if(month<10) month.padded <- paste('0',month,sep='')
    day.padded <- paste(day)
    if(day<10) day.padded <- paste('0',day,sep='')
    start.date <- paste( paste(year,month.padded,day.padded,sep='-'),'00:00')

    day.padded <- paste(day+1)
    if(day+1<10) day.padded <- paste('0',day+1,sep='')
    end.date <- paste( paste(year,month.padded,day.padded,sep='-'),'00:00')

    df.grid.subset$rows <- 0
    for(i in 1:length(df.grid.subset[,1])){
        json.data <- get.grid.file.from.couch(df.grid.subset[i,'i_cell'],
                                              df.grid.subset[i,'j_cell'],
                                              start.date,
                                              end.date,
                                              include.docs=FALSE)
        if('error' %in% names(json.data) || length(json.data$rows)<2)
            next
        df.grid.subset$rows[i] <- length(json.data$rows)
    }
    ##print(df.grid.subset$rows)
    df.grid.subset$rows
}

##' Call this to save cl, df.hpms.grids, df.grid.data for next iteration
##'
##' Call stash to save cl, df.hpms.grids, df.grid.data to the
##' filesystem.  Trying to save multiple round trips and such for
##' loading, and also to fix the clustering so I can also fix the
##' model.
##'
##' @title stash
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @param cl the cl to save (cluster thing)
##' @param df.hpms.grids the hpms grids to save
##' @param df.grid.data the highway grid data to save
##' @return 1
##' @author James E. Marca
stash <- function(year,month,day,basin,cl,df.hpms.grids,df.grid.data){

    ## was going to save to couchdb, but faster just to stash locally
    savepath <- 'stash'
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,year,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,month,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,day,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,basin,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}

    save(cl,
         file=paste(savepath,'/cl.RData',sep=''),
         compress='xz')
    save(df.hpms.grids,
         file=paste(savepath,'/df.hpms.grids.RData',sep=''),
         compress='xz')
    save(df.grid.data,
         file=paste(savepath,'/df.grid.data.RData',sep=''),
         compress='xz')

    return (1)
}

##' Call this to fetch cl, df.hpms.grids, df.grid.data
##'
##' After you call stash, call this to fetch cl, df.hpms.grids,
##' df.grid.data from the filesystem
##'
##' @title fetch
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @return a list of [1] "cl" "df.hpms.grids" "df.grid.data"
##' @author James E. Marca
fetch.outer.data <- function(year,month,day,basin){
    result <- list()
    ## was going to save to couchdb, but faster just to stash locally
    savepath <- 'stash'

    savepath <- paste(savepath,year,month,day,basin,sep='/')
    if(file.exists(savepath)){
        env <- new.env()
        r1 <- load(file=paste(savepath,'/cl.RData',sep=''),envir=env)
        r2 <- load(file=paste(savepath,'/df.hpms.grids.RData',sep=''),envir=env)
        r3 <- load(file=paste(savepath,'/df.grid.data.RData',sep=''),envir=env)
        result[[r1]] <- env[[r1]]
        result[[r2]] <- env[[r2]]
        result[[r3]] <- env[[r3]]
    }
    return(result)
}
##' Make a path for saving RData between runs
##'
##' @title makepath
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the air basin or whatever
##' @return a path name string
##' @author James E. Marca
makepath <- function(year,month,day,basin){
    ## was going to save to couchdb, but faster just to stash locally
    savepath <- 'stash'
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,year,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,month,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,day,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}

    savepath <- paste(savepath,basin,sep='/')
    if(!file.exists(savepath)){dir.create(savepath)}
    return(savepath)
}

##' Call this to save the models
##'
##' @title stash.model
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @param models the models list
##' @return 1
##' @author James E. Marca
stash.model <- function(year,month,day,basin,models){

    savepath <- makepath(year,month,day,basin)
    save(models,
         file=paste(savepath,'/models.RData',sep=''),
         compress='xz')
    return (1)
}

##' Call this to fetch the models
##'
##' @title fetch.model
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @return the models
##' @author James E. Marca
fetch.model <- function(year,month,day,basin){
    result <- list()
    ## was going to save to couchdb, but faster just to stash locally
    savepath <- makepath(year,month,day,basin)
    savepath <- paste(savepath,'/models.RData',sep='')

    if(file.exists(savepath)){
        env <- new.env()
        r1 <- load(file=savepath,envir=env)
        return (env[[r1]])
    }else{
        return ()
    }
}

##' Call this to save the fwy.data
##'
##' @title stash.fwy.data
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @param fwy.data the fwy.data list
##' @return 1
##' @author James E. Marca
stash.fwy.data <- function(year,month,day,basin,fwy.data){

    savepath <- makepath(year,month,day,basin)
    save(fwy.data,
         file=paste(savepath,'/fwy.data.RData',sep=''),
         compress='xz')
    return (1)
}

##' Call this to fetch the fwy.data
##'
##' @title fetch.fwy.data
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @return the fwy.data
##' @author James E. Marca
fetch.fwy.data <- function(year,month,day,basin){
    result <- list()
    ## was going to save to couchdb, but faster just to stash locally
    savepath <- makepath(year,month,day,basin)
    savepath <- paste(savepath,'/fwy.data.RData',sep='')
    if(file.exists(savepath)){
        env <- new.env()
        r1 <- load(file=savepath,envir=env)
        return (env[[r1]])
    }else{
        return ()
    }
}

##' Call this to save the hpms
##'
##' @title stash.hpms
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @param hpms the hpms list
##' @return 1
##' @author James E. Marca
stash.hpms <- function(year,month,day,basin,hpms){

    savepath <- makepath(year,month,day,basin)
    save(hpms,
         file=paste(savepath,'/hpms.RData',sep=''),
         compress='xz')
    return (1)
}

##' Call this to fetch the hpms
##'
##' @title fetch.hpms
##' @param year the year
##' @param month the month
##' @param day the day
##' @param basin the airbasin
##' @return the hpms
##' @author James E. Marca
fetch.hpms <- function(year,month,day,basin){
    result <- list()
    ## was going to save to couchdb, but faster just to stash locally
    savepath <- makepath(year,month,day,basin)
    savepath <- paste(savepath,'/hpms.RData',sep='')
    if(file.exists(savepath)){
        env <- new.env()
        r1 <- load(file=savepath,envir=env)
        return (env[[r1]])
    }else{
        return ()
    }
}
