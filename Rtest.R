## need node_modules directories
dot_is <- getwd()
node_paths <- dir(dot_is,pattern='\\.Rlibs',
                  full.names=TRUE,recursive=TRUE,
                  ignore.case=TRUE,include.dirs=TRUE,
                  all.files = TRUE)
path <- normalizePath(node_paths, winslash = "/", mustWork = FALSE)
lib_paths <- .libPaths()
.libPaths(c(path, lib_paths))

## need env for test file
Sys.setenv(TEST_CONFIG=paste(dot_is,'test.config.json',sep='/'))
config <- rcouchutils::get.config(Sys.getenv('TEST_CONFIG'))
library('RPostgreSQL')
m <- dbDriver("PostgreSQL")
## requires environment variables be set externally

spatialvds.con <-  dbConnect(m
                            ,user=config$postgresql$auth$username
                            ,port=config$postgresql$port
                            ,host=config$postgresql$host
                            ,dbname=config$postgresql$db)
devtools::check()
