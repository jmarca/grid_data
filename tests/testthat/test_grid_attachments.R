context("grid from sql and attachments")

config <- rcouchutils::get.config()
rcouchutils::couch.makedb(config$couchdb$grid_detectors)
rcouchutils::couch.makedb(config$couchdb$grid_hpms)


test_that("get hwy grids",{
    config <- rcouchutils::get.config(Sys.getenv('TEST_CONFIG'))
    library('RPostgreSQL')
    m <- dbDriver("PostgreSQL")
    ## requires environment variables be set externally

    spatialvds.con <-  dbConnect(m
                                ,user=config$postgresql$auth$username
                                ,port=config$postgresql$port
                                ,host=config$postgresql$host
                                ,dbname=config$postgresql$db)

    basin <-  'SJV'
    year <- 2012

    ## first use the old sql plain method
    df.grid.detectors <- get.grids.with.detectors(basin)
    print(dim(df.grid.detectors))
    expect_equal(dim(df.grid.detectors),c(176,4))

    ## then use the new functions.  first, couchdb should be empty
    d.g.d2 <- load.grid.data.from.couchdb('hwy',basin,year)
    print(d.g.d2)

    expect_equal(dim(d.g.d2),c(0,0))

    d.g.d2 <- load.grid.data.from.postgresql(basin,year)

    expect_equal(dim(d.g.d2),c(176,5))
    expect_equal(d.g.d2[,1],df.grid.detectors[,1])
    ## can probably also do the others, but not geo_id

    ## now the df should also be in couchdb
    d.g.d3 <- load.grid.data.from.couchdb('hwy',basin,year)
    expect_equal(dim(d.g.d2),dim(d.g.d3))
    expect_equal(d.g.d2,d.g.d3)

    res <- unlink('data/SJV.hwy.2012.RData')

})

test_that("get hpms grids",{
    basin <-  'SJV'
    year <- 2012

    ## first use the old sql plain method
    df.grid.hpms <- get.grids.with.hpms(basin)
    expect_equal(dim(df.grid.hpms),c(1785,4))

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

    expect_equal(dim(d.g.d2),c(1785,4))

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
rcouchutils::couch.deletedb(config$couchdb$grid_hpms)
