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
