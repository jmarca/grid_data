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
get.raft.of.grids <- function(df.grid.subset,year,month){

    curlH <- RCurl::getCurlHandle()

    ## df.grid.subset has a bunch of grids to get
    ## i_cell, j_cell
    ## make a start and end date
    month.padded=paste(month)
    if(month<10) month.padded=paste('0',month,sep='')
    start.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')
    month.padded=paste(month+1)
    if(month+1<10) month.padded=paste('0',month+1,sep='')
    end.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')
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
        ## df$Latitude  <- df.grid.subset[i,'lat']
        ## df$Longitude <- df.grid.subset[i,'lon']
        ## df$i_cell <- df.grid.subset[i,'i_cell']
        ## df$j_cell <- df.grid.subset[i,'j_cell']
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
        names(df.mrg)[c(29,30)] <- c("Longitude","Latitude")
    }
    df.mrg
}


##' Get rowcount of grids
##'
##' Something.  Probably dumb.  Calls get.grid.file.from.couch and
##' then returns the number of rows for the grid subset passed.  Seems
##' like a big waste of IO at this point, but maybe it is a great
##' idea.  Been a while since I've written this.
##'
##' @title get.rowcount.of.grids
##' @param df.grid.subset a subset of grids to get
##' @param year the year
##' @param month the month
##' @return a list of row counts for each of the cells in the grid subset
##' @author James E. Marca
get.rowcount.of.grids <- function(df.grid.subset,year,month){

    ## df.grid.subset has a bunch of grids to get
    ## i_cell, j_cell
    ## make a start and end date
    month.padded <- paste(month)
    if(month<10) month.padded <- paste('0',month,sep='')
    start.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')
    month.padded <- paste(month+1)
    if(month+1<10) month.padded <- paste('0',month+1,sep='')
    end.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')
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
