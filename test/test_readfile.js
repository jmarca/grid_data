/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var read_file = require('../lib/read_file').read_file
var fs = require('fs')

describe('read_file',function(){
    it('should not read a file that does not exist and err should be task'
           ,function(done){
                var task={file:'notthere.json'}
                read_file(task
                         ,function(err,cbtask){
                              // file should not exist
                              should.exist(err)
                              should.not.exist(cbtask)
                              err.should.eql(task)
                              done()
                          })
            })
    it('should read a file that exists and return null error and the parsed json file'
           ,function(done){
                var task={file:'./test/files/monthly/2009/100/263.json'}

                read_file(task
                         ,function(err,cbtask){
                              // file should not exist
                              should.not.exist(err)
                              should.exist(cbtask)
                              fs.readFile(task.file
                                         ,function(err,text){
                                              should.not.exist(err)
                                              should.exist(text)
                                              task.data.should.eql(JSON.parse(text))
                                          })

                              done()
                          })
            })
    it('should read a file that exists but has no features, and return an empty data element'
           ,function(done){
                var task={file:'./test/files/hourly/2007/300/250.json'}

                read_file(task
                         ,function(err,cbtask){
                              // file should not exist
                              // file should not exist
                             should.not.exist(err)
                             should.exist(cbtask)
                             cbtask.should.have.property('data')
                             cbtask.data.should.eql({'features':[{'properties':{'data':[]}}]})
                              done()
                          })
            })
})
