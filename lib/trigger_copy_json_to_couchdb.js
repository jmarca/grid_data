
var env = process.env


/**
 * This program will copy all of the files that I cached for grid and
 * put them in couchdb.  It will place the data in whatever database
 * the variable "couchdb:grid_detectors" is pointing to, defaulting to
 * carb/grid/state4k
 *
 */


var http = require('http')
var _ = require('lodash')
var queue = require('d3-queue').queue
var fs = require('fs')
var glob = require('glob')

var check_file = require('./check_file').check_file
var read_file = require('./read_file').read_file
var compute_aadt = require('calvad_compute_aadt')
var grab_geom = require('./grab_geom').grab_geom
var couch_file = require('./couch_file').couch_file
var clear_grid = require('./clear_grid_from_couchdb.js')
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
           .options('c',{'alias':'config'
                         ,'describe':'the config file name, defaults to config.json'
                         ,'default':'config.json'
                        })

           .argv

if (argv.help){
    optimist.showHelp()
    return null
}



var default_grid_db ='carb%2fgrid%2fstate4k'
var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = argv.config
var config_okay = require('config_okay')
var config = {}


var space_aggregation='grid'
var time_aggregation='hourly'

var years = _.flatten([argv.year])


function process_task(task,done){
    var q = queue(1)
    q.defer(read_file,task)
    q.defer(function(cb){
        if(task.data.features[0].properties.data.length < 1){
            console.log('no data for grid',task.i,task.j,task.year,' Clearing it from couchdb')
            return clear_grid(task,cb)
        }
        return compute_aadt(task,cb)
    })
    q.await(function(err,r1,r2,r3){
        if(err){
            //console.log(err)
            return done(err)
        }
        // temporarily comment this out as I don't need it at the
        // moment
        // result.aadt.grid = result.grid.grid

        // all done
        // console.log('ready to save '+task.file)
        return done(null,task)
    })
    return null
}
var populate_files = require('./populate_files_array.js')

function file_worker(task,done){
    var q = queue(1)
    console.log('firing up chain for ',task.file)
    //q.defer(check_file(task))
    q.defer(process_task,task)
    q.defer(couch_file,task)
    q.await(function(e){
        console.log('calling await for',task.file)
        if(e &&
           (e.message === 'no data' ||
            (e.code !== undefined && e.code==='ENOENT'))){
            console.log('skipped and/or deleted from db '+task.file)
            return done()
        }
        if(e){
            console.log('OTHER ERROR:',e)
        }
        return done(e)
    })
    return null
}

var root = argv.root
var subdir = argv.directory


config_okay(process.cwd()+'/'+config_file,function(err,c){
    if(err){
        console.log('Problem trying to parse options in ',config_file)
        throw new Error(err)
    }
    // use grid_detectors database
    if(c.couchdb.grid_detectors !== undefined){
        c.couchdb.db = c.couchdb.grid_detectors
    }
    if(c.couchdb.db === undefined){
        c.couchdb.db = default_grid_db
    }
    Object.keys(c).forEach(function(k){
        config[k]=c[k]
        return null
    })

    var fq = queue(5)
    populate_files(fq,file_worker,root,subdir,years,space_aggregation,time_aggregation,config,function(e,r){
        fq.awaitAll(function(e,results){
            console.log('file worker queue drained')
            return null
        })
    })
    return null
})
