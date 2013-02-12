/*global require process exports */
var request = require('request')
var topojson = require('topojson')
var _=require('lodash')
var async = require('async')

/**
 * couch_file
 *
 * save a doc in couchdb
 *
 */
function couch_file(task,callback){

    var options = task.options
    //couchdb
    var chost = options.chost ? options.chost : '127.0.0.1'
    var cuser = options.cusername ? options.cusername : 'myname'
    var cpass = options.cpassword ? options.cpassword : 'secret'
    var cport = options.cport ? options.cport :  5984
    var cdb   = options.couch_db || ['carb','grid','state4k'].join('%2f')
    var couch = 'http://'+chost+':'+cport+'/'+cdb

    // overwrite old docs??

    // hmm, for this one, each doc is an hour.  Let's go crazy.  Then
    // the views can be null and just get the doc too, maybe save some
    // space and time creating the views

    // not so great if I have to eventually update? granularity yes
    // because per hour docs.  although that is a lot of disk i/o

    // create the per-hour docs, each gets the geometry and AADT, plus
    // the hour record

    // going to use topojson for this, and so I am going to store
    // features and geometry information separately.  features will be
    // indexed by id, and by time.  geometry information just by id.

    var header = task.data.features[0].properties.header
    var unmapper = {}
    _.each(header
          ,function(value,idx){
               unmapper[value]=idx
           });


    var data = []
    _.each(task.data.features
          ,function(feature){
               data.push(feature.properties.data)
           });
    data = _.flatten(data,true)
    var docs = _.map(data
                    ,function(v,i){

                         var geom
                         var id=[task.grid.i_cell,task.grid.j_cell,v[unmapper['ts']]].join('_')
                         var geom_id = [task.grid.i_cell,task.grid.j_cell].join('_')
                         var doc={'_id':id
                             ,'geom_id':geom_id
                             ,'i_cell':+task.grid.i_cell
                             ,'j_cell':+task.grid.j_cell}

                         doc.data=v
                         return doc
                     })
    // now to save  docs, the header stuff, linked with expected  topology ids
    //
    // I am assuming that the topology is already or will be stored
    //


    var opts = { 'headers': {}
               };
    opts.headers.authorization = 'Basic ' + new Buffer(cuser + ':' + cpass).toString('base64')
    opts.headers['Content-Type'] =  'application/json'

    // first make sure that the header file exists
    opts.body=JSON.stringify({'_id':'header'
                             ,'header':header
                             ,'unmapper':unmapper})
    opts.uri =  couch +'/header'
    opts.method='PUT'
    request(opts
           ,function(e,r,b){
                if(e) return callback(e)
                // ignore conflicts for now.
                return null
            });
    // now bulkdocs, 100 at a time
    opts.uri= couch +'/_bulk_docs'
    opts.method='POST'
    opts.body=[]
    async.whilst(
        function(){
            return docs !== undefined && docs.length > 0
        }
      ,function(whilst_callback){
           var chunk = docs.splice(0,100)
           console.log(['next',chunk.length,'records,',docs.length,'remaining'].join(' '))
           opts.body = JSON.stringify({'docs':chunk})
           request(opts
                  ,function(e,r,b){
                       if(e){
                           console.log('bulk doc save error '+e)
                           return whilst_callback(e)
                       }
                       return whilst_callback()
                   });
       }
      ,function(err){
           // all done saving docs
           if(err){ throw new Error('failed saving docs to couchdb')}
           return callback(err)
       }
    )

}

exports.couch_file=couch_file

// borrowed from topojson

function flatten(topology) {
  for (var k in topology) {
    if (!topology.hasOwnProperty(k)) topology[k] = topology[k];
    if (typeof topology[k] === "object") flatten(topology[k]);
  }
  return topology;
}
