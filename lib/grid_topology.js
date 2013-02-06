/*global require process exports */
var request = require('request')
var topojson = require('topojson')
var _=require('lodash')
var async = require('async')
var pg = require('pg')

/**
 * grid_topology
 *
 * save all or some of the grid as a topology
 *
 */
function grid_topology(task,callback){

    var options = task.options
    //couchdb
    var chost = options.chost ? options.chost : '127.0.0.1'
    var cuser = options.cusername ? options.cusername : 'myname'
    var cpass = options.cpassword ? options.cpassword : 'secret'
    var cport = options.cport ? options.cport :  5984
    var cdb   = options.couch_db || ['carb','grid','state4k'].join('%2f')
    var couch = 'http://'+chost+':'+cport+'/'+cdb

    var host = task.options.host ? task.options.host : '127.0.0.1';
    var user = task.options.username ? task.options.username : 'myname';
    var pass = task.options.password ? task.options.password : 'secret';
    var port = task.options.port ? task.options.port :  5432;
    var osmConnectionString        = "pg://"+user+":"+pass+"@"+host+":"+port+"/osm";

    var i0 = task.i0
    var i1 = task.i1
    var j0 = task.j0
    var j1 = task.j1

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
                ,'st_asgeojson(geom,7) as geom,'
                ,'st_asgeojson(geom4326,7) as geom4326'
                ,'from carbgrid.state4k'
                ,'where i_cell between '+i0+' and '+i1+' and j_cell between '+j0+' and '+j1
                ].join(' ')

    console.log(query)
    pg.connect(osmConnectionString
              ,function(err,client){
                   var grid={}
                   var grid4326={}
                   var result = client.query(query);
                   result.on('row',function(row){
                       var geom_id = [row.i_cell,row.j_cell].join('_')
                       if(grid[geom_id]===undefined){
                           var geo = {type: "Feature"
                                     ,id: geom_id
                                     //,properties: _.clone(row)
                                     ,geometry: JSON.parse(row.geom)}
                           grid[geom_id]=geo
                           var geo4326 = {type: "Feature"
                                     ,id: geom_id
                                     //,properties: _.clone(row)
                                     ,geometry: JSON.parse(row.geom4326)}
                           grid4326[geom_id]=geo4326
                       }
                       return null
                   })
                   result.on('error'
                            ,function(err){
                                 console.log('postgres choked')
                                 console.log(err)
                                 throw new Error(err)
                             })
                   result.on('end'
                            ,function(result){
                                 console.log(result.rowCount + ' rows were received');
                                 var uri = couch +'/topology'
                                 var opts = {'uri':uri
                                            , 'method': "PUT"
                                            , 'headers': {}
                                            };
                                 opts.headers.authorization = 'Basic ' + new Buffer(cuser + ':' + cpass).toString('base64')
                                 opts.headers['Content-Type'] =  'application/json'
                                 console.log('saving topology?')
                                 async.parallel([
                                     function(cb){
                                         var topo = topojson.topology(grid)
                                         opts.json = topo
                                         request(opts
                                                ,function(e,r,b){
                                                     if(e) return callback(e)
                                                     console.log('saved topology?')
                                                     console.log(b)
                                                     return cb(null,b)
                                                 })
                                     }
                                 ,function(cb){
                                      var topo = topojson.topology(grid4326)
                                      opts.json = topo
                                      opts.uri= couch +'/topology4326'
                                      request(opts
                                             ,function(e,r,b){
                                                     if(e) return callback(e)
                                                     console.log('saved topology?')
                                                     console.log(b)
                                                     return cb(null,b)
                                                 })
                                     }
                                 ],callback)
                                 return null
                             })

               })
    return null
}

exports.grid_topology=grid_topology
