months=1:12
if(year==2007){
   months <- c(3,4,5,6,7,8,9,10,11,12)
}
    for(month in months){
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
