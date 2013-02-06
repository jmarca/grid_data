/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var fs = require('fs')
var grid_topology = require('../lib/grid_topology').grid_topology
var request = require('request')
var topojson = require('topojson')

var env = process.env;
var cuser = env.COUCHDB_USER ;
var cpass = env.COUCHDB_PASS ;
var chost = env.COUCHDB_HOST ;
var cport = env.COUCHDB_PORT || 5984;
var puser = process.env.PSQL_USER
var ppass = process.env.PSQL_PASS
var phost = process.env.PSQL_TEST_HOST || '127.0.0.1'
var pport = process.env.PSQL_PORT || 5432


var test_db ='test%2fcarb%2fgrid%2ftopology'
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
           var task={i0:140
                    ,i1:160
                    ,j0:150
                    ,j1:200
                    ,options:options}

           grid_topology(task
                        ,function(err,cbtask){
                             // err should not exist
                             should.not.exist(err)
                             should.exist(cbtask)
                             // check with couchdb, make sure that what you get is a topology
                             var couch = 'http://'+chost+':'+cport+'/'+test_db


                             var uris = [couch +'/topology4326',couch +'/topology']
                             async.forEach(uris
                                          ,function(uri,cb){
                                               request.get(uri
                                                          ,function(e,r,b){
                                                               if(e) return cb(e)
                                                               // b should be a topology object
                                                               should.exist(b)
                                                               var c = JSON.parse(b)
                                                               should.exist(c)
                                                               c.should.have.property('type','Topology')
                                                               c.should.have.property('objects')
                                                               var topo_objects = c.objects
                                                               _.each(topo_objects
                                                                     ,function(obj){
                                                                          obj.should.have.property('type')
                                                                          obj.should.have.property('id')
                                                                          obj.id.should.match(/^\d+_\d+$/)

                                                                      })
                                                               c.should.have.property('arcs')
                                                               c.arcs.should.have.property('length')
                                                               c.arcs.length.should.be.above(0)
                                                               console.log('arcs.length is '+c.arcs.length)
                                                               return cb(null)
                                                           })
                                           }
                                          ,done)

                             return null

                         })
       })

})
