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

get.grids.with.detectors <- function(basin){

  grid.with = paste("with basingrids as (select i_cell,j_cell,"
,"st_centroid(grids.geom4326) as centroid"
,", geom4326"
," from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins"
," where basin_name='",basin,"' and grids.geom4326 && basins.geom_4326)",sep='')

## select grid cells with hpm records in them
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
  cl.df.grid<-cclust(as.matrix(df.grid[,c('lon','lat')]),3,20,verbose=TRUE,method="kmeans")
  cl.df.grid
}
  
process.grids <- function(df.grid){
  
}

df.grid <- get.grids.with.detectors('SAN JOAQUIN VALLEY')
cl <- cluster.grids(df.grid)
n <- cl$ncenters
for(i=1;i<=n;i++){
  idx <- cl$cluster==i
  ## are we doing daily, monthly, what?  what canthe computer handle?
  ## start with monthly, go from there
  year=2009
  for(month=0;month<12;month++){
    ## data.fetch has to get data for all the grid cells, by month, year
    df.data <- data.fetch(df.grid[idx,],month=month,year=year)
    ## data.pred will model the data, and then predict median fraction
    ## for passed in hpms grids
    df.pred <- data.pred(df.data,hpms.grids)
  }
  
}
