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
var queue = require('d3-queue').queue

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
           .options('sm',{'alias':'startmonth'
                          ,describe:'The starting month (number value).  Just a small time saver when restarting jobs.  Default is 1 (January)'
                          ,'default':1
                        })
           .options('b',{'alias':'basin'
                        ,describe:'pick one or more airbasins to process each pass.  Multiple basins are possible by saying --basin SJV --basin SV -b SS, for example. If you do not know the basin abbreviations, you should not be running this code'
                        })

           .argv
;
if (argv.help){
    optimist.showHelp();
    return null
}

var years = _.flatten([argv.year])
var jobs = argv.jobs
var startmonth = argv.startmonth
startmonth = Math.floor(startmonth) - 1
startmonth = startmonth < 0 ? 0 : startmonth

console.log('startmonth is ',startmonth)
console.log('jobs is ',jobs)
console.log('years is ',years)



// these use lots of RAM:
var big_basins = [
    'GBV', 'MD',
    'NEP', 'SC', 'SF', 'LC', 'MC' ]
// These were successfully done, for 2007, on lysithia
var small_basins = [ 'LT',  'NCC',  'NC',  'SCC', 'SD',  'SJV',  'SS',  'SV' ]


var areatypes = require('calvad_areas')
// var pattern = /(.*)\.json/;
// var airbasins = _.map(areatypes.airbasins
//                      ,function(basinjson){
//                           var match = pattern.exec(basinjson)
//                           return match[1]
//                       })
// airbasins = _.filter(airbasins,
//                      function(basin){
//                          return  ( _.indexOf(done_basins,basin) === -1 )
//                      })
var airbasins
if(argv.basin !== undefined){
    airbasins =  _.flatten([argv.basin])
}else{
    airbasins = _.flatten([big_basins,small_basins])
}

console.log(airbasins)

var RCall = ['--no-restore','--no-save','process.R']

var opts = { cwd: '.',
             env: process.env
           }
// just one job while testing
// jobs = 3

// var basin_queue=async.queue(setup_R_job, jobs)
console.log(years)

var secondpass = 0

function setup_R_job(o,done){
    var R,logfile,logstream,errstream
    var year  = o.env['CARB_GRID_YEAR']
    var month  = o.env['CARB_GRID_MONTH']
    var day  = o.env['CARB_GRID_DAY']
    var basin = o.env['AIRBASIN']

    R  = spawn('Rscript', RCall, o);
    R.stderr.setEncoding('utf8')
    R.stdout.setEncoding('utf8')
    logfile = 'log/'+basin+'_'+year+'_'+month+'_'+day+'.log'
    logstream = fs.createWriteStream(logfile
                                        ,{flags: 'a'
                                         ,encoding: 'utf8'
                                         ,mode: 0o666 })
    errstream = fs.createWriteStream(logfile
                                     ,{flags: 'a'
                                       ,encoding: 'utf8'
                                       ,mode: 0o666 })
    R.stdout.pipe(logstream)
    R.stderr.pipe(errstream)
    R.on('exit',function(code){
        console.log('got exit: '+code+', for ',[basin,year,month,day].join(' '))
        if(code === 0){
            done()
        }else{
            // exit code > 100 means need to redo this
            // year month day
            var o2 = _.clone(opts,true) // so we keep the working directory, env
            o2.env['CARB_GRID_YEAR'] = year
            o2.env['CARB_GRID_MONTH'] = month
            o2.env['CARB_GRID_DAY'] = day
            o2.env['AIRBASIN'] = basin
            redo_ymd.push(o2)
            //
            done(null,code)
        }
        return null
    })
}

function quittingtime(){
    console.log('done with queue')
    if(redo_ymd.length > 0){
        console.log('need to revisit some days')
        q = queue(jobs)
        redo_ymd.forEach(function(o){
            q.defer(setup_R_job,o)
            return null

        })
        q.await(quittingtime)
    }
    return null
}


var qsize = 0

var q = queue(jobs)
var redo_ymd = []

_.each(years,function(year){
    _.each(airbasins,function(basin){
        var endymd = new Date(year+1, 0, 1, 0, 0, 0)
        // for debugging, do a few days only
        // var endymd = new Date(year, startmonth, 3, 0, 0, 0)
        for( var ymd = new Date(year, startmonth, 1, 0, 0, 0);
             ymd < endymd;
             ymd.setDate(ymd.getDate()+1)){

            var o = _.clone(opts,true) // so we keep the working directory, env
            o.env['CARB_GRID_YEAR'] = year
            o.env['CARB_GRID_MONTH'] = +ymd.getMonth() + 1
            o.env['CARB_GRID_DAY'] = +ymd.getDate()
            o.env['AIRBASIN'] = basin
            q.defer(setup_R_job,o)

        }
        return null
    })
});

q.await(quittingtime)
