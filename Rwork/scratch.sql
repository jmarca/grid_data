with basingrids as (select i_cell,j_cell,
      st_centroid(grids.geom4326) as centroid
      ,geom4326
from carbgrid.state4k grids ,
     public.carb_airbasins_aligned_03 basins
     where basin_name='SAN JOAQUIN VALLEY' and grids.geom4326 && basins.geom_4326)

-- select grid cells with hpm records in them
select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat, array_agg(hd.hpms_id)

from basingrids
     join hpms.hpms_geom hg on st_intersects(basingrids.geom4326,hg.geom)
     join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
     group by i_cell,j_cell,lon,lat



-- now just skip the hpms ids
     with basingrids as (select i_cell,j_cell,
     st_centroid(grids.geom4326) as centroid
     ,geom4326
     from carbgrid.state4k grids ,
     public.carb_airbasins_aligned_03 basins
     where basin_name='SAN JOAQUIN VALLEY' and grids.geom4326 && basins.geom_4326)

     -- select grid cells with hpm records in them
     select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat
     from basingrids
     join hpms.hpms_geom hg on st_intersects(basingrids.geom4326,hg.geom)
     join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
     group by i_cell,j_cell,lon,lat

-- now ditto detectors, but have to run on osm db


with basingrids as (select i_cell,j_cell,
st_centroid(grids.geom4326) as centroid
,geom4326
from carbgrid.state4k grids ,
public.carb_airbasins_aligned_03 basins
where basin_name='SAN JOAQUIN VALLEY' and grids.geom4326 && basins.geom_4326)

-- select grid cells with hpm records in them
select i_cell,j_cell,st_x(centroid) as lon, st_y(centroid) as lat
from basingrids
    join tempseg.tdetector ttd on  st_intersects(ttd.geom,geom4326)
    group by i_cell,j_cell,lon,lat
