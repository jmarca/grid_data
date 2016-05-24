/* global require console process it describe after before */

var should = require('should')
var spawn = require('child_process').spawn

var queue = require('d3-queue').queue
var querystring = require('querystring')

var logfile = 'log/testvdsimpute.log'

var fs = require('fs')

var request = require('request')

var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = rootdir+'/../test.config.json'
var config_okay = require('config_okay')
var config={}

var utils=require('./utils.js')

var testdb ='test%2fcarb%2fgrid%2fstate4k_invoke'
var config_file_2 = 'test.config.'+Math.round(Math.random()*100)+'.json'

var docs = {'docs':[{'_id':'300_250_2012-01-01 02:00'
                    ,foo:'bar'}
                   ,{'_id':'300_250_2012-01-01 03:00'
                    ,foo:'baz'}
                   ,{'_id':'300_250_2012-01-01 04:00'
                    ,foo:'bat'}
                   ,{'_id':'300_250_2012-01-01 05:00'
                    ,foo:'bah'}
                   ]
           }
describe('test invoke copy_to_couchdb.js',function(){


    before(function(done){
        config_okay(config_file,function(err,c){
            var bq
            if(err){
                console.log('Problem trying to parse options in ',config_file)
                throw new Error(err)
            }
            config.couchdb = Object.assign({},c.couchdb)
            config.couchdb.db = testdb
            bq = queue(1)
            bq.defer(utils.create_tempdb,config)
            bq.defer(function(cb){
                // dump a temporary config file
                config.couchdb.grid_detectors=config.couchdb.db
                fs.writeFile(config_file_2,JSON.stringify(config),
                             {'encoding':'utf8'
                              ,'mode':0o600
                             },function(e){
                                 should.not.exist(e)
                                 return cb(e)
                             })
            })
            bq.defer(function(cb){
                // put docs to be cleared
                var cdb = config.couchdb.host+':'
                        + config.couchdb.port + '/'
                        + config.couchdb.db
                if(!/^http/.test(cdb)){
                    cdb = 'http://'+cdb
                }
                var opts ={}
                opts.method='POST'
                opts.json=docs
                opts.uri = cdb+ '/_bulk_docs'
                request(opts,function(e,r,b){
                    if(e) {
                        console.log(e)
                        return cb(e)
                    }
                    // make sure it got written, so the test at the end
                    // correctly testst that they are gone
                    var startkey=[300,250,2012].join('_')
                    var endkey=[300,250,2013].join('_')
                    opts = {'uri':cdb+'/_all_docs?startkey="'+startkey
                            +'"&endkey="'+endkey+'"'
                            ,'content-type': 'application/json'}
                    request.get(opts
                                ,function(e,r,b){
                                    //console.log(r)
                                    if(e) return done(e)
                                    var c=JSON.parse(b)
                                    c.should.have.property('total_rows',4)
                                    return cb()
                                })

                    return null
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

    // put in tests here for all the options

    it('should work with all the correct options'
       ,function(done){

           var logstream,errstream
           var commandline = ['./lib/trigger_copy_json_to_couchdb.js'
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
               var doneq = queue()
               doneq.defer(function(cb){

                   fs.readFile(logfile,{'encoding':'utf8'},function(err,data){
                       var lines = data.split(/\r?\n/)
                       // console.log(lines)
                       var numrecords
                       var write_regex = /writing\s*(\d+)\s*/i;
                       var err_regex = /error/i;
                       lines.forEach(function(line){
                           // console.log(line)
                           var result = write_regex.exec(line)
                           line.should.not.match(err_regex)
                           if(result && result[1]){
                               numrecords = +result[1]
                           }
                       })
                       numrecords.should.eql(8784)
                       return cb()
                   })
                   return null
               })
               doneq.defer(function(cb){
                   var couchq = queue()
                   var cdb = config.couchdb.host+':'
                           + config.couchdb.port + '/'
                           + config.couchdb.db
                   if(!/^http/.test(cdb)){
                       cdb = 'http://'+cdb
                   }
                   // console.log(cdb)
                   couchq.defer(function(cb2){
                       request.get(cdb+'/_all_docs?include_docs=false'
                                   ,function(e,r,b){
                                       if(e) return done(e)
                                       var c=JSON.parse(b)
                                       c.should.have.property('rows')
                                       var rows = c.rows
                                       rows.sort(function(a,b){
                                           return a.id<b.id ? -1 : 1
                                       })
                                       rows.should.have.length(8785)
                                       c.should.have.property('total_rows',8785)
                                       return cb2()
                                   })
                   })
                   couchq.defer(function(cb2){
                       var startkey=[300,250,2012].join('_')
                       var endkey=[300,250,2013].join('_')
                       var opts = {'uri':cdb+'/_all_docs?startkey="'+startkey
                                   +'"&endkey="'+endkey+'"'
                                   ,'content-type': 'application/json'}
                       request.get(opts
                                   ,function(e,r,b){
                                       if(e) return done(e)
                                       var c=JSON.parse(b)
                                       c.should.have.property('rows')
                                       c.rows.should.have.length(0)
                                       c.should.have.property('total_rows',8785)
                                       return cb2()
                                   })
                   })
                   couchq.await(function(e,r){
                       return cb()
                   })
                   return null
               })
               doneq.await(function(e,r){
                   return done()
               })
               return null
           })
           return null
       })
    return null
})
