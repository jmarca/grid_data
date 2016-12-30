/* global require console process it describe after before */

var should = require('should')

var queue = require('d3-queue').queue

var _ = require('lodash')
var fs = require('fs')
var grid_topology = require('../lib/grid_topology').grid_topology
var request = require('request')
var topojson = require('topojson')


var config_okay = require('config_okay')


var utils=require('./utils.js')

var test_db ='test%2fcarb%2fgrid%2ftopology'
var config ={}
var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = rootdir+'/../test.config.json'

describe('couch_file',function(){


    before(function(done){
        config_okay(config_file,function(err,c){
            if(err){
                console.log('Problem trying to parse options in ',config_file)
                throw new Error(err)
            }
            config.couchdb = Object.assign({},c.couchdb)
            config.couchdb.db = test_db
            utils.create_tempdb(config,done)
            config.postgresql = Object.assign({},c.postgresql)
            return null
        })
        // options={'chost':c.couchdb.host
        //         ,'cport':c.couchdb.port
        //         ,'cusername':c.couchdb.auth.username
        //         ,'cpassword':c.couchdb.auth.password
        //         ,'couchdb' : test_db+test_db_unique
        //         ,'host':c.postgres.host
        //         ,'port':c.postgres.port
        //         ,'username':c.postgres.auth.username
        //         ,'password':c.postgres.auth.password
        //      }
        return null
    })

    after(function(done){
        // uncomment to bail in development
        // return done()
        utils.delete_tempdb(config,done)
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
                    ,options:{
                        'postgresql': config.postgresql,
                        'couchdb':config.couchdb
                    }
                   }

           grid_topology(task
                         ,function(err,cbtask){
                             var couch,uri,q
                             // err should not exist
                             should.not.exist(err)
                             should.exist(cbtask)
                             // check with couchdb, make sure that what you get is a topology
                             couch ='http://'+
                                 [config.couchdb.host+':'+config.couchdb.port
                                  ,config.couchdb.db].join('/')



                             uri = couch +'/topology4326'

                             request.get(uri
                                         ,function(e,r,b){
                                             if(e) return done(e)
                                             // b should be a topology object
                                             should.exist(b)
                                             var c = JSON.parse(b)
                                             should.exist(c)
                                             c.should.have.property('type','Topology')
                                             c.should.have.property('objects')
                                             var topo_objects = c.objects
                                             topo_objects.should.have.keys(['grids'])
                                             //console.log(Object.keys(topo_objects))
                                             var obj = topo_objects.grids
                                             obj.should.have.property('type')
                                             obj.should.have.property('id')
                                             obj.id.should.eql('grids')
                                             obj.should.have.property('geometries')
                                             Object.keys(obj.geometries).length.should.eql(25083)
                                             return done(null)
                                         })
                             return null
                         })

          return null
       })

})
