/*global require process exports JSON console */
var superagent = require('superagent')
var topojson = require('topojson')
var _=require('lodash')
var queue = require('d3-queue').queue
//var async = require('async')
var make_bulkdoc_saver = require('couchdb_bulkdoc_saver')
var save_header_once = require('./save_header_once.js')
/**
 * couch_file
 *
 * save a doc in couchdb
 *
 */
function couch_file(task,callback){

    var options = task.options
    //couchdb

    var host = options.couchdb.host || 'localhost'
    var port = options.couchdb.port ||  5984
    var user,pass

    var cdb   = options.couchdb.db || ['carb','grid','state4k'].join('%2f')
    if(options.couchdb.auth){
        user = options.couchdb.auth.username
        pass = options.couchdb.auth.password
    }

    console.log('writing to ',cdb)
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
    // console.log(Object.keys(task.data.features[0].properties))
    var header = task.data.features[0].properties.header || task.data.features[0].header
    var unmapper = {}
    _.each(header
          ,function(value,idx){
               unmapper[value]=idx
           })
    var data = []
    if(task.flatdata !== undefined && task.flatdata.length > 0){
        data = _.clone(task.flatdata)
    }else{
        _.each(task.data.features
              ,function(feature){
                   data.push(feature.properties.data)
               })
        data = _.flatten(data,true)
    }
    var aadt = task.aadt
    var aadt_summed = []
    var aadt_keys
    // flatten out the aadt here
    // a little gymnastics to not have to hard code the key values
    // because maybe I want to change them in the future

    // outer keys is the list of freeways with detectors
    var outer_keys = Object.keys(aadt)
    //     console.log('outer keys are',outer_keys)

    // inner keys is probably n,hh,not_hh, etc.  but figure it out
    // programmaticaly
    var inner_keys = []
    var start = {}
    outer_keys.forEach(function (fwy){
        (Object.keys(aadt[fwy])).forEach(function(k){
            start[k]=0
            return null
        })
        return null
    })
    //console.log(start)
    aadt_keys = Object.keys(start)

    aadt_summed = outer_keys.reduce(
        function(memo,fwy){
            // console.log(memo)
            aadt_keys.forEach(function(k){
                if(aadt[fwy][k]){
                    memo[k] += aadt[fwy][k]
                }
                return null
            })
            return memo
        }
        ,start)
    //console.log(aadt_summed)
    // check for zero to prevent divide by zero
    aadt_keys.forEach(function(k){
        if(aadt_summed[k]) // yes, if not v then v is zero and skipped
            inner_keys.push(k)
        return null
    })


    // fixme check for possible bug here.  If data has multiple
    // freeways, then id is the same, but will overwrite.  Need to
    // gather instead.
    var docs = {}
    data.forEach(function(v,i){

        var geom
        var id=[task.grid.i_cell,task.grid.j_cell,v[unmapper['ts']]].join('_')

        var geom_id = [task.grid.i_cell,task.grid.j_cell].join('_')

        if(docs[id] === undefined){
            var doc={'_id':id
                     ,'geom_id':geom_id
                     ,'i_cell':+task.grid.i_cell
                     ,'j_cell':+task.grid.j_cell
                     ,'count':1}

            doc.data=[v]
            doc.aadt_frac={}
            inner_keys.forEach(function(aadt_k){
                doc.aadt_frac[aadt_k]=v[unmapper[aadt_k]]/aadt_summed[aadt_k]
                return null
            })
            docs[id]=doc
        }else{
            // tack on row of data
            docs[id].data.push(v)
            //increase aadt_frac
            inner_keys.forEach(function(aadt_k){
                docs[id].aadt_frac[aadt_k] += v[unmapper[aadt_k]]/aadt_summed[aadt_k]
                return null
            })
        }
        return null
    })

    docs = _.values(docs)

    // now to save  docs, the header stuff, linked with expected  topology ids
    //
    // I am assuming that the topology is already or will be stored
    //

    save_header_once(task,function(e,r){
        if(e) throw new Error(e)
        return null
    })

    var saver = make_bulkdoc_saver(cdb,{host : host
                                       ,user : user
                                       ,pass : pass
                                       ,port : port
                                       })
    //console.log('saving to '+cdb+' '+docs[0]._id)
    // now bulkdocs, 100 at a time

    var q = queue(5)
    console.log(['writing',docs.length,'records to couchdb'].join(' '))
    while(docs !== undefined && docs.length > 0){
        var chunk = docs.splice(0,10)
        // console.log(chunk[0])
        // console.log(['next',chunk.length,'records,',docs.length,'remaining'].join(' '))
        q.defer(saver,{docs:chunk})
    }
    q.await(function(err){
        // all done saving docs
        if(err){ throw new Error('failed saving docs to couchdb' + JSON.stringify(err))}
        return callback(err)
    })
    return null
}

exports.couch_file=couch_file

// borrowed from topojson

function flatten(topology) {
  for (var k in topology) {
    if (!topology.hasOwnProperty(k)) topology[k] = topology[k]
    if (typeof topology[k] === "object") flatten(topology[k])
  }
  return topology
}
