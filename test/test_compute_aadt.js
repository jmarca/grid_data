/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var compute_aadt = require('../lib/compute_aadt').compute_aadt
var fs = require('fs')

describe('compute_aadt',function(){
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
                                            var rounded = Math.floor(cbtask.aadt['101'].n)
                                            rounded.should.eql( Math.floor(3154748))
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
    it('should properly compute aadt from hourly file, take two'
      ,function(done){
           var task={file:'./test/files/hourly/2008/133/154.json'}
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
                                            cbtask.aadt.should.have.property('280')
                                            cbtask.aadt['280'].should.have.property('n')
                                            var rounded = Math.round(cbtask.aadt['280'].n)
                                            rounded.should.eql(7867433)
                                            // flat data should be shorter than starting
                                            var data = []
                                            _.each(cbtask.data.features
                                                  ,function(feature){
                                                       data.push(feature.properties.data)
                                                   });
                                            data = _.flatten(data,true)
                                            data.length.should.be.above(cbtask.flatdata.length)
                                            done()

                                        })
                       })
       })

})
