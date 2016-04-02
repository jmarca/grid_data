/*global require process exports */

var pg = require('pg')

/**
 * grab_geom
 *
 * go off to postgresql and get this grid cell's geometry and other details
 *
 */
function grab_geom(task,callback){
    //psql
    var host = task.options.postgresql.host || '127.0.0.1'
    var user = task.options.postgresql.auth.username
    var pass = task.options.postgresql.auth.password || ''
    var port = task.options.postgresql.port || 5432
    var db = task.options.postgresql.db || 'osm'
    var osmConnectionString = "pg://"+user+":"+pass+"@"+host+":"+port+"/"+db

    console.log(osmConnectionString)
    var file = task.file
    var parts = file.split('/')
    var filename = parts.pop()
    var j = filename.split('.')[0]
    var i = parts.pop()



    var query = ['select'
                ,'fid_state4,'
                ,'cell_id,'
                ,'i_cell,'
                ,'j_cell,'
                ,'st_cell_id,'
                ,'st_i_cell,'
                ,'st_j_cell,'
                ,'fid_ca,'
                ,'state,'
                ,'st_asgeojson(geom) as geom,'
                ,'st_asgeojson(geom4326) as geom4326'
                ,'from carbgrid.state4k'
                ,'where i_cell='+i+' and j_cell='+j
                ,'limit 1'].join(' ')

    pg.connect(osmConnectionString
               ,function(err,client){
                   if(err) throw new Error(err)
                   task.grid={}
                   var result = client.query(query)
                   result.on('row',function(row){
                       task.grid.fid_state4 = row.fid_state4
                       task.grid.cell_id    = Math.round(row.cell_id)
                       task.grid.i_cell     = Math.round(row.i_cell)
                       task.grid.j_cell     = Math.round(row.j_cell)
                       task.grid.st_cell_id = Math.round(row.st_cell_id)
                       task.grid.st_i_cell  = Math.round(row.st_i_cell)
                       task.grid.st_j_cell  = Math.round(row.st_j_cell)
                       task.grid.fid_ca     = row.fid_ca
                       task.grid.state      = row.state
                       task.grid.geom       = row.geom
                       task.grid.geom4326   = row.geom4326
                       return callback(null,task)
                   })

               })
    return null

}




exports.grab_geom=grab_geom
