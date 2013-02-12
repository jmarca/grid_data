source('./safetylib/remoteFiles.R')
source('./safetylib/couchUtils.R')

get.grid.file <- function(i,j,server='http://calvad.ctmlabs.net'){

   load.remote.file(server,service='grid',root=paste('hourly',i,sep='/'),file=paste(j,'json',sep='.'))
}

get.grid.file.from.couch <- function(i,j,start,end,local=TRUE){

  start.date.part <- format(start,"%Y-%m-%d %H:00")
  end.date.part <- format(end,"%Y-%m-%d %H:00")
  
  query=list(
    'startkey'=paste('%22',paste(i,j,start.date.part,sep='_'),'%22',sep=''),
    'endkey'=paste('%22',paste(i,j,end.date.part,sep='_'),'%22',sep='')
    )
  json <- couch.allDocs('carb%2fgrid%2fstate4k' , query=query, local=local)
  return(json)
}

