library(RJSONIO)

parseImputeRecord <- function(rawjson){
  ## trim it down
  properties <- rawjson$features[[1]]$properties
  gridData <- properties$data
  header <- properties$header
  ncol = length(header)
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)
  colnames(data.matrix) <- header
  df <- data.frame(data.matrix)
  df[,3:17] <- apply(df[,3:17],2,as.numeric)
  df$dashts <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
}
library(plyr)
default.header =c("ts","freeway","n","hh","not_hh","o","avg_veh_spd","avg_hh_weight","avg_hh_axles","avg_hh_spd","avg_nh_weight","avg_nh_axles","avg_nh_spd","miles","lane_miles","detector_count","detectors")
parseGridRecord <- function(rawjson){
  ## trim it down
  rows = rawjson$rows
  df <- ldply(rows,.fun=function(x){
    dd <- unlist(x$doc$data)[1:16]
    daadt <- unlist(x$doc$aadt_frac)
    c(dd,daadt)
  })
  names(df) <- c(default.header[1:16],'n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')
  df[,3:19] <- apply(df[,3:19],2,as.numeric)
  df[,2] <- as.factor(df[,2])
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
  df$tsct <- as.POSIXct(df$ts2)
  df
}

aadt.cols <- c('n.aadt.frac','hh.aadt.frac','nhh.aadt.frac')

dumpPredictionsToJSON <- function(chunk,bulk=TRUE){
  ## must split out text and numeric, so numbers don't get promoted to text
  if( ! '_id' %in% names(chunk) ){
    chunk[,'_id']=paste(chunk$geom_id,chunk$ts,sep='_')
  }
  colnames <- names(chunk)
  text.cols    <-  grep( pattern="^(_id|ts|geom_id|freeway|detectors)$",x=colnames,perl=TRUE)
  numeric.cols <-  grep( pattern="^(_id|ts|geom_id|freeway|detectors)$",x=colnames,perl=TRUE,invert=TRUE)
  aadt.cols = grep(pattern="^(n|hh|nhh)",x=colnames[numeric.cols],perl=TRUE)  
  numeric.data.json <- function(row){
    cellvals = toJSON(row[c(1,2)],collapse='')
    aadtvals = toJSON(row[aadt.cols],collapse='')
    cellvals = gsub("\\s+"," ",x=cellvals,perl=TRUE)
    cellvals = gsub("{|}","",x=cellvals,perl=TRUE)
    aadtvals = gsub("\\s+"," ",x=aadtvals,perl=TRUE)
    paste('{',cellvals,',"aadt_frac":',aadtvals,'}',sep='')
  }
  num.data <- apply(chunk[,numeric.cols],1,numeric.data.json)
  text.data <- list()
  if(length(text.cols) < 2){
    text.data <- toJSON(chunk[,text.cols],collapse='')
  }else{
    text.data <- apply(chunk[,text.cols],1,toJSON,collapse='')
  }
  bulkdocs <- gsub('} {',',',x=paste(num.data,text.data,collapse=','),perl=TRUE)
  if(bulk){  bulkdocs <- paste('{"docs":[',bulkdocs,']}') }
  bulkdocs
}



parseAADTRecord <- function(rawjson){
  ## just a doc, make it a df
  dfaadt <- data.frame(i_cell = rawjson$i_cell,
                   j_cell = rawjson$j_cell,
                   aadt.n = 0,
                   aadt.hh = 0,
                   aadt.nhh = 0
                   )
  ## sum these up
  l_ply(rawjson$aadt,.fun=function(x){
    dfaadt$aadt.n <<- dfaadt$aadt.n + x$n[1]
    dfaadt$aadt.hh <<-dfaadt$aadt.hh + x$hh[1]
    dfaadt$aadt.nhh <<- dfaadt$aadt.nhh + x$not_hh[1]
  })
  dfaadt
}


parseGridFile <- function(jsonfile){
  ## get it
  rawjson <- fromJSON(jsonfile,simplify=FALSE)
  ## trim it down
  rows <- rawjson$features[[1]]$properties$data
  df <- ldply(rows,.fun=function(x){unlist(x)[1:16]})
  names(df) <- default.header[1:16]
  df[,3:16] <- apply(df[,3:16],2,as.numeric)
  df[,2] <- as.factor(df[,2])
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
  df$tsct <- as.POSIXct(df$ts2)
  df
}
