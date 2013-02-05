/*global require process exports */
var request = require('request')
var topojson = require('topojson')


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


    var header = task.data.features.properties.header
    var unmapper = {}
    _.each(header
          ,function(value,idx){
               unmapper[value]=idx
           });

    var data = task.data.features.properties.data
    var geoms = {}
    var docs = _.map(data
                    ,function(v,i){
                         var doc={}
                         var geom
                         var id=[task.geom.i_cell,task.geom.j_cell,doc[unmapper['ts']]].join('_')
                         var geom_id = [task.geom.i_cell,task.geom.j_cell].join('_')
                         doc._id=id
                         doc.geom_id=geom_id
                         if(geoms[geom_id]===undefined){
                             var geo = {type: "Feature"
                                       ,id: geom_id
                                       ,properties: _.clone(task.geom)
                                       ,geometry: task.geom.geom4326}
                             geoms[geom_id]=geo
                         }
                         doc.data=v
                     })
    // now to save both docs, and topology
    var topo = topojson.topology(geoms)
    var uri = couch +'/topology'
    var opts = {'uri':uri
               , 'method': "PUT"
               , 'body': topo
               , 'headers': {}
               };
    opts.headers.authorization = 'Basic ' + new Buffer(cuser + ':' + cpass).toString('base64')
    opts.headers['Content-Type'] =  'application/json'
    request(opts
           ,function(e,r,b){
                if(e) return callback(e)
                return null
            });
    // now bulkdocs, 1000 at a time
    opts.uri= couch +'/_bulk_docs'
    opts.method='POST'
    opts.body=[]
    async.whilst(
        function(){
            return docs !== undefined && docs.length > 0
        }
      ,function(whilst_callback){
           var chunk = docs.splice(0,1000)
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
