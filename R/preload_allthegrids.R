##' The main function that does everything.
##'
##' @title run.preloading
##' @return null
##' @author James E. Marca
##' @export
run.preloading <- function(){

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

    print(paste('preloading',basin,year,month,day))

    ## first make sure that the clusters are not too big.  if so, catch next pas
    numclust <- max(df.hpms.grids$cluster)

    returnval <- 0

    for(cl.i in 1:numclust){
        print(paste('cluster',cl.i,'of',numclust))
        grid.idx <- cl$clustering==cl.i
        hpms.idx <- df.hpms.grids$cluster==cl.i
        somereturnval <- preload.data.by.day(df.grid.data[grid.idx,]
                                            ,df.hpms.grids[hpms.idx,]
                                            ,year=year
                                            ,month=month
                                            ,day=day
                                            ,basin=paste(basin,cl.i,numclust
                                                        ,sep='_')
                                             )
        returnval <- max(returnval,somereturnval )
    }
    return (returnval)
}
