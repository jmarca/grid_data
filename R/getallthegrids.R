##' A little script to save typing out the same bit of sql
##'
##' @title select.grids.in.basin
##' @param basin the basin
##' @return a string for use as a with or select statement
##' @author James E. Marca
select.grids.in.basin <- function(basin){
   paste("select i_cell,j_cell,"
        ,"st_centroid(grids.geom4326) as centroid"
        ,", grids.geom4326 as geom4326"
        ," from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins"
        ," where ab='",basin
        ,"' and st_contains(basins.geom_4326,st_centroid(grids.geom4326))"
        ,sep='')
}

##' Get all the grids in an airbasin shape
##'
##' This function will hit postgresql and fetch all of the grid cells
##' that lie inside of the passed-in airbasin shape.  If you stare at
##' the query, you should see that the rule "inside" is that the
##' centroid of the grid lies inside of the shape.
##'
##' @title get.all.the.grids
##' @param basin the name of the basin (two letter abbreviation)
##' @return the result of the query:  rows of i_cell,j_cell, grid centroid
##' @author James E. Marca
get.all.the.grids <- function(basin){
  ## assume area is a county for now

  ## form a sql command

  grid.query <- select.grids.in.basin(basin)
  print(grid.query)
  rs <- dbSendQuery(con,grid.query)
  df.grid <- fetch(rs,n=-1)
  df.grid

}

##' Get all the grids in an airbasin shape with hpms data
##'
##' This function will hit postgresql and fetch all of the grid cells
##' that lie inside of the passed-in airbasin shape.  If you stare at
##' the query, you should see that the rule "inside" is that the
##' centroid of the grid lies inside of the shape.
##'
##' @title get.all.the.grids
##' @param basin the name of the basin (two letter abbreviation)
##' @return the result of the query: rows of i_cell,j_cell, centroid
##'     lon, centroid lat
##' @author James E. Marca
get.grids.with.hpms <- function(basin){
    grid.with = paste("with basingrids as (",select.grids.in.basin(basin),")",sep='')
    ## select grid cells with hpm records in them
    grid.query <- paste(grid.with
                       ," select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat"
                       ," from basingrids"
                       ," join hpms.hpms_geom hg on st_intersects(basingrids.geom4326,hg.geom)"
                       ," join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)"
                       ," group by i_cell,j_cell,lon,lat"
                       ,sep='')
    print(grid.query)
    rs <- dbSendQuery(spatialvds.con,grid.query)
    df.grid <- fetch(rs,n=-1)
    df.grid
}

## not used, and untested, and it was broken when I was editing it
## just now so commented out
##
## get.grids.with.hpms.data <- function(basin){
##     grid.with = paste("with basingrids as (",select.grids.in.basin(basin),")",sep='')

##     ## select grid cells with hpm records in them
##     grid.query <- paste(grid.with
##                        ," select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat"
##                        ," sum(h.aadt),sum(h.section_length),h.weighted_design_speed,h.speed_limit,h.kfactor,"
##                        ," h.perc_single_unit,h.avg_single_unit,h.perc_combination,h.avg_combination "
##                        ," from basingrids"
##                        ," join hpms.hpms_geom hg on st_intersects(basingrids.geom4326,hg.geom)"
##                        ," join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)"
##                        ," group by i_cell,j_cell,lon,lat"
##                        ,sep='')
##     print(grid.query)
##     rs <- dbSendQuery(spatialvds.con,grid.query)
##     df.grid <- fetch(rs,n=-1)
##     df.grid
## }

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
    print(grid.query)
    rs <- dbSendQuery(spatialvds.con,grid.query)
    df.grid <- fetch(rs,n=-1)
    df.grid
}


hpms.grid.couch.db <- 'carb%2Fgrid%2Fstate4k%2fhpms'

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

##' assign a cell to a cluster
##'
##' This is a function that is inside.
##' @title assign.cell
##' @param hpms.cell the current cell that needs assigning
##' @return the assigned cluster
##' @author James E. Marca
    assign.cell <- function(hpms.cell){
        centers.distance <- ddply(centers,.(lat,lon,clustering),.fun=function(a){compute.manhattan.distance(a,hpms.cell)})
        min.distance <- min(centers.distance$V1)
        assigned.cluster <- centers.distance$clustering[min.distance==centers.distance$V1]
        return(assigned.cluster[1]) ## prevent duplicates
    }
}

## source('./data.model.R')

##' The main function that does everything.
##'
##' @title runme
##' @return null
##' @author James E. Marca
##' @export
runme <- function(){

  year = Sys.getenv(c("CARB_GRID_YEAR"))
  gridenv = Sys.getenv(c("AIRBASIN"))
  basin = gridenv[1]
  df.grid <- get.grids.with.detectors(basin)
  df.grid$geo_id <- paste(df.grid$i_cell,df.grid$j_cell,sep='_')
  df.hpms.grids <- get.grids.with.hpms(basin)
  df.hpms.grids$geo_id <- paste(df.hpms.grids$i_cell,df.hpms.grids$j_cell,sep='_')

  months=1:12
  for(month in months){

      ## cluster **ONLY** the grid cells with valid data
      data.count <- get.rowcount.of.grids(df.grid,month=month,year=year,local=TRUE)
      df.grid.data <- df.grid[data.count>0,]

      ## want clusters of about 20
      numclust = ceiling(dim(df.grid.data)[1] / 20)
      if(numclust > 10) numclust = 10
      print(paste('numclust is ',numclust,'dims is',dim(df.grid.data)[1]))
      if(numclust > 0){
        cl <- cluster::clara(as.matrix(df.grid.data[,c('lon','lat')]),numclust,pamLike = TRUE,samples=100)
        centers <- as.data.frame(cl$medoids)
        centers$clustering = cl$clustering[rownames(cl$medoids)]
        assign.cluster <- ddply(df.hpms.grids,.(i_cell,j_cell,lon,lat,geo_id),.fun=assign.hpms.grid.cell(centers))
        print(paste('processing',basin,year))

        for(cl.i in 1:numclust){
          print(paste('cluster',cl.i,'of',numclust))
          grid.idx <- cl$clustering==cl.i
          hpms.idx <- assign.cluster$V1==cl.i
          process.data.by.day(df.grid.data[grid.idx,],assign.cluster[hpms.idx,],year,month,local=TRUE)
        }
     }else{
       print('skipping, no data')
     }
  }
}
## runme()
