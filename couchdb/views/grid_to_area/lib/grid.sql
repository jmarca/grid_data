 carb_airbasins_aligned_03
                                   Table "public.carb_airbasins_aligned_03"
   Column   |         Type          |                                Modifiers
------------+-----------------------+-------------------------------------------------------------------------
 gid        | integer               | not null default nextval('carb_airbasins_aligned_03_gid_seq'::regclass)
 area       | numeric               |
 perimeter  | numeric               |
 abasa_     | bigint                |
 abasa_id   | bigint                |
 basin_name | character varying(40) |
 ab         | character varying(3)  |
 the_geom   | geometry              |
 geom_4326  | geometry              |


with basingrids as
  (select basins.basin_name as airbasin, basins.ab as abbrev,floor(i_cell) as i_cell,floor(j_cell) as j_cell, grids.geom4326
   from carbgrid.state4k grids,public.carb_airbasins_aligned_03 basins
   where st_centroid(grids.geom4326) @ basins.geom_4326)

select '"'||i_cell || '_'|| j_cell || '":{"airbasin":"'||airbasin||'","abbrev":"'|| abbrev||'"},' as jsonstr
from basingrids join hpms.hpms_geom hg on st_intersects(basingrids.geom4326,hg.geom)
join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
group by i_cell,j_cell,airbasin,abbrev
order by jsonstr
;



with countygrids as
  (select counties.name as county, counties.conum as fips,floor(i_cell) as i_cell,floor(j_cell) as j_cell, grids.geom4326
   from carbgrid.state4k grids,public.carb_counties_aligned_03 counties
   where st_centroid(grids.geom4326) @ counties.geom4326)

select '"'||i_cell || '_'|| j_cell || '":{"county":"'||county||'","fips":"'|| fips||'"},' as jsonstr
from countygrids join hpms.hpms_geom hg on st_intersects(countygrids.geom4326,hg.geom)
join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
group by i_cell,j_cell,county,fips
order by jsonstr
;

public.carb_counties_aligned_03
   Column   |         Type          |                               Modifiers
------------+-----------------------+------------------------------------------------------------------------
 gid        | integer               | not null default nextval('carb_counties_aligned_03_gid_seq'::regclass)
 cacoa_     | integer               |
 cacoa_id   | integer               |
 coname     | character varying(20) |
 name       | character varying(20) |
 conum      | smallint              |
 display    | smallint              |
 symbol     | bigint                |
 islandname | character varying(35) |
 baysplinte | character varying(35) |
 cntyi_area | numeric               |
 island_id  | smallint              |
 bay_id     | smallint              |
 the_geom   | geometry              |
 geom4326   | geometry              |
Indexes:


carb_airdistricts_aligned_03
                                   Table "public.carb_airdistricts_aligned_03"
   Column   |         Type          |                                 Modifiers
------------+-----------------------+----------------------------------------------------------------------------
 gid        | integer               | not null default nextval('carb_airdistricts_aligned_03_gid_seq'::regclass)
 adisa_     | bigint                |
 adisa_id   | bigint                |
 name       | character varying(30) |
 dist_type  | character varying(5)  |
 display    | smallint              |
 disti_area | numeric               |
 dis        | character varying(3)  |
 disn       | character varying(35) |
 the_geom   | geometry              |
 geom4326   | geometry              |


with districtgrids as
  (select districts.name as district, districts.dis as abbrev,floor(i_cell) as i_cell,floor(j_cell) as j_cell, grids.geom4326
   from carbgrid.state4k grids,public.carb_airdistricts_aligned_03 districts
   where st_centroid(grids.geom4326) @ districts.geom4326)

select '"'||i_cell || '_'|| j_cell || '":{"district":"'||district||'","abbrev":"'|| abbrev||'"},' as jsonstr
from districtgrids join hpms.hpms_geom hg on st_intersects(districtgrids.geom4326,hg.geom)
join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
group by i_cell,j_cell,district,abbrev
order by jsonstr
;

-- now combine them all into one query, one json object for lookup


with basingrids as
  (select distinct basins.basin_name as airbasin, basins.ab as bas_abbrev,floor(i_cell) as i_cell,floor(j_cell) as j_cell, grids.geom4326
   from carbgrid.state4k grids,public.carb_airbasins_aligned_03 basins
   where st_centroid(grids.geom4326) @ basins.geom_4326
   ),
basinjson as
  (select i_cell ||'_'|| j_cell as cell, '"airbasin":"'||airbasin||'","bas":"'|| bas_abbrev||'"}' as basinstr
   from basingrids join hpms.hpms_geom hg on st_intersects(basingrids.geom4326,hg.geom)
   join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
   order by cell
   ),
countygrids as
  (select distinct counties.name as county, counties.conum as fips,floor(i_cell) as i_cell,floor(j_cell) as j_cell, grids.geom4326
   from carbgrid.state4k grids,public.carb_counties_aligned_03 counties
   where st_centroid(grids.geom4326) @ counties.geom4326
   ),
countyjson as
  (select i_cell ||'_'|| j_cell as cell, '"county":"'||county||'","fips":"'|| fips||'"' as countystr
   from countygrids join hpms.hpms_geom hg on st_intersects(countygrids.geom4326,hg.geom)
   join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
   order by cell
   ),
districtgrids as
  (select distinct districts.name as district, districts.dis as dis_abbrev,floor(i_cell) as i_cell,floor(j_cell) as j_cell, grids.geom4326
   from carbgrid.state4k grids,public.carb_airdistricts_aligned_03 districts
   where st_centroid(grids.geom4326) @ districts.geom4326
   ),
districtjson as
  (select i_cell ||'_'|| j_cell as cell,'"district":"'||district||'","dis":"'|| dis_abbrev||'"}' as districtstr
   from districtgrids join hpms.hpms_geom hg on st_intersects(districtgrids.geom4326,hg.geom)
   join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
   order by cell
   )
select '"'|| cell || '":{'|| basinstr || ',' || countystr || ',' || districtstr || '},' as jsonstr
from basinjson
join countyjson using (cell)
join districtjson using (cell)
order by jsonstr
;


with hpmsgrid as
  (select distinct floor(i_cell) || '_'|| floor(j_cell) as cell
   from carbgrid.state4k grids
   join hpms.hpms_geom hg on st_intersects(grids.geom4326,hg.geom)
   join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
)
select cell,count(*) cnt
from hpmsgrid
group by cell
order by cnt desc;


with hpmsgrid as
  (select distinct floor(grids.i_cell) || '_'|| floor(grids.j_cell) as cell
   from carbgrid.state4k grids
   join hpms.hpms_geom hg on st_intersects(grids.geom4326,hg.geom)
   join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
   ),
basingrids as
  (select distinct floor(grids.i_cell) || '_'|| floor(grids.j_cell) as cell, '"airbasin":"'||basin_name||'","bas":"'|| ab ||'"' as basinstr
   from carbgrid.state4k grids
   join public.carb_airbasins_aligned_03 a on (st_contains(a.geom_4326,st_centroid(grids.geom4326)))
   join hpmsgrid hg on (hg.cell = floor(grids.i_cell) || '_'|| floor(grids.j_cell))
   ),
countygrids as
  (select distinct floor(grids.i_cell) || '_'|| floor(grids.j_cell) as cell, '"county":"'||a.name||'","fips":"'|| conum ||'"' as countystr
   from carbgrid.state4k grids
   join public.carb_counties_aligned_03 a on (st_contains(a.geom4326,st_centroid(grids.geom4326)))
   join hpmsgrid hg on (hg.cell = floor(grids.i_cell) || '_'|| floor(grids.j_cell))
   ),
districtgrids as
  (select distinct floor(grids.i_cell) || '_'|| floor(grids.j_cell) as cell, '"airdistrict":"'||a.disn||'","dis":"'|| a.dis ||'"' as districtstr
   from carbgrid.state4k grids
   join public.carb_airdistricts_aligned_03 a on (st_contains(a.geom4326,st_centroid(grids.geom4326)))
   join hpmsgrid hg on (hg.cell = floor(grids.i_cell) || '_'|| floor(grids.j_cell))
   )
select  '"'|| cell ||'":{'|| basinstr || ',' || countystr || ',' || districtstr ||  '},' as jsonstr
from basingrids
left outer join countygrids using (cell)
left outer join districtgrids using (cell)
order by cell,jsonstr
;

-- that misses 9 grids whose centroids are not contained properly, so, special case for those 9

with allhpmsgrids as
  (select distinct floor(grids.i_cell) || '_'|| floor(grids.j_cell) as cell,st_centroid(grids.geom4326) as centroid, grids.geom4326 as geom
   from carbgrid.state4k grids
   join hpms.hpms_geom hg on st_intersects(grids.geom4326,hg.geom)
   join hpms.hpms_link_geom hd on (hg.id=hd.geo_id)
   ),
containedgrids as
  (select distinct cell
   from allhpmsgrids hg
   join public.carb_airbasins_aligned_03 a on (st_contains(a.geom_4326,hg.centroid))
   ),
uncontained as
  (select hg.*
   from allhpmsgrids hg
   left outer join containedgrids u on (hg.cell=u.cell)
   where u.cell is null
   ),
basingrids as
  (select distinct u.cell, '"airbasin":"'||basin_name||'","bas":"'|| ab ||'"' as basinstr
   from uncontained u
   join public.carb_airbasins_aligned_03 a on (st_intersects(a.geom_4326,u.geom))
   ),
countygrids as
  (select distinct u.cell, '"county":"'||a.name||'","fips":"'|| conum ||'"' as countystr
   from uncontained u
   join public.carb_counties_aligned_03 a on (st_intersects(a.geom4326,u.geom))
   ),
districtgrids as
  (select distinct u.cell, '"airdistrict":"'||a.disn||'","dis":"'|| a.dis ||'"' as districtstr
   from uncontained u
   join public.carb_airdistricts_aligned_03 a on (st_intersects(a.geom4326,u.geom))
   )
select  '"'|| cell ||'":{'|| basinstr || ',' || countystr || ',' || districtstr ||  '},' as jsonstr
from basingrids
left outer join countygrids using (cell)
left outer join districtgrids using (cell)
order by jsonstr
;
