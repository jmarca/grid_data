/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var compute_aadt = require('../lib/compute_aadt').compute_aadt
var fs = require('fs')

describe('compute_aadt',function(){
    it('should properly compute aadt from month file'
      ,function(done){
           var task={file:'./test/files/monthly/2009/100/263.json'}
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
                                            cbtask.aadt['101'].should.have.property('n',  1151483024.58 /12)
                                            cbtask.aadt['101'].should.have.property('hh', 10713955.44   /12)
                                            cbtask.aadt['101'].should.have.property('not_hh',11791466.6/12)
                                            done()

                                        })
                       })
       })
    it('should properly compute aadt from hourly file'
      ,function(done){
           var task={file:'./test/files/hourly/2009/100/263.json'}
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
                                            done()

                                        })
                       })
       })
    it('should compute yearly from month and hourly and get same result'
      ,function(){
           //var motask={file:'./test/files/monthly/2009/100/263.json'}
           //var hourtask={file:'./test/files/hourly/2009/100/263.json'}

       })
})
