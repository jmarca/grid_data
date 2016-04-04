/* global require console process it describe after before */

var should = require('should')

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

var testdb ='test%2fcarb%2fgrid%2fstate4k'

before(function(done){
    config_okay(config_file,function(err,c){
        if(err){
            console.log('Problem trying to parse options in ',config_file)
            throw new Error(err)
        }
        c.couchdb.db = testdb
        config = c
        utils.create_tempdb(config,done)
        return null
    })
})
after(function(done){
    // uncomment to bail in development
     return done()
    //utils.delete_tempdb(config,done)
    return null
})

describe('couch file with 2012 and multiple freeeways',function(){

    it('should properly compute aadt, and data field should be right'
       ,function(done){

           var task={file:__dirname+'/files/hourly/2012/231/55.json'
                     ,options:{
                         'postgresql': config.postgresql,
                         'couchdb':config.couchdb
                     }
                     ,year:2012}
           task.options.postgresql.db=config.postgresql.osmdb
           var q = queue(1)
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
               task = Object.assign(task,result_grab,result_aadt)
               task.should.have.property('grid')
               task.grid.should.have.property('i_cell',231)
               task.grid.should.have.property('j_cell',55)

               // all set to set couch saving
               couch_file (task
                           ,function(err,cbtask){
                               should.not.exist(err)
                               var couch ='http://'+
                                       [config.couchdb.host+':'+config.couchdb.port
                                        ,config.couchdb.db].join('/')
                               var uri1 = couch +'/header'
                               var uri2 = couch +'/_all_docs?'+['include_docs=true'
                                                                ,'startkey=%22'+[task.grid.i_cell,task.grid.j_cell,'2012-01-01%2000:00'].join('_')+'%22'
                                                                ,'endkey=%22'+[task.grid.i_cell,task.grid.j_cell,'2012-12-31%2024:00'].join('_')+'%22'].join('&')

                               var q_couch_checks = queue()
                               q_couch_checks.defer(function(cb){
                                   request.get(uri1
                                               ,function(e,r,b){
                                                   if(e) return cb(e)
                                                   should.exist(b)
                                                   var c = JSON.parse(b)
                                                   should.exist(c)
                                                   c.should.have.property('header')
                                                   c.should.have.property('unmapper')
                                                   return cb()
                                               })
                                   return null
                               })

                               q_couch_checks.defer(function(cb){
                                   console.log(uri2)
                                   request.get(uri2
                                               ,function(e,r,b){
                                                   if(e) return cb(e)
                                                   should.exist(b)
                                                   var c = JSON.parse(b)
                                                   should.exist(c)
                                                   c.rows.length.should.eql(8784)
                                                   if(c.rows !== undefined){
                                                       c.rows.forEach(function(row){
                                                           var nval = 0
                                                           var hhval = 0
                                                           var nhval = 0
                                                           row.should.have.property('key')
                                                           row.should.have.property('value')
                                                           row.should.have.property('doc')

                                                           var doc=row.doc
                                                           doc.should.have.property('geom_id')
                                                           doc.should.have.property('data')
                                                           doc.data.should.have.length(3)
                                                           doc.should.have.property('i_cell',task.grid.i_cell)
                                                           doc.should.have.property('j_cell',task.grid.j_cell)
                                                           doc.should.have.property('aadt_frac')

                                                           doc.data.forEach(function(datarow){
                                                               nval += datarow[2]
                                                               hhval += datarow[3]
                                                               nhval += datarow[4]
                                                           })
                                                           // check n
                                                           doc.aadt_frac.should.have.property('n')
                                                           nval /= (619562+327744+303961)
                                                           nval.should.be.approximately(doc.aadt_frac.n,0.01)

                                                           // check hh
                                                           doc.aadt_frac.should.have.property('hh')
                                                           hhval /= (10933+7420+6022)
                                                           hhval.should.be.approximately(doc.aadt_frac.hh,0.01)

                                                           // check nhh
                                                           doc.aadt_frac.should.have.property('not_hh')
                                                           nhval /= (15174+10690+7562)
                                                           nhval.should.be.approximately(doc.aadt_frac.not_hh,0.01)

                                                       })
                                                   }
                                                   return cb()
                                               })
                                   return null

                               })
                               q_couch_checks.await(function(err){
                                   return done(err)
                               });
                           })
               return null
           })
           return null
       })
    return null
})
