hpms.grid.couch.db <- 'carb%2Fgrid%2Fstate4k%2fhpms'
months=1:12

for(month in months){

  ## form date part of checking URL for couchdb
  couch.test.date <- paste(paste(year,month,'01',sep='-'),"00%3A00",sep='%20')
  if(month < 10){
    monthstr <- paste('0',month,sep='')
    couch.test.date <- paste(paste(year,monthstr,'01',sep='-'),"00%3A00",sep='%20')
  }
  ## data.fetch has to get data for all the grid cells, by month, year
  df.data <- get.raft.of.grids(df.grid[idx,],month=month,year=year,local=FALSE)
  ## df.data <- get.raft.of.grids(df.grid,month=month,year=year,local=FALSE)
  ## data.pred will model the data, and then predict median fraction
  ## for passed in hpms grids
  df.all.predictions <- data.frame()

  ## here I have to do the subset thing...
  hpms.subset <- df.hpms.grids[hpms.in.range,]
  ## eliminate overlaps
  geoids <- sort(unique(paste(df.data$i_cell, df.data$j_cell,'_')))
  overlap <- hpms.subset$geo_id %in% geoids
  hpms.subset <- hpms.subset[!overlap,]
      
  ## now loop over the variables to model and predict
  for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
    ## model
    post.gp.fit <- data.model(df.data,formula=formula(paste(variable,1,sep='~')))

    ## loop over hpms cells,  and simulate what should be there
    simlim <- length(hpms.subset[,1])
    picker <- 1:simlim
                                        # just do one at a time for now
    df.pred.result = data.frame()
    ts.un <- sort(unique(df.data$ts2))
    n.times = length(ts.un)
    for(iter in 1:simlim){ 
      sim.set <- picker[iter]
      df.pred.grid <- hpms.subset[sim.set,]

      ## abort if already done in couchdb
      couch.test.doc <- paste(df.pred.grid$geo_id,couch.test.date,sep='_')
      test.doc.json <- couch.get(hpms.grid.couch.db,couch.test.doc,local=TRUE)
      if(test.doc.json$error != "not_found") next
      print(paste('processing',couch.test.doc))

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
  couch.bulk.docs.save(hpms.grid.couch.db,df.all.predictions,local=TRUE,makeJSON=dumpPredictionsToJSON)
}
