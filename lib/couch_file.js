/*global require process exports JSON console */
var superagent = require('superagent')
var topojson = require('topojson')
var _=require('lodash')
var async = require('async')
var make_bulkdoc_saver = require('couchdb_bulkdoc_saver')

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
    if(task.flatdata !== undefined && task.flatdata.length > 0){
        data = _.clone(task.flatdata)
    }else{
        _.each(task.data.features
              ,function(feature){
                   data.push(feature.properties.data)
               });
        data = _.flatten(data,true)
    }
    var aadt = task.aadt
    // flatten out the aadt here
    // a little gymnastics to not have to hard code the key values
    // because maybe I want to change them in the future

    var outer_keys = _.keys(aadt)
    var inner_keys = []
    var start = {}
    _.each(aadt[outer_keys[0]]
          ,function(v,k){
               start[k]=0
           });

    aadt = _.reduce(aadt
                   ,function(memo,value){
                        _.each(value
                              ,function(v,k){
                                   memo[k]+=v
                               });
                        return memo
                    }
                   ,start)
    // check for zero to prevent divide by zero
    _.each(aadt
          ,function(v,k){
               if(v) // yes, if not v then v is zero and skipped
                   inner_keys.push(k)
           });
    var docs = _.map(data
                    ,function(v,i){

                         var geom
                         var id=[task.i,task.j,v[unmapper['ts']]].join('_')
                         var geom_id = [task.i,task.j].join('_')
                         var doc={'_id':id
                                 ,'geom_id':geom_id
                                 ,'i_cell':+task.i
                                 ,'j_cell':+task.j}

                         doc.data=v
                         doc.aadt_frac={}
                         _.each(inner_keys
                               ,function(aadtk){
                                    doc.aadt_frac[aadtk]=v[unmapper[aadtk]]/aadt[aadtk]
                                })
                         return doc
                     })
    // now to save  docs, the header stuff, linked with expected  topology ids
    //
    // I am assuming that the topology is already or will be stored
    //


    // first make sure that the header file exists
    var putbody={'_id':'header'
                ,'header':header
                ,'unmapper':unmapper}
    var uri =  couch +'/header'

    superagent.put(uri)
    .type('json')
    .auth(cuser,cpass)
    .send(putbody)
    .end(function(e,r){
        if(e){
            console.log(e)
            console.log(r)
            throw new Error(e)
        }
        // ignore conflicts for now.
        return null
    })

    var saver = make_bulkdoc_saver(cdb,{chost : chost
                                       ,cuser : cuser
                                       ,cpass : cpass
                                       ,cport : cport
                                       })
    // now bulkdocs, 100 at a time
    async.whilst(
        function(){
            return docs !== undefined && docs.length > 0
        }
      ,function(whilst_callback){
           var chunk = docs.splice(0,1000)
           var hash = {}
           console.log(['next',chunk.length,'records,',docs.length,'remaining'].join(' '))
           saver({docs:chunk},function(e,r){
               if(e){
                   console.log('bulk doc save error '+e)
                   throw new Error(e)
               }
               return whilst_callback()
           });
           return null
       }
      ,function(err){
           // all done saving docs
           if(err){ throw new Error('failed saving docs to couchdb' + JSON.stringify(err))}
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
