/* global require console process it describe after before */

var should = require('should')
var spawn = require('child_process').spawn

var queue = require('d3-queue').queue

var logfile = 'log/testvdsimpute.log'

var fs = require('fs')

var request = require('request')

var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = rootdir+'/../test.config.json'
var config_okay = require('config_okay')
var config={}

var utils=require('./utils.js')

var testdb ='test%2fcarb%2fgrid%2fstate4k'
var config_file_2 = 'test.config.'+Math.round(Math.random()*100)+'.json'

before(function(done){
    config_okay(config_file,function(err,c){
        var bq
        if(err){
            console.log('Problem trying to parse options in ',config_file)
            throw new Error(err)
        }
        c.couchdb.db = testdb
        config = c
        bq = queue(1)
        bq.defer(utils.create_tempdb,config)
        bq.defer(function(cb){
            // dump a temporary config file
            fs.writeFile(config_file_2,JSON.stringify(config),
                         {'encoding':'utf8'
                          ,'mode':0o600
                         },function(e){
                             should.not.exist(e)
                             return cb(e)
                         })
        })
        bq.await(function(e){
            if(e) throw new Error(e)
            return done()
        })
        return null
    })
})
after(function(done){
    // uncomment to bail in development
    // return done()
    var qa = queue()
    qa.defer(utils.delete_tempdb,config)
    qa.defer(fs.unlink,config_file_2)
    qa.defer(fs.unlink,logfile)
    qa.await(function(e){
        if(e) console.log(e)
        return done()
    })
    return null
})

describe('test invoke copy_to_couchdb.js',function(){

    // put in tests here for all the options

    it('should work with all the correct options'
       ,function(done){

           var logstream,errstream
           var commandline = ['./lib/copy_to_couchdb.js'
                              ,'--config',config_file_2
                              ,'--root',process.cwd()+'/test'
                              ,'--directory','files'
                              ,'-y',2012
                             ]
           var job  = spawn('node', commandline)

           job.stderr.setEncoding('utf8')
           job.stdout.setEncoding('utf8')
           logstream = fs.createWriteStream(logfile
                                            ,{flags: 'a'
                                              ,encoding: 'utf8'
                                              ,mode: 0o666 })
           errstream = fs.createWriteStream(logfile
                                            ,{flags: 'a'
                                              ,encoding: 'utf8'
                                              ,mode: 0o666 })
           job.stdout.pipe(logstream)
           job.stderr.pipe(errstream)
           job.on('exit',function(code){
               fs.readFile(logfile,{'encoding':'utf8'},function(err,data){
                   var lines = data.split(/\r?\n/)
                   // console.log(lines)
                   var numrecords
                   var regex = /writing\s*(\d+)\s*/i;
                   lines.forEach(function(line){
                       var result = regex.exec(line)
                       if(result && result[1]){
                           numrecords = +result[1]
                       }
                   })
                   numrecords.should.eql(8784)
                   return done()
               })
           })
           return null
       })
    return null
})
