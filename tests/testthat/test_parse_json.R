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

        if('error' %in% names(json.data) || length(json.data$rows)<2) next
        ## print(length(json.data$rows))
        df <- parseGridRecord(json.data)

    ## first use the old sql plain method
    df.grid.hpms <- get.grids.with.hpms(basin)
    expect_equal(dim(df.grid.hpms),c(1785,5))

    ## then use the new functions.  first, fs should be empty
    d.g.d.fs <- load.grid.data.from.fs('hpms',basin,year)
    expect_equal(dim(d.g.d.fs),c(0,0))

    ## then couchdb, also should be empty
    d.g.d.cdb <- load.grid.data.from.couchdb('hpms',basin,year)
    expect_equal(dim(d.g.d.cdb),c(0,0))

    ## the canonical fetch should get from postgresql, and populate
    ## fs, couchdb
    d.g.d2 <- load.grids.with.hpms(basin,year)
    print(dim(d.g.d2))
    print(d.g.d2[1,])

    expect_equal(dim(d.g.d2),c(1785,5))

    expect_equal(d.g.d2[,1],df.grid.hpms[,1])
    ## can probably also do the others, but not geo_id

    ## now the df should also be in fs and couchdb
    d.g.d.fs <- load.grid.data.from.fs('hpms',basin,year)
    expect_equal(d.g.d.fs,d.g.d2)

    d.g.d.cdb <- load.grid.data.from.couchdb('hpms',basin,year)
    expect_equal(d.g.d.cdb,d.g.d2)

    res <- unlink('data/SJV.hpms.2012.RData')

})

rcouchutils::couch.deletedb(config$couchdb$grid_detectors)
##rcouchutils::couch.deletedb(config$couchdb$grid_hpms)
