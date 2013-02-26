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

        var couch = 'http://'+chost+':'+cport+'/'+test_db
        // bail in development
        //console.log(couch)
        //return done()
        console.log('deleting temporary couchdb')
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

    it('should write and overwrite couchdb entries'
      ,function(done){
           async.waterfall([create_couch_entries,overwrite_couch_entries],done)
       })
})


function create_couch_entries(done){
    var task={file:'./test/files/hourly/2009/100/263.json'
             ,'year':2009
             ,'i':100
             ,'j':263
             ,options:options}
    async.parallel({grid:function(cb){ cb() }
        //      grab_geom(task
        //               ,function(err,cbtask){
        //                    // err should not exist
        //                    should.not.exist(err)
        //                    should.exist(cbtask)
        //                    cbtask.should.have.property('grid')
        //                    cbtask.grid.should.have.property('i_cell',100)
        //                    cbtask.grid.should.have.property('j_cell',263)
        //                    cb(null,cbtask)
        //                })}
        //
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
                       console.log('aadt done')
                       //task.grid = result.grid.grid
                       task = result.aadt
                       // all set to set couch saving
                       couch_file(task
                                 ,function(err,cbtask){
                                      should.not.exist(err)
                                      // check with couchdb, make sure that what you get is a topology
                                      var couch = 'http://'+chost+':'+cport+'/'+test_db


                                      var uri1 = couch +'/header'

                                      var uri2 = couch +'/_all_docs?'+['include_docs=true'
                                                                      ,'startkey=%22'+[100,263,'2009-01-02%2012:00'].join('_')+'%22'
                                                                      ,'endkey=%22'+[100,263,'2009-03-02%2012:00'].join('_')+'%22'].join('&')
                                      var docs={}
                                      async.parallel([function(cb){
                                                          request.get(uri1
                                                                     ,function(e,r,b){
                                                                          if(e) return cb(e)
                                                                          // b should be a topology object
                                                                          should.exist(b)
                                                                          var c = JSON.parse(b)
                                                                          should.exist(c)
                                                                          c.should.have.property('header')
                                                                          c.should.have.property('unmapper')
                                                                          return cb()
                                                                      })}
                                                     ,function(cb){
                                                          request.get(uri2
                                                                     ,function(e,r,b){
                                                                          if(e) return cb(e)
                                                                          // b should be a topology object
                                                                          should.exist(b)
                                                                          var c = JSON.parse(b)
                                                                          should.exist(c)

                                                                          c.rows.length.should.be.above(1)
                                                                          if(c.rows !== undefined){
                                                                              _.each(c.rows
                                                                                    ,function(row){
                                                                                         row.should.have.property('key')
                                                                                         row.should.have.property('value')
                                                                                         row.should.have.property('doc')

                                                                                         var doc=row.doc
                                                                                         docs[doc._id]={_id:doc._id
                                                                                                       ,_rev:doc._rev}

                                                                                         doc.should.have.property('geom_id')
                                                                                         doc.should.have.property('data')
                                                                                         doc.data.should.have.property('length')
                                                                                         doc.data.length.should.be.above(0)
                                                                                         doc.should.have.property('i_cell')
                                                                                         doc.should.have.property('j_cell')
                                                                                         doc.should.have.property('aadt_frac')
                                                                                         doc.aadt_frac.should.have.property('n')
                                                                                         var roundn = Math.floor(10000*Math.floor(doc.data[2]*10000)/Math.floor(1151483024.58 /365 * 10000))
                                                                                         roundn.should.eql(Math.floor(doc.aadt_frac.n*10000))
                                                                                         doc.aadt_frac.should.have.property('hh')
                                                                                         var roundhh = Math.floor(10000*Math.floor(doc.data[3]*10000)/Math.floor(10713955.44   /365 * 10000))
                                                                                         roundhh.should.eql(Math.floor(doc.aadt_frac.hh*10000))
                                                                                         doc.aadt_frac.should.have.property('not_hh')
                                                                                         var roundnothh = Math.floor(10000*Math.floor(doc.data[4]*10000)/Math.floor(11791466.6/365 * 10000))
                                                                                         roundnothh.should.eql(Math.floor(doc.aadt_frac.not_hh*10000))
                                                                                     })
                                                                          }
                                                                          return cb()
                                                                      })
                                                      }]
                                                    ,function(err){
                                                         done(err,docs)
                                                     });

                                      return null


                                  })
                   })
}

function overwrite_couch_entries(origdocs,done){
    var task={file:'./test/files/hourly/2009/100/263.json'
             ,'year':2009
             ,'i':100
             ,'j':263
             ,options:options}
    async.parallel({aadt:function(cb){
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
                                                         cb(null,cbtask)
                                                     })
                                    })
                    }}
                  ,function(err,result){
                       task = result.aadt
                       // all set to set couch saving
                       couch_file(task
                                 ,function(err,cbtask){
                                      should.not.exist(err)
                                      var couch = 'http://'+chost+':'+cport+'/'+test_db
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
                                                      _.each(c.rows
                                                            ,function(row){
                                                                 row.should.have.property('key')
                                                                 row.should.have.property('value')
                                                                 row.value.should.have.property('rev')
                                                                 origdocs[row.key]._rev.should.not.eql(row.value.rev)
                                                             });
                                                      return done()
                                                  });
                                  });

                       return null


                   })
    return null
}
