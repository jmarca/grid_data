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

### copy_to_couchdb.js

This program will pull out grid files from the file system and then
copy them into CouchDB.

## Rwork

This is where all the R scripts are kept.

### getallthegrids.R

This is the program that is called from `trigger_R_gridwork.js`.  If
you want to debug or step through the R, the easiest way to do that is
to open this file in an editor, scroll to the bottom, and comment out
the line that reads

```
runme()
```

Then, open up an R console in the directory `Rwork`, and type

```
source('getallthegrids.R')
```

There are a number of environment variables that are expected to be
set in order for this program to work properly.  First there are three
variables that set up the link to the PostgreSQL database.
Unfortunately, I have not yet parameterized the database port, so it
will default to 5432.  I also have not parameterized the databases, as
that is a little bit pointless.  The code will create a connection to a
database called `spatialvds`, and another to a database called `osm`.
The code expects certain tables to exist in these databases, and that
really isn't something I'm ready to parameterize yet.

* `PSQL_HOST`
* `PSQL_USER`
* `PSQL_PASS`

The next set of environment variables controls connections to
CouchDB.  The idea behind these is that CouchDB can have a local
connection as well as a remote connection.  Typically, the remote
connection is the master node to which all distributed processes are
synchronizing.  By connecting to this remote database directly, one
can avoid race conditions that might result from the delay in
replication from the local db to the remote db.

However, in practice for this code, it is often better to keep both
the remote and the local the same, and to assign them both to the
local machine.  There is at least one place in the code that will
connect to the remote machine, so make sure both links are set up to
connect to the local address.

* `COUCHDB_HOST`
* `COUCHDB_USER`
* `COUCHDB_PASS`
* `COUCHDB_PORT`
* `COUCHDB_LOCALHOST`
* `COUCHDB_LOCALUSER`
* `COUCHDB_LOCALPASS`
* `COUCHDB_LOCALPORT`

Next come variables that govern this run of the code.  Specifically,
the code will process one air basin and one year at a time.

* `AIRBASIN`
* `CARB_GRID_YEAR`

The air
basin variable corresponds to the air basin names from the database.
These are:

* GBV
* LT
* MC
* MD
* NCC
* NC
* NEP
* SCC
* SC
* SD
* SF
* SJV
* SS
* SV
* LC
