library(ggplot2)
library(RJSONIO)
source('./getallthegrids.R')
source('./fetchFiles.R')
jsonfile <- file('../test/files/hourly/2008/133/154.json')
  rawjson <- fromJSON(jsonfile,simplify=FALSE)
  rows = rawjson$properties$data
  df <- ldply(pdata,.fun=function(x){unlist(x)[1:16]})
  names(df) <- default.header[1:16]
  df[,3:16] <- apply(df[,3:16],2,as.numeric)
  df[,2] <- as.factor(df[,2])
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
  df$tsct <- as.POSIXct(df$ts2)
  df <- ldply(rows,.fun=function(x){unlist(x)[1:16]})
  names(df) <- default.header[1:16]
  rows = rawjson$properties[[1]]$data
  df <- ldply(rows,.fun=function(x){unlist(x)[1:16]})
summary(df)
summary(rows)
summary(rawjson)
summary(rawjson$features)
summary(rawjson[['features']])
summary(rawjson[['features']][0])
summary(rawjson[['features']][[0]])
summary(rawjson$features[[0]])
summary(rawjson$features[[1]])
summary(rawjson$features[[1]]$properties)
summary(rawjson$features[[1]]$properties$data)
summary(rawjson$features[[1]]$properties$data)  rows <- rawjson$features[[1]]$properties$data
  rows <- rawjson$features[[1]]$properties$data
  df <- ldply(rows,.fun=function(x){unlist(x)[1:16]})
  names(df) <- default.header[1:16]
summary(df)
  df[,3:16] <- apply(df[,3:16],2,as.numeric)
  df[,2] <- as.factor(df[,2])
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
  df$tsct <- as.POSIXct(df$ts2)
d <- ggplot(df,aes(x=n/sum(n)))
d+geom_histogram()
g+stat_bin(geom="area")
d+stat_bin(geom="area")
d+stat_bin(geom="point")
d+stat_bin(geom="line")
sumn <- sum(df$n)
summary(df$n/sumn)
aadt.est <- sumn/356
summary(df$n/aadt.est)
d <- ggplot(df,aes(x=n/aadt.est))
d+geom_histogram()
d+stat_bin(geom="area")
d+stat_bin(geom="line")
d+coord_trans(x="log10")
qplot(log10(n/aadt.est),data=df,geom="histogram",binwidth=0.1)
filter <- df$n/aadt.est > 1
qplot(log10(n/aadt.est),data=df[filter,],geom="histogram",binwidth=0.1)
qplot(n/aadt.est,data=df[filter,],geom="histogram",binwidth=0.1)
qplot(n/aadt.est,data=df[filter,],geom="histogram")
summary(filter)
df[filter,'ts']
filter <- df$n/aadt.est > 0.5
summary(filter)
filter <- df$n/aadt.est >= 0.5
summary(filter)
aadt.est.filtered <- sum(df$n[filter])/356
qplot(n/aadt.est.filtered,data=df[filter,],geom="histogram")
aadt.est.filtered <- sum(df$n[!filter])/356
qplot(n,df$ts2$hour,data=df[!filter,],geom="")
qplot(log10(n/aadt.est.filtered),data=df[!filter,],geom="histogram")
summary(df$n[!filtered]/aadt.est.filtered)
summary(df$n[!filter]/aadt.est.filtered)
filter <- df$n/aadt.est.filtered > 1
aadt.est.filtered <- sum(df$n[!filter])/356
summary(df$n[!filter]/aadt.est.filtered)
filter <- df$n/aadt.est.filtered > 1
aadt.est.filtered <- sum(df$n[!filter])/356
summary(df$n[!filter]/aadt.est.filtered)
summary(filter)
summary(df$ts2$hour)
 p <- ggplot(df[!filter], aes(n, tsct$hour))
df$hour <- df$tsct$hour
 p <- ggplot(df[!filter], aes(n, ts2$hour))
df$hour <- df$ts2$hour
 p <- ggplot(df[!filter], aes(n, hour))
 p <- ggplot(df[!filter,], aes(n, ts2$hour))
 p + geom_point()
 p <- ggplot(df[filter,], aes(n, ts2$hour))
 p + geom_point()
 p <- ggplot(df[filter,], aes(log10(n), ts2$hour))
 p + geom_point()
 p <- ggplot(df, aes(log10(n), ts2$hour))
 p + geom_point()
p + geom_point(aes(colour = filter))
 p <- ggplot(df, aes(n, ts2$hour))
 p + geom_point()
p + geom_point(aes(colour = filter))
filter <- df$n/aadt.est > 1
p + geom_point(aes(colour = filter))
 p <- ggplot(df, aes(ts2$hour, n))
p + geom_point(aes(colour = filter))
q()
aadt.est.filtered
aadt.est.filtered <- sum(df$n[!filter])/356
aadt.est.filtered
aadt.est.filtered <- sum(df$n[!filter])/355
aadt.est.filtered <- sum(df$n[!filter])/357
aadt.est.filtered
summary(unique(df$ts2$date))
?POSIXlt
summary(unique(df$ts2$yday))
summary(unique(df$ts2[!filter]$yday))
aadt.est.filtered <- sum(df$n[!filter])/366
aadt.est.filtered
jsonfile <- file('../test/files/hourly/2009/100/263.json')
  rawjson <- fromJSON(jsonfile,simplify=FALSE)
summary(rawjson)
  rows <- rawjson$features[[1]]$properties$data
  df <- ldply(rows,.fun=function(x){unlist(x)[1:16]})
  names(df) <- default.header[1:16]
  df[,3:16] <- apply(df[,3:16],2,as.numeric)
  df[,2] <- as.factor(df[,2])
  df$ts2 <- strptime(df$ts,"%Y-%m-%d %H:%M",tz='UTC')
  df$tsct <- as.POSIXct(df$ts2)
aadt.est.filtered <- sum(df$n[!filter])/length(unique(df$ts2$yday))
aadt.est.filtered
length(unique(df$ts2$yday))
aadt.est <- sum(df$n)/length(unique(df$ts2$yday))
filter <- df$n/aadt.est > 1
aadt.est.filtered <- sum(df$n[!filter])/length(unique(df$ts2$yday))
aadt.est.filtered
aadt.est
aadt.est
q()
