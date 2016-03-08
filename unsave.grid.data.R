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

basins <- c('GBV', 'MD',
            'NEP', 'SC', 'SF', 'LC', 'MC',
            'LT',  'NCC',  'NC',  'SCC', 'SD',  'SJV',  'SS',  'SV'
            )
y <- 2012
for(b in basins){

    res <- detach.grid.data.from.couchdb('hpms',b,y)
    print(paste(b,res))

}
