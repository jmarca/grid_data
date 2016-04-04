
var env = process.env


/**
 * This program will copy all of the files that I cached for grid and
 * put them in couchdb
 *
 */


var cuser = env.COUCHDB_USER
var cpass = env.COUCHDB_PASS
var chost = env.COUCHDB_HOST
var cport = env.COUCHDB_PORT || 5984
var puser = env.PSQL_USER
var ppass = env.PSQL_PASS
var phost = env.PSQL_HOST || '127.0.0.1'
var pport = env.PSQL_PORT || 5432

var http = require('http')
var _ = require('lodash')
var queue = require('d3-queue').queue
var pg = require('pg')
var fs = require('fs')

var check_file = require('./check_file').check_file
var read_file = require('./read_file').read_file
var compute_aadt = require('calvad_compute_aadt')
var grab_geom = require('./grab_geom').grab_geom
var couch_file = require('./couch_file').couch_file
var superagent = require('superagent')


var optimist = require('optimist')
var argv = optimist
           .usage('copy all of the files cached for grid and put them in couchdb.\nUsage: $0')
           .options('r',{'default':process.cwd()
                        ,'alias':'root'
                        ,'describe':'The root directory, probably under the Calvad web server.  Will default to the current working directory.  Another choice might be "public", or perhaps "/home/james/repos/jem/carbserver/public"'
                        })
           .options('d',{'default':'data'
                        ,'alias': 'directory'
                        ,'describe':'The directory under the root directory (see the root option) where the data to copy to couchdb resides.  Defaults to data'
                        })
           .options("h", {'alias':'help'
                         ,'describe': "display this hopefully helpful message"
                         ,'type': "boolean"
                         ,'default': false
                         })
           .options('y',{'demand':true
                        ,'alias':'year'
                        ,describe:'One or more years to process.  Specify multiple years as --year 2007 --year 2008'
                        })

           .argv

if (argv.help){
    optimist.showHelp()
    return null
}



var grid_db ='carb%2fgrid%2fstate4k'
var options ={'chost':chost
             ,'cport':cport
             ,'cusername':cuser
             ,'cpassword':cpass
             ,'couch_db' : grid_db
             ,'host':phost
             ,'port':pport
             ,'username':puser
             ,'password':ppass
             }

var i_min = 90
//var i_min = 241
var i_max = 400
var j_min = 20
var j_max = 300
var space_aggregation='grid'
var time_aggregation='hourly'

var years = _.flatten([argv.year])

function process_task(task,done){
    var q = queue()
    //q.defer(function(cb){
    //       grab_geom(task,cb)
    //  })
    q.defer(function(cb){
        read_file(task
                  ,function(err,result){
                      if(err) return cb(err)
                      if(task.data.features[0].properties.data.length < 1){
                          return cb(new Error('no data'),task)
                      }
                      return compute_aadt(result,cb)
                  })
    })
    q.await(function(err,result){
        if(err) return done(err,result)
        // result.aadt.grid = result.grid.grid  // temporarily comment this out as I don't need it at the moment
        // all done
        console.log('ready to save '+task.file)
        return done(null,result)
    })
    return null
}



function populate_files (queue,root,subdir,years){
    // populate the file combinations array
    // url and file pattern is
    // /data/{area}/{timeagg}/{year}/{filename}

    years.forEach(function(year){
        // just for the grid case
        for(var i = i_min; i<= i_max; i++){
            for(var j=j_min; j<=j_max; j++){

                var hourlyfile = [root,subdir,space_aggregation,time_aggregation,year,i,j+'.json'].join('/')
                queue.defer(file_worker,{'file':hourlyfile
                           ,'year':year
                           ,'i':i
                           ,'j':j
                           ,options:options})

            }
        }
    })
    console.log('done loading queue' +queue.length() + ' tasks to process')
    return null
}

function file_worker(task,done){

    var q = queue(1)
    q.defer(check_file(task))
    q.defer(process_task,task)
    q.defer(couch_file,task)
    q.await(function(e){
        if(e &&
           (e.message === 'no data' ||
            (e.code !== undefined && e.code==='ENOENT'))){
            console.log('skip '+task.file+', does not exist')
            return done()
        }
        return done(e)
    })
    return null
}

var root = argv.root
var subdir = argv.directory


var fq = queue(3)
populate_files(fq,root,subdir,years)


function create_db(couchdb){
    return function(cb){
        superagent.put(couchdb)
        .auth(cuser,cpass)
        .end(function(e,r){
            if(e) throw new Error(e)
            return cb()
        })
        return null
    }
}
