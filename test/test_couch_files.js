/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var compute_aadt = require('../lib/compute_aadt').compute_aadt
var fs = require('fs')
var grab_geom = require('../lib/grab_geom').grab_geom
var couch_file = require('../lib/couch_file').couch_file
var request = require('request')


var env = process.env;
var cuser = env.COUCHDB_USER ;
var cpass = env.COUCHDB_PASS ;
var chost = env.COUCHDB_HOST ;
var cport = env.COUCHDB_PORT || 5984;
var puser = process.env.PSQL_USER
var ppass = process.env.PSQL_PASS
var phost = process.env.PSQL_TEST_HOST || '127.0.0.1'
var pport = process.env.PSQL_PORT || 5432


var test_db ='test%2fcarb%2fgrid%2fstate4k'
var options ={'chost':chost
             ,'cport':cport
             ,'cusername':cuser
             ,'cpassword':cpass
             ,'couch_db' : test_db
             ,'host':phost
             ,'port':pport
             ,'username':puser
             ,'password':ppass
             }

describe('couch_file',function(){
    var created_locally=false
    before(function(done){
        console.log('creating temporary couchdb')
        // create the test couchdb
        var couch = 'http://'+chost+':'+cport+'/'+test_db
        var opts = {'uri':couch
                   ,'method': "PUT"
                   ,'headers': {}
                   };
        opts.headers.authorization = 'Basic ' + new Buffer(cuser + ':' + cpass).toString('base64')
        opts.headers['Content-Type'] =  'application/json'
        request(opts
               ,function(e,r,b){
                    if(e) return done(e)
                    created_locally=true
                    return done()
                })
        return null
    })
    after(function(done){
        if(!created_locally) return done()

        // bail in development
        return done()
        console.log('deleting temporary couchdb')
        var couch = 'http://'+chost+':'+cport+'/'+test_db
        var opts = {'uri':couch
                   ,'method': "DELETE"
                   ,'headers': {}
                   };
        opts.headers.authorization = 'Basic ' + new Buffer(cuser + ':' + cpass).toString('base64')
        opts.headers['Content-Type'] =  'application/json'
        request(opts
               ,function(e,r,b){
                    if(e) return done(e)
                    return done()
                })
        return null
    })

    it('should save something to couchdb'
      ,function(done){
           var task={file:'./test/files/monthly/2009/100/263.json'
                    ,options:options}
           async.parallel({grid:function(cb){
                               grab_geom(task
                                        ,function(err,cbtask){
                                             // err should not exist
                                             should.not.exist(err)
                                             should.exist(cbtask)
                                             cbtask.should.have.property('grid')
                                             cbtask.grid.should.have.property('i_cell',100)
                                             cbtask.grid.should.have.property('j_cell',263)
                                             cb(null,cbtask)
                                         })}
                          ,aadt:function(cb){
                               fs.readFile(task.file
                                          ,function(err,text){
                                               should.not.exist(err)
                                               should.exist(text)
                                               task.data = JSON.parse(text)
                                               compute_aadt(task
                                                           ,function(err,cbtask){
                                                                // file should not exist
                                                                should.not.exist(err)
                                                                should.exist(cbtask)
                                                                cbtask.aadt.should.have.property('101')
                                                                cbtask.aadt['101'].should.have.property('n',  1151483024.58 /12)
                                                                cbtask.aadt['101'].should.have.property('hh', 10713955.44   /12)
                                                                cbtask.aadt['101'].should.have.property('not_hh',11791466.6/12)
                                                                cb(null,cbtask)

                                                            })
                                           })
                           }}
                         ,function(err,result){
                              task.grid = result.grid.grid
                              task.aadt = result.aadt.aadt
                              // all set to set couch saving
                              couch_file(task
                                         ,function(err,cbtask){
                                              should.not.exist(err)
                                              done(err)
                                          })
                          })
       })
    it('should combine topologies'
      ,function(done){
           var task={file:'./test/files/monthly/2009/100/264.json'
                    ,options:options}
           async.parallel({grid:function(cb){
                               grab_geom(task
                                        ,function(err,cbtask){
                                             // err should not exist
                                             should.not.exist(err)
                                             should.exist(cbtask)
                                             cbtask.should.have.property('grid')
                                             cbtask.grid.should.have.property('i_cell',100)
                                             cbtask.grid.should.have.property('j_cell',264)
                                             cb(null,cbtask)
                                         })}
                          ,aadt:function(cb){
                               fs.readFile('./test/files/monthly/2009/100/263.json'
                                          ,function(err,text){
                                               should.not.exist(err)
                                               should.exist(text)
                                               task.data = JSON.parse(text)
                                               compute_aadt(task
                                                           ,function(err,cbtask){
                                                                // file should not exist
                                                                should.not.exist(err)
                                                                should.exist(cbtask)
                                                                cbtask.aadt.should.have.property('101')
                                                                cbtask.aadt['101'].should.have.property('n',  1151483024.58 /12)
                                                                cbtask.aadt['101'].should.have.property('hh', 10713955.44   /12)
                                                                cbtask.aadt['101'].should.have.property('not_hh',11791466.6/12)
                                                                cb(null,cbtask)

                                                            })
                                           })
                           }}
                         ,function(err,result){
                              task.grid = result.grid.grid
                              task.aadt = result.aadt.aadt
                              // all set to set couch saving
                              couch_file(task
                                         ,function(err,cbtask){
                                              should.not.exist(err)
                                              done(err)
                                          })
                          })
       })
})
