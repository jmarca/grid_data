context("couch_access")

## TODO: Rename context
## TODO: Add more tests


test_that("get grid files",{
    i <- 161
    j <- 158
    month <- 2
    year <-  2012
    month.padded <- paste('0',month,sep='')
    start.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')
    month.padded <- paste('0',month+1,sep='')
    end.date <- paste( paste(year,month.padded,'01',sep='-'),'00:00')

    json.data <- get.grid.file.from.couch(i,j,
                                          start.date,
                                          end.date,
                                          include.docs=FALSE)

})
