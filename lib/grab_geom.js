/*global require process exports */

/**
 * grab_geom
 *
 * go off to postgresql and get this grid cell's geometry and other details
 *
 */
function grab_geom(task,callback){
    //psql
    var host = task.options.host ? task.options.host : '127.0.0.1';
    var user = task.options.username ? task.options.username : 'myname';
    var pass = task.options.password ? task.options.password : 'secret';
    var port = task.options.port ? task.options.port :  5432;
    var osmConnectionString        = "pg://"+user+":"+pass+"@"+host+":"+port+"/osm";

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
                   task.grid={}
                   var result = client.query(query);
                   result.on('row',function(row){
                       _.each(row
                             ,function(v,k){
                                  task.grid[k]=v
                              });
                       return callback(null,task)
                   });

               })
    return null

}




exports.grab_geom=grab_geom
