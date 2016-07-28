# 2016-07-28

1. get rid of async usage in tests
2. edit README
3. make sure all tests run out of the box
    1. grid topology fails
    2. pop files fails, 4 is not 3
# 2016-04-13

I had an idea to run a model for all of california in order to pick up
grid cells that are not modeled with others.

Kinda crazy.



# todo

both detector and hpms data are in couchdb, and queryable.

need to get, by grid, both detector and hpms data, and merge then,
then see them together.

somehow decide what it means to have a complete year, and maybe scale
things to that.

# blockers

HPMS data is not 100% linked.

what about the ctearth stuff that brian domsic referenced?

# WMS server

access ctearth wms server viA http://earth.dot.ca.gov/geoserver/wms?
version 1.1.1


in qgis.


# something forward

make sql to select grid cell, hpms links, summing volumes by type of
facility
