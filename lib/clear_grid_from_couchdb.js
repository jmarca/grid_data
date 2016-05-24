
var request = require('request')
var viewer = require('couchdb_get_views')

/**
 * clear a grid cell from couchdb for the given year
 *
 * Call this when you want to make sure that couchdb does not contain
 * any data for a given grid cell, year.  This is currently used when
 * loading data, called when a cell has no data.
 *
 * The logic: first a quick query to see if there are any docs for the
 * grid cell in the given year.  If there are, then those docs are
 * passed to bulk delete function.
 *
 * @param {Object} task the object containing options parameters
 * @param {number} task.year the year to use
 * @param {number} task.i the i of the grid cell
 * @param {number} task.j the j of the grid cell
 * @param {Object} task.options.couchdb configuration information for
 *                 couchdb access
 * @param {function} cb the callback to call, with error or null in first argument
 */
function clear_couchdb(task,cb){

    var firstdate = task.year +'-01-00'
    var lastdate = task.year +'-12-32'
    var first_doc_id=[task.i,task.j,firstdate].join('_')
    var last_doc_id=[task.i,task.j,lastdate].join('_')

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

    function deleter(docs,next){
        // passed a block of docs.  need to DELETE them
        var del_docs = _.map(docs
                             ,function(row){
                                 return {'_id':row.doc._id
                                         ,'_rev':row.doc._rev
                                         ,'_deleted':true}
                             });
        var bulkuri = couch+'/'+cdb+ '/_bulk_docs'
        var opts =  {'uri':bulkuri
                     , 'method': "POST"
                     , 'body': JSON.stringify({'docs':del_docs})
                     , 'headers': {}
                    }
        opts.headers.authorization = 'Basic '
            + new Buffer(user + ':' + pass).toString('base64')

        opts.headers['Content-Type'] =  'application/json'
        request(opts
                ,function(e,r,b){
                    if(e){ console.log('bulk delete error '+e)
                           return next(e)
                         }
                    return next()
                });
        return null
    }

    viewer(Object.assign({}
                         ,options.couchdb
                         ,{'view':'_all_docs'
                           ,'startkey':first_doc_id
                           ,'endkey':last_doc_id
                           ,'reduce':false
                           ,'include_docs':false
                          })
           ,function(e,docs){
               if(e) {
                   console.log(e)
                   throw new Error(e)
               }
               if(docs.length>0){
                    deleter(docs,cb)
               }else{
                   cb()
               }

               return null
           })
    return null
}
