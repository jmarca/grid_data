/*global require process exports */
var superagent = require('superagent')
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

    var chost = options.couchdb.host || 'localhost'
    var cport = options.couchdb.port ||  5984
    var cdb   = options.couchdb.db || ['carb','grid','state4k'].join('%2f')
    var cuser,cpass
    if(options.couchdb.auth){
        cuser = options.couchdb.auth.username
        cpass = options.couchdb.auth.password
    }

    var couch = 'http://'+chost+':'+cport+'/'+cdb
    var host = task.options.postgresql.host || '127.0.0.1'
    var user = task.options.postgresql.auth.username
    var pass = task.options.postgresql.auth.password || ''
    var port = task.options.postgresql.port || 5432
    var db = task.options.postgresql.db || 'osm'
    var osmConnectionString = "pg://"+user+":"+pass+"@"+host+":"+port+"/"+db

    var i0 = task.i0
    var i1 = task.i1
    var j0 = task.j0
    var j1 = task.j1

        var query = ['select'
                ,'st_asgeojson(ST_Multi(ST_Collect(geom4326))) as geom4326'
                ,'from carbgrid.state4k'
                ,'where i_cell between '+i0+' and '+i1+' and j_cell between '+j0+' and '+j1
                ].join(' ')

    // console.log(query)
    pg.connect(osmConnectionString
              ,function(err,client){
                   if(err)
                       throw err
                   var grid={}
                   var grid4326={}
                   var result = client.query(query)
                   result.on('row',function(row){
                       var geom_id = "grids"
                       if(grid4326[geom_id]===undefined){
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
                                 // console.log(result.rowCount + ' rows were received')
                                 var uri = couch +'/topology'
                                 // console.log('saving topology')
                                 async.parallel([function(cb){
                                                     var topo = topojson.topology(grid)
                                                     superagent.put(uri)
                                                     .type('json')
                                                     .auth(cuser,cpass)
                                                     .send(topo)
                                                     .end(function(e,r){
                                                         if(e) return callback(e)
                                                         // console.log('saved topology')
                                                         return cb(null,r.body)
                                                     })
                                                 }
                                                ,function(cb){
                                                     var topo = topojson.topology(grid4326)
                                                     var uri4326 = couch +'/topology4326'
                                                     superagent.put(uri4326)
                                                     .type('json')
                                                     .auth(cuser,cpass)
                                                     .send(topo)
                                                     .end(function(e,r){
                                                         if(e) return callback(e)
                                                         // console.log('saved topology 4326')
                                                         return cb(null,r.body)
                                                     })
                                                 }
                                                ],callback)
                                 return null
                             })

               })
    return null
}

exports.grid_topology=grid_topology
