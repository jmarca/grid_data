/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var fs = require('fs')
var grid_topology = require('../lib/grid_topology').grid_topology
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


var test_db ='carb%2fgrid%2fstate4k'
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
           var task={i0:0
                    ,i1:500
                    ,j0:0
                    ,j1:500
                    ,options:options}

           grid_topology(task
                        ,function(err,cbtask){
                             // err should not exist
                             should.not.exist(err)
                             should.exist(cbtask)
                             console.log(cbtask)
                             done()
                         })
       })
    it('should combine topologies'
      ,function(){

       })
})
