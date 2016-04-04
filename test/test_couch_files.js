/* global require console process it describe after before */

var should = require('should')

var queue = require('d3-queue').queue

var _ = require('lodash')
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
        config = Object.assign(config,c)
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
// var env = process.env;
// var cuser = env.COUCHDB_USER ;
// var cpass = env.COUCHDB_PASS ;
// var chost = env.COUCHDB_HOST ;
// var cport = env.COUCHDB_PORT || 5984;
// var puser = process.env.PSQL_USER
// var ppass = process.env.PSQL_PASS
// var phost = process.env.PSQL_TEST_HOST || '127.0.0.1'
// var pport = process.env.PSQL_PORT || 5432


function aadtFile(task,cb){
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
                                     return cb(null,cbtask)


                                 })
                    return null
                })
    return null
}

function create_couch_entries(task,done){
    couch_file(task
               ,function(err,couch_task){
                   console.log('check result of saving to couchdb')
                   should.not.exist(err)
                   // check with couchdb, make sure that what you get is a topology
                   var couch ='http://'+
                           [config.couchdb.host+':'+config.couchdb.port
                            ,config.couchdb.db].join('/')
                   var uri1 = couch +'/header'
                   var uri2 = couch +'/_all_docs?'+['include_docs=true'
                                                    ,'startkey=%22'+[100,263,'2009-01-02%2012:00'].join('_')+'%22'
                                                    ,'endkey=%22'+[100,263,'2009-03-02%2012:00'].join('_')+'%22'].join('&')
                   var docs={}
                   var q = queue()
                   q.defer(function(cb){
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

                   q.defer(function(cb){
                       request.get(uri2
                                   ,function(e,r,b){
                                       if(e) return cb(e)
                                       should.exist(b)
                                       var c = JSON.parse(b)
                                       should.exist(c)
                                       c.rows.length.should.be.above(1)
                                       if(c.rows !== undefined){
                                           c.rows.forEach(function(row){
                                               row.should.have.property('key')
                                               row.should.have.property('value')
                                                                                row.should.have.property('doc')

                                               var doc=row.doc
                                               docs[doc._id]={_id:doc._id
                                                              ,_rev:doc._rev}

                                               doc.should.have.property('geom_id')
                                               doc.should.have.property('data')
                                               doc.data.should.have.length(1)
                                               doc.should.have.property('i_cell')
                                               doc.should.have.property('j_cell')
                                               doc.should.have.property('aadt_frac')
                                               doc.aadt_frac.should.have.property('n')
                                               var roundn = Math.floor(10000*Math.floor(doc.data[0][2]*10000)/Math.floor(1151483024.58 /365 * 10000))
                                               roundn.should.eql(Math.floor(doc.aadt_frac.n*10000))
                                               doc.aadt_frac.should.have.property('hh')
                                               var roundhh = Math.floor(10000*Math.floor(doc.data[0][3]*10000)/Math.floor(10713955.44   /365 * 10000))
                                               roundhh.should.eql(Math.floor(doc.aadt_frac.hh*10000))
                                               doc.aadt_frac.should.have.property('not_hh')
                                               var roundnothh = Math.floor(10000*Math.floor(doc.data[0][4]*10000)/Math.floor(11791466.6/365 * 10000))
                                               roundnothh.should.eql(Math.floor(doc.aadt_frac.not_hh*10000))
                                           })
                                       }
                                       return cb()
                                   })
                       return null

                   })
                   q.await(function(err){
                       done(err,docs)
                   });
                   return null
               })
    return null
}


function overwrite_couch_entries(task,origdocs,done){
    couch_file(task
               ,function(err,cbtask){
                   console.log('check result of overwriting to couchdb')
                   should.not.exist(err)
                   var couch ='http://'+
                           [config.couchdb.host+':'+config.couchdb.port
                            ,config.couchdb.db].join('/')

                   var uri2 = couch +'/_all_docs?'+['include_docs=false'
                                                    ,'startkey=%22'+[100,263,'2009-01-02%2012:00'].join('_')+'%22'
                                                    ,'endkey=%22'+[100,263,'2009-03-02%2012:00'].join('_')+'%22'].join('&')
                   request.get(uri2
                               ,function(e,r,b){
                                   if(e) return cbtask(e)
                                   should.exist(b)
                                   var c = JSON.parse(b)
                                   should.exist(c)
                                   c.should.have.property('rows')
                                   c.rows.length.should.be.above(1)
                                   c.rows.forEach(function(row){
                                       row.should.have.property('key')
                                       row.should.have.property('value')
                                       row.value.should.have.property('rev')
                                       origdocs[row.key]._rev.should.not.eql(row.value.rev)
                                       return null
                                   })
                                   return done()
                               })
                   return null
               })
    return null
}



describe('couch_file',function(){

    it('should write and overwrite couchdb entries'
       ,function(done){
           var task={file:'./test/files/hourly/2009/100/263.json'
                     ,'year':2009
                     ,'i':100
                     ,'j':263
                     ,'options':{'couchdb':config.couchdb}
                    }
           aadtFile(task,function(e,t2){
               create_couch_entries(t2,function(e,docs){
                   overwrite_couch_entries(t2,docs,function(e){
                       return done(e)
                   })
                   return null
               })
               return null
           })
           return null
       })
    return null
})
