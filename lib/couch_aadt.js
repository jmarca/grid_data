/*global require process exports Buffer JSON */
var superagent = require('superagent')
var topojson = require('topojson')
var _=require('lodash')
var async = require('async')

/**
 * couch_file
 *
 * save a doc in couchdb
 *
 */
function couch_aadt(task,callback){

    var options = task.options
    //couchdb
    var chost = options.chost ? options.chost : '127.0.0.1'
    var cuser = options.cusername ? options.cusername : 'myname'
    var cpass = options.cpassword ? options.cpassword : 'secret'
    var cport = options.cport ? options.cport :  5984
    var cdb   = options.couch_db || ['carb','grid','state4k'].join('%2f')
    var couch = 'http://'+chost+':'+cport+'/'+cdb

    // overwrite old docs?? no update

    var geom
    var id=[task.grid.i_cell,task.grid.j_cell,task.year,'aadt'].join('_')
    var geom_id = [task.grid.i_cell,task.grid.j_cell].join('_')
    var doc={'_id':id
            ,'geom_id':geom_id
            ,'i_cell':+task.grid.i_cell
            ,'j_cell':+task.grid.j_cell
            ,'aadt':task.aadt}

    // now to save  docs, the header stuff, linked with expected  topology ids
    //
    // I am assuming that the topology is already or will be stored
    //


    var opts = { 'headers': {}
               };
    opts.headers.authorization = 'Basic ' + new Buffer(cuser + ':' + cpass).toString('base64')
    opts.headers['Content-Type'] =  'application/json'

    var uri= couch +'/'+id
    opts.method='GET'
    superagent.get(uri)
    .type('json')
    .auth(cuser,cpass)
    .end(function(e,r){
        if(e){
            return callback(e)
        }
        var c = r.body
        if(c && c._rev){
            doc._rev=c.rev
        }
        superagent.put(uri)
        .type('json')
        .send(doc)
        .end(function(e,r){
            if(e) return callback(e)
            return callback(null,task)
        })
        return null
    })

}

exports.couch_aadt=couch_aadt
