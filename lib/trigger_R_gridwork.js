/**
 * trigger_R_gridwork.js
 *
 * This program increments the airbasin and the year and fires off R jobs.
 *
 * Set the number of simultaneous R jobs by the option --num_jobs or
 * the environment variables NUM_R_JOBS
 *
 */

var spawn = require('child_process').spawn
var fs = require('fs')
var queue = require('d3-queue').queue

var _ = require('lodash')

var q
var queued = {}
var redo_ymd = []
var years
var jobs
var startmonth

// these use lots of RAM:
var big_basins = [
    // 'GBV',// comment out during redo runs because it is empty
    'MD',
    'NEP', 'SC', 'SF', 'LC', 'MC' ]
// These were successfully done, for 2007, on lysithia
var small_basins = [ 'LT',  'NCC',  'NC',  'SCC', 'SD',  'SJV',  'SS',  'SV' ]


// var areatypes = require('calvad_areas')
// var pattern = /(.*)\.json/;

var airbasins
var RCall = ['--no-restore','--no-save','process.R']

var opts = { cwd: process.cwd(),  // needs to be where process.R is
             env: process.env
           }

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

if (argv.help){
    optimist.showHelp()
    process.exit()
}

years = _.flatten([argv.year])
jobs = argv.jobs
q = queue(jobs)
startmonth = argv.startmonth
startmonth = Math.floor(startmonth) - 1
startmonth = startmonth < 0 ? 0 : startmonth

console.log('startmonth is ',startmonth)
console.log('jobs is ',jobs)
console.log('years is ',years)


if(argv.basin !== undefined){
    airbasins =  _.flatten([argv.basin])
}else{
    // alternatively, could set it from code, but too complicated
    // airbasins  = _.filter(_.map(areatypes.airbasins
    //                                ,function(basinjson){
    //                                    var match = pattern.exec(basinjson)
    //                                    return match[1]
    //                                }),
    //                          function(basin){
    //                              return  ( _.indexOf(done_basins,basin) === -1 )
    //                          })

    airbasins = _.flatten([big_basins,small_basins])
}

console.log(airbasins)

// just one job while testing
// jobs = 3

// var basin_queue=async.queue(setup_R_job, jobs)
console.log(years)

function setup_R_job(o,done){
    var R,logfile,logstream,errstream
    var year  = o.env.CARB_GRID_YEAR
    var month = o.env.CARB_GRID_MONTH
    var day   = o.env.CARB_GRID_DAY
    var basin = o.env.AIRBASIN

    var key = [year,
               month,
               day,
               basin].join('_')
    console.log('calling R for',key)
    R  = spawn('Rscript', RCall, o)
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
        var o2
        console.log('got exit: '+code+', for ',[basin,year,month,day].join(' '))
        if(code === 0){
            done()
        }else{
            // exit code > 100 means need to redo this
            // year month day
            o2 = {env:{}}
            o2.env.CARB_GRID_YEAR = year
            o2.env.CARB_GRID_MONTH = month
            o2.env.CARB_GRID_DAY = day
            o2.env.AIRBASIN = basin
            redo_ymd.push(Object.assign({},opts,o2))
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
        redo_ymd = []
        q.await(quittingtime)
    }
    return null
}

years.forEach(function(year){
    airbasins.forEach(function(basin){
        var endymd = new Date(year+1, 0, 1, 0, 0, 0)
        var ymd,o,key
        o = {}

        // for debugging, do a few days only
        // var endymd = new Date(year, startmonth, 3, 0, 0, 0)
        for( ymd = new Date(year, startmonth, 1, 0, 0, 0);
             ymd < endymd;
             ymd.setDate(ymd.getDate()+1)){

            o.env = {}
            o.env.CARB_GRID_YEAR = year
            o.env.CARB_GRID_MONTH = +ymd.getMonth() + 1
            o.env.CARB_GRID_DAY = +ymd.getDate()
            o.env.AIRBASIN = basin



            key = [o.env.CARB_GRID_YEAR,
                   o.env.CARB_GRID_MONTH,
                   o.env.CARB_GRID_DAY,
                   o.env.AIRBASIN].join('_')

            console.log('queuing',key)
            q.defer(setup_R_job,Object.assign({},opts,o))


        }
        return null
    })
})

q.await(quittingtime)
