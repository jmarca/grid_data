##' Just preload data from couchdb, etc
##'
##' This function is similar to processing.sequence, but it does not
##' model, and does not predict.  It only loads the data into the fs
##' for use by the modeling runs.
##'
##' @title preloading.sequence
##' @param df.fwy.grid the freeway grid cells
##' @param df.hpms.grid.locations the hpms grid cells
##' @param year the year of this analysis
##' @param month the month
##' @param day the day
##' @param basin the basin (make this unique with iterant too)
##' @return number left to do
##' @author James E. Marca
preloading.sequence <- function(df.fwy.grid,
                                df.hpms.grid.locations,
                                year,month,day,basin){

    iter <- 0
    curlH <- RCurl::getCurlHandle()

    var.models <- list() # fetch.model(year,month,day,basin)
    df.fwy.data <- fetch.fwy.data(year,month,day,basin)
    hpms <- fetch.hpms(year,month,day,basin)

    if(length(dim(hpms)) == 2 && length(hpms[,1])<1){
        print(dim(hpms))

        print(paste('not going to start, all done'))
        ## rm(df.fwy.data)

        return (0)
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

        ## actually, I don't want to do this here
        ## stash.hpms(year,month,day,basin,hpms)


    }

    if(length(hpms[,1])<1){
        print(paste('all done'))
        ## rm(df.fwy.data)

        ## save empties to reduce space needs
        stash.fwy.data(year,month,day,basin,list())
        return (0)
    }else{
        print(length(hpms[,1]))
    }
    rm(curlH)
    return(length(hpms[,1]))
}

##' Preload a month of data day by day
##'
##' First step is to get the hour by hour data for the freeway grid
##' cells.  The second step is to model and predict, using plyr, one
##' day at a time, by running the preloading.sequence function
##'
##' This can get out of hand.  RAM bug starts here
##'
##' @title preload.data.by.day
##' @param df.grid the freeway grid cells, but not the data
##' @param df.hpms.grids the hpms grid cells
##' @param year the year of analysis
##' @param month the month to run this.
##' @param day the day
##' @param basin the basin (make it unique)
##' @return nothing at all
##' @author James E. Marca
preload.data.by.day <- function(df.grid,df.hpms.grids,year,month,day,basin,maxiter=2){
    print (paste(year,month,day,pryr::mem_used()))
    ## don't care about true number of days per month
    returnval <- preloading.sequence(df.grid,df.hpms.grids
                                    ,year=year
                                    ,month=month
                                    ,day=day
                                    ,basin=basin)

    return (returnval)
}
