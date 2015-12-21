context("sql_access")

config <- rcouchutils::get.config(Sys.getenv('TEST_CONFIG'))

library('RPostgreSQL')
m <- dbDriver("PostgreSQL")
## requires environment variables be set externally

spatialvds.con <-  dbConnect(m
                            ,user=config$postgresql$auth$username
                            ,port=config$postgresql$port
                            ,host=config$postgresql$host
                            ,dbname=config$postgresql$db)

## TODO: Rename context
## TODO: Add more tests

test_that("select statement has right form",{
    expect_equal(select.grids.in.basin('SJV'),"select i_cell,j_cell,st_centroid(grids.geom4326) as centroid, grids.geom4326 as geom4326 from carbgrid.state4k grids ,public.carb_airbasins_aligned_03 basins where ab='SJV' and st_contains(basins.geom_4326,st_centroid(grids.geom4326))")
})

test_that("get grids",{
    basin <-  'SJV'

    df.grid.detectors <- get.grids.with.detectors(basin)
    expect_equal(dim(df.grid.detectors),c(176,4))

    df.grid.hpms <- get.grids.with.hpms.from.postgres(basin)
    expect_equal(dim(df.grid.hpms),c(1785,4))

})
