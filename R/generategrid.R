## pick a swath of grid cells, get all the sites in it

## not sure how to do that...start at the top and work down, across
## until I find something?  Sure.  But do it with couchdb.  get the
#_# first, then get the neightbors in space

# or just get "all the grids in a county with data"


site.union <- rbind(df.129.160,df.130.160,df.131.160)
ts.unq <- sort(unique(site.union$ts2))


dat.mrg <- matrix(NA,length(ts.un)*n.pred,6)
dat.mrg[,1] <- sort(rep(1:n.pred,N))
dat.mrg[,2] <- rep(ts.un$year,n.pred)+1900
dat.mrg[,3] <- rep(ts.un$mon,n.pred)
dat.mrg[,4] <- rep(ts.un$mday,n.pred)
dat.mrg[,5] <- rep(ts.un$hour,n.pred)

