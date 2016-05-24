
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

var i_min = 90
//var i_min = 241
var i_max = 400
var j_min = 20
var j_max = 300
var space_aggregation='grid'
var time_aggregation='hourly'

var years = _.flatten([argv.year])


function process_task(task,done){
    var q = queue(1)
    // q.defer(function(cb){
    //        grab_geom(task,cb)
    //   })
    q.defer(function(cb){
        read_file(task,cb)
    })
    q.defer(function(cb){
        if(task.data.features[0].properties.data.length < 1){
            return clear_couchdb(task,cb)
        }
        return compute_aadt(task,cb)
    })
    q.await(function(err,r1,r2,r3){
        if(err) return done(err)
        // result.aadt.grid = result.grid.grid  // temporarily comment this out as I don't need it at the moment
        // all done
        // console.log('ready to save '+task.file)
        return done(null,task)
    })
    return null
}
var populate_files = require('./populate_files_array.js')

function file_worker(task,done){

    var q = queue(1)
    q.defer(check_file(task))
    q.defer(function(cb){
        // console.log('calling process_task for ',task.grid.i_cell,'_',task.grid.j_cell)
        return process_task(task,cb)
    })
    q.defer(function(cb){
        console.log('calling couch_file for ',task.file,task.grid.i_cell,task.grid.j_cell)
        return couch_file(task,cb)
    })
    q.await(function(e){
        if(e &&
           (e.message === 'no data' ||
            (e.code !== undefined && e.code==='ENOENT'))){
            //console.log('skip '+task.file+', does not exist')
            return done()
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
    populate_files(fq,root,subdir,years)
    return null
})
