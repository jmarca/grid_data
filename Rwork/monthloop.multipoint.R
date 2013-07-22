## this is sourced in getallthegrids.R, **inside** of the "runme"
## loop.  for month in months source ./monthloop.R.  So this really is
## run, once per month

monthloop <- function(df.grid,month,year,df.hpms.grids,hpms.in.range,idx,local=FALSE){

  gc()
  ## data.fetch has to get data for all the grid cells, by month, year
  print (month)
  df.data <- get.raft.of.grids(df.grid[idx,],month=month,year=year,local=local)
  ## df.data <- get.raft.of.grids(df.grid,month=month,year=year,local=FALSE)
  ## data.pred will model the data, and then predict median fraction
  ## for passed in hpms grids

  ## sometimes there just isn't any data
  if(dim(df.data)[1]==0){
    print(paste('no data for',year,month,'cluster index',idx))
  }else{

  ## here I have to do the subset thing...
  hpms.subset <- df.hpms.grids[hpms.in.range,]
  ## eliminate overlaps
  geoids <- sort(unique(paste(df.data$i_cell, df.data$j_cell,'_')))
  overlap <- hpms.subset$geo_id %in% geoids
  hpms.subset <- hpms.subset[!overlap,]

  ## loop over hpms cells,  and simulate what should be there
  simlim <- length(hpms.subset[,1])
  picker <- 1:simlim
                                        # just do one at a time for now

  ## okay, now loop *IF* the size of df.data is unmanageable
  ## in testing, dim(df.data)[1] =  17135 broke the model
  ## so, if up to half of that, chop days in half

  ## lordy I hate R.  so clunky

  ## this is horrible code that needs to be fixed, but I just want to move on

  usethese <- list(1:dim(df.data)[1])
  if( dim(df.data)[1] > 8000 ){
      # split into halves
    maxday <- max(df.data$day)
    batch1 <- df.data$month == month-1 & df.data$day <= maxday/2
    batch2 <- !batch1
    usethese = list(batch1,batch2)
  }

  for(batch.idx in usethese){
    batch <- df.data[batch.idx,]

      ts.un <- sort(unique(batch$ts2))
      ts.ct <- sort(unique( batch$tsct))
      ts.ts = sort(unique(batch$ts))
      n.times = length(ts.un)

    minday <- min(batch$day)+1
    if(minday<10) minday <- paste('0',minday,sep='')
    monthstr = month
    if(month < 10) monthstr <- paste('0',month,sep='')
    ## form date part of checking URL for couchdb
    couch.test.date <- paste(paste(year,monthstr,minday,sep='-'),"00%3A00",sep='%20')
    print(paste('checking',couch.test.date))
    hpmstodo <- picker > 0
    for(cell in picker){
      ## abort if already done in couchdb
      df.pred.grid <- hpms.subset[cell,]
      couch.test.doc <- paste(df.pred.grid$geo_id,couch.test.date,sep='_')
      test.doc.json <- couch.get(hpms.grid.couch.db,couch.test.doc,local=TRUE)
      if('error' %in% names(test.doc.json) ){
        hpmstodo[cell] <- TRUE ## true means need to do this document
      } else {
        hpmstodo[cell] <- FALSE ## false means doc is dropped from index
      }
    }
    print(length(picker[hpmstodo]))
    if(length(picker[hpmstodo])<1){
      next
    }
    picked = picker[hpmstodo]
    if(length(picked)>1)    picked = sample(picked) ## randomly permute

    if(length(unique(df.data$s.idx))<2){
       ## just assign frac to hpms cells
      for(sim.set in picked){
        df.pred.grid <- hpms.subset[sim.set,]
        couch.test.doc <- paste(df.pred.grid$geo_id,couch.test.date,sep='_')
        test.doc.json <- couch.get(hpms.grid.couch.db,couch.test.doc,local=TRUE)
        if('error' %in% names(test.doc.json) ){
          print(paste('processing',couch.test.doc))
          df.all.predictions <- data.frame('ts'= ts.ts)
          df.all.predictions$i_cell <- hpms.subset[sim.set,'i_cell']
          df.all.predictions$j_cell <- hpms.subset[sim.set,'j_cell']
          df.all.predictions$geom_id <- hpms.subset[sim.set,'geo_id']

          for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
            df.all.predictions[,variable] <- df.data[,variable]
          }
          if(dim(df.all.predictions)[2]>4){
            ## now dump that back into couchdb
            rnm = names(df.all.predictions)
            names(df.all.predictions) <- gsub('.aadt.frac','',x=rnm)
            save.these = ! is.na(df.all.predictions$n)
            couch.bulk.docs.save(hpms.grid.couch.db,df.all.predictions[save.these,],local=TRUE,makeJSON=dumpPredictionsToJSON)
          }
        }
      }
    }else{
      ## more than one cell, need to model, can't just copy
      ## now loop over the variables to model and predict

      var.models <- list()
      for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
        var.models[[variable]] <- data.model(batch,formula=formula(paste(variable,1,sep='~')))
      }
      gc()
      ##for(sim.set in picked){
      num.runs = ceiling(length(picked)/90) ## manage RAM
      index=rep_len(1:num.runs,length=length(picked))
      for(group in 1:num.runs){

        some.picked <- picked[index==group]
        df.pred.grid <- hpms.subset[some.picked,]
        ## df.pred.grid <- hpms.subset[picked,]

        df.all.predictions = list()
        for(sim.site in 1:(length(some.picked))){
          df.all.predictions[[sim.site]] <- data.frame('ts'= ts.ts)
          df.all.predictions[[sim.site]]$i_cell  <- df.pred.grid[sim.site,'i_cell']
          df.all.predictions[[sim.site]]$j_cell  <- df.pred.grid[sim.site,'j_cell']
          df.all.predictions[[sim.site]]$geom_id <- df.pred.grid[sim.site,'geo_id']
        }

        for(variable in c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')){
          ## model
          post.gp.fit <- var.models[[variable]]
          grid.pred <- list()
          gc()
          pred.result <- try (grid.pred <-  data.predict(post.gp.fit,df.pred.grid,ts.un))
          if(class(pred.result) == "try-error"){
            print ("\n Error predicting \n")
          }else{
            ## save the median prediction

            ##> dim(grid.pred$Median)
            ##[1] 745  86
            for(sim.site in 1:(length(some.picked))){
              df.all.predictions[[sim.site]][,variable] <- grid.pred$Median[,sim.site]
            }
          }
          grid.pred <- list()
        }
        gc()
        if(dim(df.all.predictions[[1]])[2]>4){
          ## now dump that back into couchdb
          for(sim.site in 1:(length(some.picked))){
            rnm = names(df.all.predictions[[sim.site]])
            names(df.all.predictions[[sim.site]]) <- gsub('.aadt.frac','',x=rnm)
            couch.bulk.docs.save(hpms.grid.couch.db,df.all.predictions[[sim.site]],local=TRUE,makeJSON=dumpPredictionsToJSON)
          }
        }
      }
    } ## loop to the next grid cell
  }## loop to the next batch
}
