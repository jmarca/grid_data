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
var couch_check = require('couch_check_state')
var couch_set   = require('couch_set_state')

var statedb = 'vdsdata%2ftracking'

var env = process.env

var years = _.flatten[argv.y]
var jobs = argv.j

var areatypes = require('calvad_areas')
var airbasins = areatypes.airbasins

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
        if(code==10){
            // do something special
        }else{
            throw new Error('die in testing')
            done()
        }
        return null
    })
}

var opts = { cwd: undefined,
             env: process.env
           }

// just one job while testing
var basin_queue=async.queue(setup_R_job, 1 ) // jobs)

_.each(years,function(year){
    _.each(airbasins,function(basin){
        var o = _.clone(opts,true)
        o.env['CARB_GRID_YEAR'] = year
        o.env['AIRBASIN'] = basin
        basin_queue.push(o)
    })
});
