source('./fetchFiles.R')

## get all the grids in a county
library('cclust')

library('RPostgreSQL')
m <- dbDriver("PostgreSQL")
## requires environment variables be set externally
psqlenv = Sys.getenv(c("PSQL_HOST", "PSQL_USER", "PSQL_PASS"))

spatialvds.con <-  dbConnect(m
                  ,user=psqlenv[2]
                  ,password=psqlenv[3]
                  ,host=psqlenv[1]
                  ,dbname="spatialvds")
osm.con <-  dbConnect(m
                  ,user=psqlenv[2]
                  ,password=psqlenv[3]
                  ,host=psqlenv[1]
                  ,dbname="osm")

get.all.the.grids <- function(basin){
  ## assume area is a county for now

  ## form a sql command

  grid.query <- paste( "select i_cell,j_cell,st_aswkt(st_centroid(grids.geom4326)) from carbgrid.state4k grids join public.carb_airbasins_aligned_03 basins where basin_name=",basin," and grids.geom4326 && basins.geom_4326" )
  print(wim.query)
  rs <- dbSendQuery(con,wim.query)
  df.wim <- fetch(rs,n=-1)
  df.wim

}

get.grids.with.hpms <- function(basin){
  grid.with = paste("with basingrids as (select i_cell,j_cell,"
,"st_centroid(grids.geom4326) as centroid"
,", geom4326"
," from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins"
," where basin_name='",basin,"' and grids.geom4326 && basins.geom_4326)",sep='')
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

get.grids.with.hpms.data <- function(basin){
  grid.with = paste("with basingrids as (select i_cell,j_cell,"
,"st_centroid(grids.geom4326) as centroid"
,", geom4326"
," from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins"
," where basin_name='",basin,"' and grids.geom4326 && basins.geom_4326)",sep='')
## select grid cells with hpm records in them
grid.query <- paste(grid.with
                    ," select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat"
                    ," sum(h.aadt),sum(h.section_length),h.weighted_design_speed,h.speed_limit,h.kfactor,h.
'perc_single_unit',
'avg_single_unit',
'perc_combination',
'avg_combination', "
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

get.grids.with.detectors <- function(basin){

  grid.with = paste("with basingrids as (select i_cell,j_cell,"
,"st_centroid(grids.geom4326) as centroid"
,", geom4326"
," from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins"
," where ab='",basin,"' and grids.geom4326 && basins.geom_4326)",sep='')

## select grid cells with tdetectors records in them
grid.query <- paste(grid.with
                    ," select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat"
                    ," from basingrids"
                    ," join tempseg.tdetector ttd on  st_intersects(ttd.geom,geom4326)"
                    ," group by i_cell,j_cell,lon,lat"
                    ,sep='')
  print(grid.query)
  rs <- dbSendQuery(osm.con,grid.query)
  df.grid <- fetch(rs,n=-1)
  df.grid
}

cluster.grids <- function(df.grid){

  cl.df.grid
}

process.grids <- function(df.grid){

}

library(cluster)

hpms.grid.couch.db <- 'carb%2Fgrid%2Fstate4k%2fhpms'


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


runme <- function(){

  gridenv = Sys.getenv(c("AIRBASIN"))
  basin = gridenv[1]
  df.grid <- get.grids.with.detectors(basin)
  df.grid$geo_id <- paste(df.grid$i_cell,df.grid$j_cell,sep='_')
  df.hpms.grids <- get.grids.with.hpms(basin)
  df.hpms.grids$geo_id <- paste(df.hpms.grids$i_cell,df.hpms.grids$j_cell,sep='_')

  months=1:12

  ## want clusters of about 20 ... 50 is too big if a cluster is too
  ## big, will split later into half the time period
  numclust = ceiling(dim(df.grid)[1] / 20)
  if(numclust > 5) numclust = 5
  print(paste('numclust is ',numclust))
  cl <- fanny(as.matrix(df.grid[,c('lon','lat')]),numclust)

  year = Sys.getenv(c("CARB_GRID_YEAR"))
  print(paste('processing',basin,year))
  for(cl.i in 1:numclust){
    idx <- cl$clustering==cl.i
    hpms.in.range <- get.hpms.in.range(df.hpms.grids,df.grid[idx,],expand=1)
    for(month in months){
      source('./monthloop.R')
    }
  }
}
runme()
