/* global require console process it describe after before */

var should = require('should')

//var async = require('async')
var queue = require('d3-queue').queue

var compute_aadt = require('calvad_compute_aadt')
var fs = require('fs')
var grab_geom = require('../lib/grab_geom').grab_geom
var couch_file = require('../lib/couch_file').couch_file
var request = require('request')

var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = rootdir+'/../test.config.json'
var config_okay = require('config_okay')
var config={}

var utils=require('./utils.js')

var test_db ='test%2fcarb%2fgrid%2fstate4k'

before(function(done){
    config_okay(config_file,function(err,c){
        if(err){
            console.log('Problem trying to parse options in ',config_file)
            throw new Error(err)
        }
        if(c.couchdb.db === undefined){
            c.couchdb.db = 'testdb'
        }
        config = c
        utils.create_tempdb(config,done)
        return null
    })
})
after(function(done){
    // uncomment to bail in development
    // return done()
    utils.delete_tempdb(config,done)
    return null
})

describe('couch file with 2012 and multiple freeeways',function(){

    it('should properly compute aadt, and data field should be right'
       ,function(done){

           var task={file:__dirname+'/files/hourly/2012/231/55.json'
                     ,'i':231
                     ,'j':55
                     ,options:{
                         'postgresql': config.postgresql,
                         'couchdb':config.couchdb
                     }
                     ,year:2012}
           task.options.postgresql.db=config.postgresql.osmdb
           var q = queue()
           q.defer(function(cb){
               grab_geom(task
                         ,function(err,cbtask){
                             // err should not exist
                             should.not.exist(err)
                             should.exist(cbtask)
                             cbtask.should.have.property('grid')
                             cbtask.grid.should.have.property('i_cell',231)
                             cbtask.grid.should.have.property('j_cell',55)
                             cb(null,cbtask)
                         })
           })
           q.defer(function(cb){
               fs.readFile(task.file
                           ,function(err,text){
                               should.not.exist(err)
                               should.exist(text)
                               task.data = JSON.parse(text)
                               compute_aadt(task
                                            ,function(err,cbtask){
                                                should.not.exist(err)
                                                should.exist(cbtask)
                                                cbtask.should.have.property('aadt')
                                                cbtask.aadt.should.have.property('22')
                                                cbtask.aadt.should.have.property('5')
                                                cbtask.aadt.should.have.property('57')

                                                ;(['n','hh','not_hh']).forEach(function(e){
                                                    cbtask.aadt['22'].should.have.property(e)
                                                    cbtask.aadt['5'].should.have.property(e)
                                                    cbtask.aadt['57'].should.have.property(e)
                                                    return null
                                                })

                                                cbtask.aadt['5'].n     .should.be.approximately(619562.39,1)
                                                cbtask.aadt['5'].hh    .should.be.approximately(10933.172185792350,1)
                                                cbtask.aadt['5'].not_hh.should.be.approximately(15173.708551912568,1)

                                                cbtask.aadt['22'].n     .should.be.approximately(327744.544726775956,1)
                                                cbtask.aadt['22'].hh    .should.be.approximately(7419.8778961748633880,1)
                                                cbtask.aadt['22'].not_hh.should.be.approximately(10690.364262295082,1)

                                                cbtask.aadt['57'].n     .should.be.approximately(303961.863224043716,1)
                                                cbtask.aadt['57'].hh    .should.be.approximately(6021.5822950819672131,1)
                                                cbtask.aadt['57'].not_hh.should.be.approximately(7561.9371311475409836,1)


                                                cb(null,cbtask)

                                            })
                               return  null
                           })
               return null
           })

           q.await(function(err,result_grab,result_aadt){
               task.grid = result_grab.grid
               task.aadt = result_aadt.aadt
               console.log(Object.keys(task))
               console.log(task.aadt)
               // all set to set couch saving
               couch_file (task
                           ,function(err,cbtask){
                               should.not.exist(err)
                               return done(err)
                           })
               return null
           })
           return null
       })
    return null
})
