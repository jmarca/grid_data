context("check parseGridRecord")

config <- rcouchutils::get.config()

rcouchutils::couch.makedb(config$couchdb$grid_detectors)
##rcouchutils::couch.makedb(config$couchdb$grid_hpms)

## populate that db with appropriate data
##
## what a pain.
##
## Need to call node to do this, because I have code to do it already.

options <- c('./lib/copy_to_couchdb.js'
            ,'--config','test.config.json'
            ,'--root','test'
            ,'--directory','files'
            ,'-y',2012
             )
system2('node', options,stdout='out.txt',stderr='err.txt')

test_that("get hpms grids",{
    i <- 231
    j <- 55

    year <- 2012
    month.padded <- '01'
    day.padded <- '02'
    start.date <- paste( paste(year,month.padded,day.padded,sep='-'),'00:00')
    day.padded <- '03'
    end.date <- paste( paste(year,month.padded,day.padded,sep='-'),'00:00')
    json.data <- get.grid.file.from.couch(i,j,
                                          start.date,
                                          end.date)
    df <- parseGridRecord(json.data)

    expect_equal(dim(df),c(25,8))

})

rcouchutils::couch.deletedb(config$couchdb$grid_detectors)
##rcouchutils::couch.deletedb(config$couchdb$grid_hpms)
