# CARB grid data handling

The CARB grid is a 4km grid covering California.  It seems to be the
smallest tractable unit used by the California Air Resources Board
(CARB) to estimate air quality and emissions.  Therefore, it makes
sense to use the grid as a basis for generating estimates of mobile
source emissions.

This package contains code I use to manipulate the CARB grid data.
Specifically, the main purpose right now is to load up data per grid
and then copy into CouchDB.

The original grid information is saved under the geometry
subdirectory.  This GIS file was read into PostgreSQL using PostGIS
tools.

Feel free to poach any code you want from here, but doing so is
probably stupid unless your name is James Marca.

# contents

## lib

This is my node.js files

### trigger_R_gridwork.js

This program is a command-line program that will fire off one or more
R jobs.  It used to be the only real way to get parallelism from the R
code, by passing a value greater than 1 to the -j option. (jobs=2, for
example).  However, now that the R code is using plyr et al, it will
generally run parallel jobs that equal half the current number of
processors.  On some machines, this means you can use -j 2 as an
option to occupy all of your cores.  On others, the best option is -j
1 and just use half the cores, or manually fiddle with the
`registerDoMC()` command in `Rwork/data.model.R` program to set it to
the desired number of parallel jobs.  Usually the problem is that too
much RAM is allocated for multiple jobs, so you want to cut back so as
to not crash.
