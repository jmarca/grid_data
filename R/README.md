# some notes

Upon coming back to this code after a month or so away, I was confused
by some things and am writing them down here for the next time I step
away.

First, the CalVAD imputed grid AADT fraction data is stored in the
database

    grid.couch.db <- 'carb%2fgrid%2fstate4k'

This database is used in the functions defined in the file
`fetchFiles.R`.  This db is populated using the code in the `lib`
subdirectory, the copy to couch stuff.

This is a different database than the HPMS output database.  I am not
exactly sure why, but I don't want to argue at the moment.  The R
script triggered by `getallthegrids.R` will estimate AADT fractions
for each hour, each grid cell that has HPMS data, and will store those
estimates in the database

    hpms.grid.couch.db <- 'carb%2Fgrid%2Fstate4k%2fhpms'

This then is the output database.  Also, there is code that tries to
prevent writing the same thing twice, as before I predict and save to
the db, I first check whether or not the first hour in the month has
any data in it for that cell (is that doc there or not).

All of this is triggered by the node.js script in
`../lib/trigger_R_gridwork.js`
