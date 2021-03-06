<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [CARB grid and HPMS processing (in R)](#carb-grid-and-hpms-processing-in-r)
- [Nota Bene](#nota-bene)
- [CARB grid data handling](#carb-grid-data-handling)
- [Running this.](#running-this)
    - [Setup config.json](#setup-configjson)
    - [Install dependencies](#install-dependencies)
    - [Install R dependencies](#install-r-dependencies)
    - [Clean up after old runs](#clean-up-after-old-runs)
    - [Run the precaching program](#run-the-precaching-program)
    - [Run the modeling program](#run-the-modeling-program)
    - [Pre-run test runs](#pre-run-test-runs)
- [contents](#contents)
    - [lib](#lib)
        - [trigger\_R\_gridwork.js](#triggerrgridworkjs)
        - [copy\_to\_couchdb.js](#copytocouchdbjs)
        - [`couch_file.js`](#couchfilejs)
        - [`find.js`](#findjs)
        - [`check_file.js`](#checkfilejs)
        - [`grab_geom.js`](#grabgeomjs)
        - [`grid_topology.js`](#gridtopologyjs)
        - [`read_file.js`](#readfilejs)
    - [Rwork](#rwork)
        - [getallthegrids.R](#getallthegridsr)
        - [see also the README.md in Rwork directory](#see-also-the-readmemd-in-rwork-directory)
- [Conduct](#conduct)

<!-- markdown-toc end -->

CARB grid and HPMS processing (in R)
====================================

Nota Bene
=========

This code actually has very little to do with the HPMS data. The main
purpose is to estimate the hourly fraction of AADT for each grid cell in
california, and that computation is based solely on the grid values from
the VDS and WIM data. To see how and where the HPMS data enters into the
system, go look at `../grid_merge/lib/query_postgres.js`

CARB grid data handling
=======================

The CARB grid is a 4km grid covering California. It seems to be the
smallest tractable unit used by the California Air Resources Board
(CARB) to estimate air quality and emissions. Therefore, it makes sense
to use the grid as a basis for generating estimates of mobile source
emissions.

This package contains code I use to manipulate the CARB grid data.
Essentially, the job is to model hourly changes across the grid, based
on observed changes in grids that have highway links (and hourly data).

Feel free to poach any code you want from here, but doing so is probably
stupid unless your name is James Marca.

Running this.
=============



## Setup config.json


First, set up config.json properly. It should look like.

```
{
    "couchdb": {
        "host": "myhost.com",
        "port":5984,
        "db": "vdsdata%2fskimmed",
        "auth":{"username":"cdbuser",
                "password":"mysegreded passzwrd""
               },
        "dbname":"vdsdata",
        "trackingdb":"vdsdata%2ftracking",
        "grid_detectors": "carb%2fgrid%2fstate4k",
        "grid_hpms": "carb%2Fgrid%2Fstate4k%2fhpms%2f2015"
    },
    "postgresql": {
        "host": "127.0.0.1",
        "port":5432,
        "db": "hpmstest",
        "auth":{"username":"pguser"
               }
    },
    "recheck":1
}
```

## Install dependencies

To install the required dependencies, run

```
npm install
```

in the package directory.  There should not be any errors.

## Install R dependencies

To install the R dependencies properly, run

```
Rscript ./RinstallDeps.R
```

from the package directory.  This will install the required R packages
local to this package.  It will *not* load them into the global R
library location, and so should not be run with root user privileges.


## Clean up after old runs

If you are re-running the code after a previous run, it is important
to delete any files that are left over.  To do that, it is safest to
look under "data" and "stash" directories, and delete the year that
you are about to redo.  For example, for 2015 the file trees look like

```
data
  -- California.hwy.2015.RData
  -- California.hpms.2015.RData
stash
  -- 2014
    -- ..
  -- 2015
    -- ..
```

So to delete the 2015 files, you would run:

```
rm data/*2015.RData
rm -rf stash/2015
```

In addition, be sure to set the configuration file value "recheck" to
be numerically greater than any previous value.  Otherwise, the
program will go to couchdb, load up the grid square, see that it
already has a model version of (say) 1.0, and decide not to redo the
grid square.  Alternately, you can just delete the entire year's
couchdb database (for example, "carb/grid/state4k/hpms/2015").




Run the precaching program
--------------------------

There is a precaching program that runs the first step of the modeling
jobs---assembling and partitioning the data for each day.  First it
will query the PostgreSQL database specified in the config.json file
to generate grid "maps" of HPMS and detector-based data.  Then it will
partition those grids into clusters according to the clustering rules
specified in the code.

It isn't strictly necessary to run this step before the general
modeling run.  However, doing so will allow the modeling job to jump
right into modeling.  It is also possible to share the `data` and
`stash` directories between multiple machines if the modeling job is
being spread to different computers.

Run it as follows:

```
node lib/trigger_R_preload_calif.js --startmonth=1  --jobs 1 --year 2012  > calif_preload_2012.log 2>&1 &
```

In the above case, the main calling routine (the node.js job) will
write its output to `calif_preload_2012.log`, and each of the spawned
R jobs will write its output to a file in the `log` directory.  These
files will be in the form `California_preload_YYYY_M_D.log`, where
`YYYY` is the four digit year, `M` is the month number (from 1 to 12),
and `D` is the day number (from 1 to 31).

This *can* be run at the same time as the modeling program, but in
that case one should wait until the preload program has
completed as many days as there are jobs in the regular modeling run.
For example, if there will be 4 parallel jobs on the modeling run, then
make sure the output log file for `California_preload_2012_1_4.log` is
written out and completed, and that the main log file shows the line
```
got exit: 10, for  California 2012 1 4
```

If the modeling job will have 20 simultaneous jobs, then obviously one
would have to wait for January 20th to be completed in the preload
program.  The modeling programs very
quickly get bogged down in modeling, while this program only loads
data PostgreSQL and CouchDB for the modeling runs, so as long as the
preload program is working on a day beyond the initial list of days,
the modeling job will never catch up and duplicate effort.

The precaching program will fill up the directories `data` and `stash`
underneath the root directory of this package. If you are short on
space, you can create a symlink to a bigger drive prior to running this
program.

For 2012, a month of data in the stash directory takes up about 22MB, so
a year of data should take up less than 300MB, although that number can
rise in future years if more grid cells are covered by highway detector
data and/or HPMS data.

Run the modeling program
------------------------

There are two options here. First, you can run a model for each
airbasin. Second, you can run for all of California at once. At this
point (mid-2016), it is strongly recommended to run the
all-of-california version of the clustering and modeling run.

What both programs do is to cluster the grid cells in the region with
valid freeway data for the given day, associate HPMS-data grid cells,
and then run the spatial-temporal modeling and predicting steps.
If you run it on an airbasin boundary, then airbasins without highway
detectors will not have any modeling done in them, and you'll have to
run the all-California model anyway.

If you start with the all-California modeling step, rather than the
per-airbasin step, then you will effectively end up with bigger clusters
of grid cells, which will slow down the spatial-temporal modeling and
predicting, but in the end the result is the same as the per-airbasin
way.

So, to run the all-of-California model/predict code, do the following
(assuming that you have 6 CPUs on your machine and approximately 4GB
available per CPU):

```
node lib/trigger_R_gridwork_calif.js --startmonth 1  --jobs 6 --year 2012  > calif2012.log 2>&1 &
```

Obviously, if the machine has sufficient RAM and CPU cores to run 20
jobs, the above command line would have jobs=20, not 6.  However, it
is best to err on the side of fewer parallel jobs, as the RAM
requirements can lead to a crash and a system shut-down in some cases.

Also, note that you have to change the year from 2012 to whatever year
you are processing.

Pre-run test runs
-----------------

If you want to run a shorter test prior to running the full blown
modeling step, then you can tweak the code a little bit to do so.

Open up `./lib/trigger_R_gridwork_calif.js` in an editor, and scroll
down to about line 129, to where you see the following lines of code:

    // for debugging, do a few days only
    // endymd = new Date(year, startmonth, 3, 0, 0, 0)
    for( ymd = new Date(year, startmonth, 1, 0, 0, 0);

You should uncomment the `// endymd = new Date...` line. What this does
is set up the job to stop after just 2 days of processing. It will only
process startmonth day 1, and startmonth day 2. Then you can inspect the
log files (look under the log/... directory) and make sure that the
program is doing what you expect it to do.

When everything looks good, don't forget to put back in the comment on
the above line.

contents
========

lib
---

This is where my node.js files live.

### trigger\_R\_gridwork.js

This program is a command-line program that will fire off one or more R
jobs. It used to be the only real way to get parallelism from the R
code, by passing a value greater than 1 to the -j option. (jobs=2, for
example). However, now that the R code is using plyr et al, it will
generally run parallel jobs that equal half the current number of
processors. On some machines, this means you can use -j 2 as an option
to occupy all of your cores. On others, the best option is -j 1 and just
use half the cores, or manually fiddle with the `registerDoMC()` command
in `Rwork/data.model.R` program to set it to the desired number of
parallel jobs. Usually the problem is that too much RAM is allocated for
multiple jobs, so you want to cut back so as to not crash.

### copy\_to\_couchdb.js

This program will pull out grid files from the file system and then copy
them into CouchDB. It also computes the AADT for each grid, and saves as
part of the save.

### `couch_file.js`

### `find.js`

Lame dead end, commented out.

### `check_file.js`

### `grab_geom.js`

Heads off to PostgreSQL to grab a particular grid cell's information and
geometry. The results get stashed in the `task` object under
`task.grid`, and then the callback gets called with the modified `task`
object.

### `grid_topology.js`

This module will connect to PostgreSQL, load grids as specified, and
save to CouchDB as a topojson topology object.

### `read_file.js`

Used in the program flow. Will read the file located at `task.file`,
parse the file as JSON, and save it in the `task` object as `task.data`,
then call the callback with the modified `task` object.

Rwork
-----

This is where all the R scripts are kept. And where the HPMS processing
is done

### getallthegrids.R

This is the program that is called from `trigger_R_gridwork.js`. If you
want to debug or step through the R, the easiest way to do that is to
open this file in an editor, scroll to the bottom, and comment out the
line that reads

    runme()

Then, open up an R console in the directory `Rwork`, and type

    source('getallthegrids.R')

There are a number of environment variables that are expected to be set
in order for this program to work properly. First there are three
variables that set up the link to the PostgreSQL database.
Unfortunately, I have not yet parameterized the database port, so it
will default to 5432. I also have not parameterized the databases, as
that is a little bit pointless. The code will create a connection to a
database called `spatialvds`, and another to a database called `osm`.
The code expects certain tables to exist in these databases, and that
really isn't something I'm ready to parameterize yet.

-   `PSQL_HOST`
-   `PSQL_USER`
-   `PSQL_PASS`

The next set of environment variables controls connections to CouchDB.
The idea behind these is that CouchDB can have a local connection as
well as a remote connection. Typically, the remote connection is the
master node to which all distributed processes are synchronizing. By
connecting to this remote database directly, one can avoid race
conditions that might result from the delay in replication from the
local db to the remote db.

However, in practice for this code, it is often better to keep both the
remote and the local the same, and to assign them both to the local
machine. There is at least one place in the code that will connect to
the remote machine, so make sure both links are set up to connect to the
local address.

-   `COUCHDB_HOST`
-   `COUCHDB_USER`
-   `COUCHDB_PASS`
-   `COUCHDB_PORT`
-   `COUCHDB_LOCALHOST`
-   `COUCHDB_LOCALUSER`
-   `COUCHDB_LOCALPASS`
-   `COUCHDB_LOCALPORT`

Next come variables that govern this run of the code. Specifically, the
code will process one air basin and one year at a time.

-   `AIRBASIN`
-   `CARB_GRID_YEAR`

The air basin variable corresponds to the air basin names from the
database. These are:

-   GBV
-   LT
-   MC
-   MD
-   NCC
-   NC
-   NEP
-   SCC
-   SC
-   SD
-   SF
-   SJV
-   SS
-   SV
-   LC

### see also the README.md in Rwork directory

Conduct
=======

Please note that this project is released with a [Contributor Code of
Conduct](CONDUCT.md). By participating in this project you agree to
abide by its terms.

(And thanks to devtools project for making it easy to include the above
statement.)
