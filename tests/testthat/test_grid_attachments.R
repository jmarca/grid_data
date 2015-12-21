config <- rcouchutils::get.config(Sys.getenv('TEST_CONFIG'))
library('RPostgreSQL')
m <- dbDriver("PostgreSQL")
## requires environment variables be set externally

print(config$postgresql)
spatialvds.con <-  dbConnect(m
                            ,user=config$postgresql$auth$username
                            ,port=config$postgresql$port
                            ,host=config$postgresql$host
                            ,dbname=config$postgresql$db)

context("grid from sql and attachments")



test_that("get hwy grids",{
    basin <-  'SJV'
    year <- 2012

    ## first use the old sql plain method
    df.grid.detectors <- get.grids.with.detectors(basin)
    expect_equal(dim(df.grid.detectors),c(176,4))

    ## then use the new functions.  first, couchdb should be empty
    d.g.d2 <- load.grid.data.from.couchdb(basin,year)
    expect_equal(dim(d.g.d2),c(0,0))

    d.g.d2 <- load.grid.data.from.postgresql(basin,year)

    expect_equal(dim(d.g.d2),c(176,5))
    expect_equal(d.g.d2[,1],df.grid.detectors[,1])
    ## can probably also do the others, but not geo_id

    ## now the df should also be in couchdb
    d.g.d3 <- load.grid.data.from.couchdb(basin,year)
    expect_equal(dim(d.g.d2),dim(d.g.d3))
    expect_equal(d.g.d2,d.g.d3)


})

test_that("get hwy grids",{
    basin <-  'SJV'
    year <- 2012

    ## first use the old sql plain method
    df.grid.hpms <- get.grids.with.hpms(basin)
    expect_equal(dim(df.grid.hpms),c(1785,4))

    ## then use the new functions.  first, couchdb should be empty
    d.g.d2 <- load.grids.with.hpms(basin,year)
    expect_equal(dim(d.g.d2),c(0,0))

    d.g.d2 <- load.grid.data.from.postgresql(basin,year)

    expect_equal(dim(d.g.d2),c(176,5))
    expect_equal(d.g.d2[,1],df.grid.detectors[,1])
    ## can probably also do the others, but not geo_id

    ## now the df should also be in couchdb
    d.g.d3 <- load.grid.data.from.couchdb(basin,year)
    expect_equal(dim(d.g.d2),dim(d.g.d3))
    expect_equal(d.g.d2,d.g.d3)


})
