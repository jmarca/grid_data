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

var config_okay = require('config_okay')


var test_db ='test%2fcarb%2fgrid%2ftopology'
var options ={}
var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = rootdir+'/../test.config.json'

before(function(done){
    config_okay(config_file,function(err,c){
        var date = new Date()
        var test_db_unique = date.getHours()+'-'
                           + date.getMinutes()+'-'
                           + date.getSeconds()+'-'
                           + date.getMilliseconds()
        options={'chost':c.couchdb.host
                ,'cport':c.couchdb.port
                ,'cusername':c.couchdb.auth.username
                ,'cpassword':c.couchdb.auth.password
                ,'couchdb' : test_db+test_db_unique
                ,'host':c.postgres.host
                ,'port':c.postgres.port
                ,'username':c.postgres.auth.username
                ,'password':c.postgres.auth.password
             }
        return done()
    })
    return null
})

describe('couch_file',function(){
    var created_locally=false
    before(function(done){
        console.log('creating temporary couchdb')
        // create the test couchdb
        var couch = 'http://'+options.chost+':'+options.cport+'/'+options.couchdb
        var opts = {'uri':couch
                   ,'method': "PUT"
                   ,'headers': {}
                   };
        opts.headers.authorization = 'Basic ' + new Buffer(options.cusername + ':' + options.cpassword).toString('base64')
        opts.headers['Content-Type'] =  'application/json'
        request(opts
               ,function(e,r,b){
                    console.log(b)
                    if(e) return done(e)
                    if(JSON.parse(b).error !== undefined) return done(b)
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
        var couch = 'http://'+options.chost+':'+options.cport+'/'+options.couchdb
        var opts = {'uri':couch
                   ,'method': "DELETE"
                   ,'headers': {}
                   };
        opts.headers.authorization = 'Basic ' + new Buffer(options.cuser + ':' + options.cpass).toString('base64')
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
           // var task={i0:140
           //          ,i1:160
           //          ,j0:150
           //          ,j1:200
           var task={i0:91
                    ,i1:316
                    ,j0:21
                    ,j1:279
                    ,options:options}

           grid_topology(task
                        ,function(err,cbtask){
                             // err should not exist
                             should.not.exist(err)
                             should.exist(cbtask)
                             // check with couchdb, make sure that what you get is a topology
                             var couch = 'http://'+options.chost+':'+options.cport+'/'+options.couchdb



                             var uris = [couch +'/topology4326']
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
                                                                          console.log(Object.keys(obj))
                                                                          obj.should.have.property('type')
                                                                          obj.should.have.property('id')
                                                                          obj.id.should.eql('grids')

                                                                      })
                                                               return cb(null)
                                                           })
                                           }
                                          ,done)

                             return null

                         })
       })

})
