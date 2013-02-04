library(RJSONIO)

parseFile <- function(fileref){
  firstcut <- fromJSON(fileref)
  ## trim it down
  properties <- firstCut$features[[1]]$properties
  gridData <- properties$data
  header <- properties$header
  ncol = length(header)
  data.matrix <- matrix(unlist(gridData[1:12]),byrow=TRUE,ncol=ncol)
  colnames(data.matrix) <- header
  df <- data.frame(data.matrix)
  df[,3:17] <- apply(df[,3:17],2,as.numeric)
  df$dashts <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
}


