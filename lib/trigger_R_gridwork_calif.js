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
var year
var jobs
var startmonth


// var areatypes = require('calvad_areas')
// var pattern = /(.*)\.json/;

var airbasins
var RCall = ['--no-restore','--no-save','process.R']

var opts = { cwd: process.cwd(),  // needs to be where process.R is
             env: process.env
           }

var argv = require('minimist')(process.argv.slice(2));

if(argv.help){
    console.log('options include',{
        '--year':'the year to process'
        ,'--jobs':'the number of jobs'
        ,'--startmonth':'the starting month of the analysis.  numeric, default 1 (January)'
    })
}

year = argv.year
jobs = argv.jobs
q = queue(jobs)
startmonth = argv.startmonth || 1
startmonth = Math.floor(startmonth) - 1
startmonth = startmonth < 0 ? 0 : startmonth

console.log('startmonth is ',startmonth)
console.log('jobs is ',jobs)
console.log('year is ',year)


console.log(year)

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



var endymd = new Date(year+1, 0, 1, 0, 0, 0)
var ymd,o,key
o = {}

// for debugging, do a few days only
endymd = new Date(year, startmonth, 3, 0, 0, 0)
for( ymd = new Date(year, startmonth, 1, 0, 0, 0);
     ymd < endymd;
     ymd.setDate(ymd.getDate()+1)){

    o.env = {}
    o.env.CARB_GRID_YEAR = year
    o.env.CARB_GRID_MONTH = +ymd.getMonth() + 1
    o.env.CARB_GRID_DAY = +ymd.getDate()
    o.env.AIRBASIN = 'California'

    key = [o.env.CARB_GRID_YEAR,
           o.env.CARB_GRID_MONTH,
           o.env.CARB_GRID_DAY,
           o.env.AIRBASIN].join('_')

    console.log('queuing',key)
    q.defer(setup_R_job,Object.assign({},opts,o))


}


q.await(quittingtime)
