/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var compute_aadt = require('../lib/compute_aadt').compute_aadt
var fs = require('fs')
var grab_geom = require('../lib/grab_geom').grab_geom
var couch_aadt = require('../lib/couch_aadt').couch_aadt
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

describe('couch_aadt',function(){
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
                    console.log('created '+couch)
                    return done()
                })
        return null
    })
    after(function(done){
        if(!created_locally) return done()

        // uncomment to bail in development
        // return done()
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
           var task={file:'./test/files/hourly/2009/100/263.json'
                    ,options:options
                    ,year:2009}
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
                                                                cbtask.aadt['101'].should.have.property('n')
                                                                var rounded = Math.floor(10000 * cbtask.aadt['101'].n)
                                                                rounded.should.eql( Math.floor(1151483024.58 /365 * 10000))
                                                                cbtask.aadt['101'].should.have.property('hh')
                                                                rounded = Math.floor(10000 * cbtask.aadt['101'].hh)
                                                                rounded.should.eql( Math.floor( 10713955.44   /365 * 10000))
                                                                cbtask.aadt['101'].should.have.property('not_hh')
                                                                rounded = Math.floor(10000 * cbtask.aadt['101'].not_hh)
                                                                rounded.should.eql( Math.floor(11791466.6/365 *10000))
                                                                cb(null,cbtask)

                                                            })
                                           })
                           }}
                         ,function(err,result){
                              task.grid = result.grid.grid
                              task.aadt = result.aadt.aadt
                              // all set to set couch saving
                              couch_aadt(task
                                        ,function(err,cbtask){
                                             should.not.exist(err)
                                             // check with couchdb, make sure that what you get is a topology
                                             var couch = 'http://'+chost+':'+cport+'/'+test_db
                                             var uri = couch +'/100_263_2009_aadt'
                                             request.get(uri
                                                        ,function(e,r,b){
                                                             if(e) return done(e)
                                                             should.exist(b)
                                                             var doc = JSON.parse(b)
                                                             should.exist(doc)
                                                             console.log(doc)
                                                             doc.should.have.property('geom_id')
                                                             doc.should.have.property('aadt')
                                                             doc.should.have.property('i_cell')
                                                             doc.should.have.property('j_cell')
                                                             doc.should.have.property('aadt')
                                                             doc.aadt.should.have.property('101')
                                                             doc.aadt['101'].should.have.property('n')
                                                             var rounded = Math.floor(10000 * doc.aadt['101'].n)
                                                             rounded.should.eql( Math.floor(1151483024.58 /365 * 10000))
                                                             doc.aadt['101'].should.have.property('hh')
                                                             rounded = Math.floor(10000 * doc.aadt['101'].hh)
                                                             rounded.should.eql( Math.floor( 10713955.44   /365 * 10000))
                                                             doc.aadt['101'].should.have.property('not_hh')
                                                             rounded = Math.floor(10000 * doc.aadt['101'].not_hh)
                                                             rounded.should.eql( Math.floor(11791466.6/365 *10000))
                                                             return done(null)
                                                         });
                                             return null
                                         })
                          })
       })
})
