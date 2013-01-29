# CARB Grid handling

The CARB grid is a 4km grid covering California.  It seems to be the
smallest tractable unit used by the California Air Resources Board
(CARB) to estimate air quality and emissions.  Therefore, it makes
sense to use the grid as a basis for generating estimates of mobile
source emissions.

The reason this is important is that HPMS data, the gold standard for
universal estimates of vehicle traffic in California, provides only
AADT.  While the estimates cover each street in space, they only
provide the coarsest of approximations in time.

So my idea is to collect everything I know about each grid in a
CouchDB database.  The DB will be document based, with one document
per grid.

I think.  Part of the reason for this document is to hash out some
alternative design options for the database.

# One document per grid cell

So if it is one document per grid cell, the documents will have as
their unique id the id of the grid cell, and can also be indexed
according to both the stock geographic projection, and the WGS84
reprojection.  Each document would then contain everything I know
about that grid, including the streets and highways contained in the
grid according to HPMS, and other stuff.

One item that I really want to have is an estimate of how each hour
deviates from the AADT value.  That is, what is the factor that should
be multiplied to the HPMS-derived estimate of AADT to obtain the
hourly volume of truck (HHDT and Not HHDT) and car travel in the
grid.  If I include this in the document, then that means that the
documents will get large---containing 8,760 factors per year.

I would also like to store the HPMS data, thus allowing me to compute
the hourly traffic straight off.  I would also like to store the
output of the other VDS/WIM highway imputations for each grid.

The problem is that each document gets bigger and bigger, and
extracting a value by hour is difficult.  Suppose I want to display
the imputations for a day.  I need to grab every grid cell, break out
just the day of data.  This will take time.  Making a view of that
might help, but it would be difficult to mix geographic index with a
time index.

Still, falling back on the usual approach of one index to get the
grids in bbox, and then direct addressing of the grid cells, might
work to give me what I want.  I also saw some mention of
multidimensional geo handling in CouchDB.  This *might* allow me to
mix geography and time as the third dimension, so that I can get a
bbox plus a range of time.  That would be excellent.
