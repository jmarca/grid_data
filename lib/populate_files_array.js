var queue = require('d3-queue').queue

var finder = require('./find_existing_aggregate_files.js')

function populate_files (fqueue,file_worker,root,subdir,years,space_aggregation,time_aggregation,config,cb){
    var regex = /(\d{4})\/(\d+)\/(\d+)\.json/;
    // populate the file combinations array
    // url and file pattern is
    // /data/{area}/{timeagg}/{year}/{filename}
    var numtasks = 0
    var q = queue()
    years.forEach(function(year){
        // just for the grid case
        var rootpath = [root,subdir,space_aggregation,time_aggregation,year].join('/')

        q.defer(finder,{path:rootpath})
        return null
    })

    q.awaitAll(function(e,results){
        if(e){
            console.log('error ',e)
            return cb(e)
        }
        results.forEach(function(r){
            console.log(r)
            r.forEach(function(f){
                // suss i, j
                var res = regex.exec(f)
                var year = +res[1]
                var i = +res[2]
                var j = +res[3]
                fqueue.defer(file_worker,{'file':f
                                          ,'year':year
                                          ,'grid':{'i_cell':i
                                                   ,'j_cell':j}
                                          ,'i':i
                                          ,'j':j
                                          ,options:{'couchdb':config.couchdb}
                                         })
                numtasks++

            })

        })
        console.log('done loading queue, ' +numtasks + ' tasks to process')
        return cb()
    })

    return null
}
module.exports=populate_files
