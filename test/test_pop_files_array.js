/* global require console process it describe after before */

var should = require('should')

var _ = require('lodash')
var populate_files = require('../lib/populate_files_array.js')
var rootdir = process.cwd()
var queue = require('d3-queue').queue

describe('find files',function(){
    it('should find files that are json and the path and all that'
       ,function(done){
           function file_worker(f,cb){
               return cb(null,f)
           }
           var fq = queue()
           var task={path:rootdir+'/test/files/grid/hourly/2009'}

           populate_files(fq,file_worker,rootdir,'test/files',[2009,2012],'grid','hourly',{couchdb:'blahblah'},
                          function(e,r){
                              should.not.exist(e)
                              fq.awaitAll(function(e,results){
                                  results.sort(function(a,b){
                                      return a.file < b.file ? -1 : 1
                                  })
                                  results.length.should.eql(3)
                                  results[0].should.eql({
                                      file:rootdir+'/test/files/hourly/2009/100/263.json'
                                      ,year:2009
                                      ,grid:{'i_cell':100,'j_cell':263}
                                      ,i:100
                                      ,j:263
                                      ,options:{'couchdb':'blahblah'}
                                  })


                                  results[1].should.eql({
                                      file:rootdir+'/test/files/hourly/2009/133/154.json'
                                      ,year:2009
                                      ,grid:{'i_cell':133,'j_cell':154}
                                      ,i:133
                                      ,j:154
                                      ,options:{'couchdb':'blahblah'}
                                  })

                                  results[2].should.eql({
                                      file:rootdir+'/test/files/hourly/2012/231/55.json'
                                      ,year:2012
                                      ,grid:{'i_cell':231,'j_cell':55}
                                      ,i:231
                                      ,j:55
                                      ,options:{'couchdb':'blahblah'}
                                  })

                                  return done()
                              })
                          })

           return null
       })
    return null
})
