## library(doMC)
## registerDoMC(2)

## library(spTimer)

## need node_modules directories
dot_is <- getwd() # expect that this is one level up

node_paths <- dir(dot_is,pattern='\\.Rlibs',
                  full.names=TRUE,recursive=TRUE,
                  ignore.case=TRUE,include.dirs=TRUE,
                  all.files = TRUE)
path <- normalizePath(node_paths, winslash = "/", mustWork = FALSE)
lib_paths <- .libPaths()
.libPaths(c(path, lib_paths))

print(.libPaths())

pkg <- devtools::as.package('.')
ns_env <- devtools::load_all(pkg,quiet = TRUE)$env

## need env for test file
config_file <- Sys.getenv('R_CONFIG')

if(config_file ==  ''){
    config_file <- 'config.json'
}
print(paste ('using config file =',config_file))
config <- rcouchutils::get.config(config_file)




library('RPostgreSQL')
m <- dbDriver("PostgreSQL")
spatialvds.con <-  dbConnect(m
                  ,user=config$postgresql$auth$username
                  ,host=config$postgresql$host
                  ,port=config$postgresql$port
                   ,dbname=config$postgresql$db)

## do it

runme()
