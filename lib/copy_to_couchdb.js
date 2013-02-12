
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
var async = require('async')
var pg = require('pg')
var fs = require('fs')

var check_file = require('./check_file').check_file
var read_file = require('./read_file').read_file
var compute_aadt = require('./compute_aadt').compute_aadt
var grab_geom = require('./grab_geom').grab_geom
var couch_file = require('./couch_file').couch_file
var request = require('request')


var optimist = require('optimist')
var argv = optimist
           .usage('aggregate hourly CalVAD data to months, days, and weeks, optiomally summing out freeways.\nUsage: $0')
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
           .argv
;
if (argv.help){
    optimist.showHelp();
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

var i_min = 300
var i_max = 400
var j_min = 250
var j_max = 300
var space_aggregation='grid'
var time_aggregation='hourly'

var years=['2007']//,'2008','2009']


function process_task(task,done){
    async.parallel({grid:function(cb){
                        grab_geom(task,cb)
                    }
                   ,aadt:function(cb){
                        read_file(task
                                 ,function(err,result){
                                      if(err) return cb(err)
                                      return compute_aadt(result,cb)
                                  })
                    }
                   }
                  ,function(err,result){
                       if(err) return done(err,result)
                       task.grid = result.grid.grid
                       task.aadt = result.aadt.aadt
                       // all done
                       console.log('ready to save '+task.file)
                       return done(null,task)
                   })
    return null
}



function populate_files (queue,root,subdir){
    // populate the file combinations array
    // url and file pattern is
    // /data/{area}/{timeagg}/{year}/{filename}

    _.each(years,function(year){
        // just for the grid case
        for(var i = i_min; i<= i_max; i++){
            for(var j=j_min; j<=j_max; j++){

                var hourlyfile = [root,subdir,space_aggregation,time_aggregation,year,i,j+'.json'].join('/');
                queue.push({'file':hourlyfile
                           ,options:options})

            }
        }
    });
    console.log('done loading queue')
}

function file_worker(task,done){
    console.log('starting '+task.file)
    async.waterfall([check_file(task)
                    ,process_task
                    ,couch_file
                    ]
                   ,done)
}

var file_q = async.queue(file_worker, 5)

var root = argv.root;
var subdir = argv.directory;

process.nextTick(function(){
    populate_files(file_q,root,subdir)
    })
