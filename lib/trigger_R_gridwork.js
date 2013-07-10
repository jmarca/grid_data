/**
 * trigger_R_gridwork.js
 *
 * This program increments the airbasin and the year and fires off R jobs.
 *
 * Set the number of simultaneous R jobs by the option --num_jobs or
 * the environment variables NUM_R_JOBS
 *
 */

var util  = require('util')
var spawn = require('child_process').spawn
var path = require('path')
var fs = require('fs')
var async = require('async')
var _ = require('lodash')

var statedb = 'vdsdata%2ftracking'

var env = process.env

var optimist = require('optimist')
var argv = optimist
           .usage('infer the likely fraction of aadt by hour for grid cells without highway data, based on nearby grid cells with highway data.\nUsage: $0')
           .options('j',{'default':1
                        ,'alias': 'jobs'
                        ,'describe':'How many simultaneous R jobs to run.  try one, watch your RAM.  Default is one'
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
;
if (argv.help){
    optimist.showHelp();
    return null
}

var years = _.flatten([argv.year])
var jobs = argv.jobs

var areatypes = require('calvad_areas')
var pattern = /(.*)\.json/;
var airbasins = _.map(areatypes.airbasins
                     ,function(basinjson){
                          var match = pattern.exec(basinjson)
                          return match[1]
                      })
// these are broken or use lots of RAM:
var big_basins = [ 'MD', 'NEP', 'SC', 'SF', 'LC', 'MC' ]
// These were successfully done, for 2007
var small_basins = [ 'GBV',  'LT',  'NCC',  'NC',  'SCC', 'SD',  'SJV',  'SS',  'SV' ]

// airbasins = _.filter(airbasins,
//                      function(basin){
//                          return  ( _.indexOf(done_basins,basin) === -1 )
//                      })

airbasins = small_basins

console.log(airbasins)

var RCall = ['--no-restore','--no-save','getallthegrids.R']


function setup_R_job(opts,done){
    var year  = opts.env['CARB_GRID_YEAR']
    var basin = opts.env['AIRBASIN']

    var R  = spawn('Rscript', RCall, opts);
    R.stderr.setEncoding('utf8')
    R.stdout.setEncoding('utf8')
    var logfile = 'log/'+basin+'_'+year+'.log'
    var logstream = fs.createWriteStream(logfile
                                        ,{flags: 'a'
                                         ,encoding: 'utf8'
                                         ,mode: 0666 })
    R.stdout.pipe(logstream)
    R.stderr.pipe(logstream)
    R.on('exit',function(code){
        console.log('got exit: '+code+', for ',[basin,year].join(' '))
        if(code==1){
            // do something special
            done()
        }else{

            done()
        }
        return null
    })
}

var opts = { cwd: './Rwork',
             env: process.env
           }

// just one job while testing
var basin_queue=async.queue(setup_R_job, jobs)
console.log(years)
console.log(airbasins[0])
_.each(years,function(year){
    _.each(airbasins,function(basin){
        var o = _.clone(opts,true)
        o.env['CARB_GRID_YEAR'] = year
        o.env['AIRBASIN'] = basin
        basin_queue.push(o)
    })
});
