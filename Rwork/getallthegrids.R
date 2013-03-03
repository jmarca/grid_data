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

get.grids.with.detectors <- function(basin){

  grid.with = paste("with basingrids as (select i_cell,j_cell,"
,"st_centroid(grids.geom4326) as centroid"
,", geom4326"
," from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins"
," where basin_name='",basin,"' and grids.geom4326 && basins.geom_4326)",sep='')

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


runme <- function(){
  df.grid <- get.grids.with.detectors('SAN JOAQUIN VALLEY')
  df.grid$geo_id <- paste(df.grid$i_cell,df.grid$j_cell,sep='_')
  cl <- cl.df.grid<-cclust(as.matrix(df.grid[,c('lon','lat')]),5,20,verbose=TRUE,method="kmeans")
  n <- cl$ncenters

  df.hpms.grids <- get.grids.with.hpms('SAN JOAQUIN VALLEY')
  df.hpms.grids$geo_id <- paste(df.hpms.grids$i_cell,df.hpms.grids$j_cell,sep='_')
  
  for(i in 1:n){
    idx <- cl$cluster==i
    ## are we doing daily, monthly, what?  what canthe computer handle?
    ## start with monthly, go from there

    hpms.in.range <- df.hpms.grids$i_cell >= min(df.grid$i_cell[idx]) &
      df.hpms.grids$i_cell <= max(df.grid$i_cell[idx]) &
        df.hpms.grids$j_cell >= min(df.grid$j_cell[idx]) &
          df.hpms.grids$j_cell <= max(df.grid$j_cell[idx])
    hpms.subset <- df.hpms.grids[hpms.in.range,]
    ## eliminate overlaps
    geoids <- sort(unique(df.grid$geo_id))
    overlap <- hpms.subset$geo_id %in% geoids
    hpms.subset <- hpms.subset[!overlap,]
    year <- 2007

    for(month in 1:12){
      ## data.fetch has to get data for all the grid cells, by month, year
      df.data <- get.raft.of.grids(df.grid[idx,],month=month,year=year,local=FALSE)
      ## df.data <- get.raft.of.grids(df.grid,month=month,year=year,local=FALSE)
      ## data.pred will model the data, and then predict median fraction
      ## for passed in hpms grids
      df.all.predictions <- data.frame()
      for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
        post.gp.fit <- data.model(df.data,formula=formula(paste(variable,1,sep='~')))
        ## loop and simulate
        simlim <- length(hpms.subset[,1])
        picker <- 1:simlim
                                        # just do one at a time for now
        df.pred.result = data.frame()
        ts.un <- sort(unique(df.data$ts2))
        n.times = length(ts.un)
        for(iter in 1:simlim){ 
          sim.set <- picker[iter]
          df.pred.grid <- hpms.subset[sim.set,]
          grid.pred <-  data.predict(post.gp.fit,df.pred.grid,ts.un)
          ## save this in df.pred.result
          df.predicted <- data.frame(var=grid.pred$Median)
          names(df.predicted) <- variable
          df.predicted$i_cell <- hpms.subset[sim.set,'i_cell']
          df.predicted$j_cell <- hpms.subset[sim.set,'j_cell']
          df.predicted$geom_id<- hpms.subset[sim.set,'geo_id']
          if(dim(df.pred.result)[1]==0){
            df.pred.result <<- df.predicted
          }else{
            df.pred.result <<- rbind(df.pred.result,df.predicted)
          }
        }
        df.pred.result$tsct <- sort(unique( df.data$tsct))
        ## now save the predictions in df.prediciton, and loop over the variables
        if(dim(df.all.predictions)[1]==0){
          df.all.predictions <<- df.pred.result
        }else{
          ## use merge here
          df.all.predictions <<- merge(df.all.predictions,df.pred.result)
        }
      }
      ## now dump that back into couchdb
      ## slap on ts from the original data
      df.all.predictions$ts = sort(unique(df.data$ts))
      df.all.predictions$tsct <- NULL
      rnm = names(df.all.predictions)
      names(df.all.predictions) <- gsub('.aadt.frac','',x=rnm)
      ## need to clean up the mess from the bad save, with a view and then a bulk delete
      couch.bulk.docs.save('carb%2Fgrid%2Fstate4k%2fhpms',df.all.predictions,local=TRUE,makeJSON=dumpPredictionsToJSON)
    }
  }
}
