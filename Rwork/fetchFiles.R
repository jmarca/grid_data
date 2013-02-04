source('./remoteFiles.R')

get.grid.file <- function(i,j,server='http://calvad.ctmlabs.net'){

   load.remote.file(server,service='grid',root=paste('hourly',i,sep='/'),file=paste(j,'json',sep='.'))
}

