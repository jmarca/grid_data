##' A little script to save typing out the same bit of sql
##'
##' @title select.grids.in.basin
##' @param basin the basin
##' @return a string for use as a with or select statement
##' @author James E. Marca
select.grids.in.basin <- function(basin){

    select_statement <- paste(
        "select i_cell,j_cell,"
       ,"st_centroid(grids.geom4326) as centroid"
       ,", grids.geom4326 as geom4326"
       ," from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins"
       ," where ab='",basin
       ,"' and st_contains(basins.geom_4326,st_centroid(grids.geom4326))"
        ##        ,"' and basins.geom_4326 && grids.geom4326"
       ,sep='')
    if(basin ==  'California'){

        select_statement <- paste(
            "select i_cell,j_cell,"
           ,"st_centroid(grids.geom4326) as centroid"
           ,", grids.geom4326 as geom4326"
           ," from carbgrid.state4k grids"
           ,sep='')

    }
    return (select_statement)
}

##' Get all the grids in an airbasin shape with hpms data
##'
##' This function will hit postgresql and fetch all of the grid cells
##' that lie inside of the passed-in airbasin shape.  If you stare at
##' the query, you should see that the rule "inside" is that the
##' centroid of the grid lies inside of the shape.
##'
##' @title get.grids.with.hpms
##' @param basin the name of the basin (two letter abbreviation)
##' @param hpms_geom_table the hpms table to use defaults to hpms.hpms_geom
##' @return the result of the query: rows of i_cell,j_cell, centroid
##'     lon, centroid lat
##' @author James E. Marca
get.grids.with.hpms <- function(basin,hpms_geom_table='hpms.hpms_geom'){
    if(is.null(hpms_geom_table) || hpms_geom_table == ''){
        hpms_geom_table <- 'hpms.hpms_geom'
    }
    grid.with = paste("with basingrids as (",select.grids.in.basin(basin),")",sep='')
    ## select grid cells with hpm records in them
    grid.query <- paste(grid.with
                       ," select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat"
                       ," from basingrids"
                       ," join ",hpms_geom_table," hg on st_intersects(basingrids.geom4326,hg.geom)"
                       ##," join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)"
                       ," group by i_cell,j_cell,lon,lat"
                       ,sep='')
    print(grid.query)
    rs <- RPostgreSQL::dbSendQuery(spatialvds.con,grid.query)
    df.grid <- RPostgreSQL::fetch(rs,n=-1)
    df.grid$geo_id <- paste(df.grid$i_cell,df.grid$j_cell,sep='_')


    df.grid
}


##' Get all the grids in an airbasin shape with hpms data
##'
##' This function will first try to get from fs, then couchdb, then
##' will call postgresql version.
##'
##' @title load.grids.with.hpms
##' @param basin the name of the basin (two letter abbreviation)
##' @param year the year, for couchdb call/save
##' @return the result of the query: rows of i_cell,j_cell, centroid
##'     lon, centroid lat
##' @author James E. Marca
load.grids.with.hpms <- function(basin,year){

    df.grid <- load.grid.data.from.fs('hpms',basin,year)
    if(nrow(df.grid) == 0){
        df.grid <- load.grid.data.from.couchdb('hpms',basin,year)
    }
    if(nrow(df.grid) == 0){
        df.grid <- NULL
        if(year > 2010 && year <=  2014){
            df.grid <- get.grids.with.hpms(basin,config$postgresql$hpms_2014_table)
        }else{
            df.grid <- get.grids.with.hpms(basin,config$postgresql$hpms_table)
        }
        res <- attach.grid.data.to.couchdb('hpms',df.grid,basin,year)
        ## print(res)
    }
    return(df.grid)
}




##' Get grid cells overlapping highway detector segments (vds or wim).
##'
##' Get the grid cells that are likely to have data from the VDS/WIM detectors.
##'
##' @title get.grids.with.detectors
##' @param basin the air basin, two letter abbreviation
##' @return the results of the sql query, rows of
##'     {i_cell,j_cell,centroid lon,centroid lat}
##' @author James E. Marca
get.grids.with.detectors <- function(basin){
    grid.with = paste("with basingrids as (",select.grids.in.basin(basin),")",sep='')

    ## select grid cells with tdetectors records in them
    grid.query <- paste(grid.with
                       ," select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat"
                       ," from basingrids"
                       ," join tempseg.tdetector ttd on  st_intersects(ttd.geom,geom4326)"
                       ," group by i_cell,j_cell,lon,lat"
                       ,sep='')
    ## print(grid.query)
    rs <- RPostgreSQL::dbSendQuery(spatialvds.con,grid.query)
    df.grid <- RPostgreSQL::fetch(rs,n=-1)
    df.grid$geo_id <- paste(df.grid$i_cell,df.grid$j_cell,sep='_')
    df.grid
}

##' Get all the grids in an airbasin shape with hwy data
##'
##' This function will first try to get from fs, then couchdb, then
##' will call postgresql version.
##'
##' @title load.grids.with.hwy
##' @param basin the name of the basin (two letter abbreviation)
##' @param year the year, for couchdb call/save
##' @return the result of the query: rows of i_cell,j_cell, centroid
##'     lon, centroid lat
##' @author James E. Marca
load.grids.with.hwy <- function(basin,year){

    df.grid <- load.grid.data.from.fs('hwy',basin,year)
    if(nrow(df.grid) == 0){
        df.grid <- load.grid.data.from.couchdb('hwy',basin,year)
    }
    if(nrow(df.grid) == 0){
        df.grid <- get.grids.with.detectors(basin)
        res <- attach.grid.data.to.couchdb('hwy',df.grid,basin,year)
        ## print(res)
    }
    return(df.grid)
}

##' Pick off HPMS grids inside the effective "range" of detector grids
##'
##' basically just expands the grids by one in each direction, such
##' that you are pulling into the modeling run just the surrounding
##' hpms grids.  if you want more grids, expand the expand parameter,
##' say to 2 for two squares away.
##'
##' @title get.hpms.in.range
##' @param df.hpms.grids the hpms grids
##' @param df.grid the grids used for the next model run
##' @param expand an integer number of squares to expand;  default 1
##' @return a binary true false filter index, which is true if an hpms
##'     grid cell falls inside of 'expand' cells away from a df.grid
##'     cell, false otherwise.
##' @author James E. Marca
get.hpms.in.range <- function(df.hpms.grids,df.grid,expand=1){

    ## assume without proof that a cell can influence at least a few grid cells on either side.
    ## 4 km square, conservative guess is one square left right up down
    ## make it more with bigger value to expand parameter

    icell.min <- min(df.grid$i_cell) - expand
    icell.max <- max(df.grid$i_cell) + expand
    jcell.min <- min(df.grid$j_cell) - expand
    jcell.max <- max(df.grid$j_cell) + expand
    ## return value:
        df.hpms.grids$i_cell >= icell.min &
        df.hpms.grids$i_cell <= icell.max &
        df.hpms.grids$j_cell >= jcell.min &
        df.hpms.grids$j_cell <= jcell.max
}

##' Compute the manhattan distance between two lat, lon points
##'
##' @title compute.manhattan.distance
##' @param a a value with lat, lon
##' @param b a value with lat, lon
##' @return manhattan distance---that is, how many blocks over plus how many up
##' @author James E. Marca
compute.manhattan.distance <- function(a,b){
    abs(a$lat - b$lat) + abs(a$lon - b$lon)
}

##' Assign an HPMS grid cell to a cluster
##'
##' Assign an HPMS grid cell to a cluster.  Uses manhattan distance,
##' and clusters based on a next nearest neighbor rule.  Clustering is
##' needed because doing eerything at once chokes the ram and takes an
##' age to run.
##'
##' @title assign.hpms.grid.cell
##' @param centers the centers of clusters, for computing the intial distances
##' @return a function that will do the assigning.
##' @author James E. Marca
assign.hpms.grid.cell <- function(centers){
    assign.cell <- function(lon,lat=NULL){
        if(is.data.frame(lon)){
            lat <- lon$lat
            lon <- lon$lon
        }
        ## centers.distance <- ddply(centers,.(lat,lon,clustering),.fun=function(a){compute.manhattan.distance(a,hpms.cell)})
        centers.distance <- as.matrix(dist(matrix(c(lon,as.vector(centers$lon),lat,as.vector(centers$lat)),ncol=2,byrow=FALSE)))[,1]
        ## drop own distance
        centers.distance <-  centers.distance[-1]
        ## pick off which cluster has the min distance, ignoring ties
        assigned.cluster <- centers$clustering[centers.distance == min(centers.distance)]
        assigned.cluster <- c(assigned.cluster)[1]
        ##return (assigned.cluster)
        return(assigned.cluster)
        ##return(data.frame(cluster=assigned.cluster))
    }
}



##' The main function that does everything.
##'
##' @title runme
##' @return null
##' @author James E. Marca
##' @export
runme <- function(){

    year = as.numeric(Sys.getenv(c("CARB_GRID_YEAR"))[1])
    month = as.numeric(Sys.getenv(c("CARB_GRID_MONTH"))[1])
    day = as.numeric(Sys.getenv(c("CARB_GRID_DAY"))[1])
    basin = Sys.getenv(c("AIRBASIN"))[1]

    cl <- NULL
    df.hpms.grids <- NULL
    df.grid.data <- NULL

    retrieve.result <- fetch.outer.data(year,month,day,basin)


    if(length(retrieve.result) == 3){
        cl <- retrieve.result$cl
        df.hpms.grids <- retrieve.result$df.hpms.grids
        df.grid.data <- retrieve.result$df.grid.data
    }
    if(length(dim(df.hpms.grids))>0){
        # okay data saved
    }else{
        ## load data from couchdb attachments, if available
        df.grid <- load.grids.with.hwy(basin,year)

        ## cluster **ONLY** the grid cells with valid data
        data.count <- get.rowcount.of.grids(df.grid,
                                            day=day,month=month,year=year)

        df.grid.data <- df.grid[data.count>0,]



        if(nrow(df.grid.data) == 0){
            print('skipping, no data')
            return (0)
        }
        print('dim df hwy grid')
        print(dim(df.grid.data))


        df.hpms.grids <- load.grids.with.hpms(basin,year)
        print('dim df hpms grid')
        print(dim(df.hpms.grids))


        ## remember, fake days have no data, so you're safe here

        ## want clusters of about 20
        numclust <- ceiling(dim(df.grid.data)[1] / 20)
        if(numclust > 10) numclust = 10
        print(paste('numclust is ',numclust,'num grid cells is',nrow(df.grid.data)))
        cl <- NULL
        if(numclust > 1){
            cl <- cluster::clara(as.matrix(df.grid.data[,c('lon','lat')]),numclust,pamLike = TRUE,samples=100)
            centers <- as.data.frame(cl$medoids)
            centers$clustering = cl$clustering[rownames(cl$medoids)]

            ## create the assigning function based on the clustered centers
            ascl <- assign.hpms.grid.cell(centers)
            df.hpms.grids$cluster <- -1
            for(i in 1:length(df.hpms.grids$lat)){
                df.hpms.grids$cluster[i] <- ascl(df.hpms.grids[i,])
            }
        }else{
            ## everything is in one cluster
            df.hpms.grids$cluster <- 1
            cl <- data.frame('clustering'=1)
        }

        ## stash all of: cl, df.hpms.grids, df.grid.data by year, month,
        ## day, basin

        stash(year,month,day,basin,cl,df.hpms.grids,df.grid.data)
    }

    print(paste('processing',basin,year,month,day))

    ## first make sure that the clusters are not too big.  if so, catch next pas
    numclust <- max(df.hpms.grids$cluster)

    returnval <- 0
    maxiter <- max(1,ceiling(10/numclust))
                                        # temporary hacking for all_california run
    maxiter <- 1
    print(paste('starting model loop with maxiter=',maxiter))

    for(cl.i in 1:numclust){
        print(paste('cluster',cl.i,'of',numclust))
        grid.idx <- cl$clustering==cl.i
        hpms.idx <- df.hpms.grids$cluster==cl.i
        somereturnval <- process.data.by.day(df.grid.data[grid.idx,]
                                            ,df.hpms.grids[hpms.idx,],year=year
                                            ,month=month
                                            ,day=day
                                            ,basin=paste(basin,cl.i,numclust,sep='_')
                                            ,maxiter=maxiter)
        returnval <- max(returnval,somereturnval )
        ## add a break statement here.  The california-wide modeling
        ## runs have very large clusters, so running multiple clusters
        ## per R job results in a *lot* of leaked RAM.  So break if
        ## there something productive was done here
        if(returnval >=  0){
            returnval <- 1 ## did something, quitting.  force a revisit to this date
            break()
        }
    }
    if(returnval < 0){
        ## that means every iteration above returned "already
        ## done". but I don't want to return -1 to the caller, because
        ## that would be misunderstood.
        returnval <- 0
    }

    if(returnval == 0){
        ## save dummies to FS to reduce space
        ## stash(year,month,day,basin,list(),list(),list())

    }
    return (returnval)
}
