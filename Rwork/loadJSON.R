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
  df <- ldply(rows,.fun=function(x){unlist(x$doc$data)[1:16]})
  names(df) <- default.header[1:16]
  df[,3:16] <- apply(df[,3:16],2,as.numeric)
  df[,2] <- as.factor(df[,2])
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
  df
}

%% ready to process 
