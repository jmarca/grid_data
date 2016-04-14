/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var check_file = require('../lib/check_file').check_file

describe('check_file',function(){
    it('should not find a file that does not exist and err should be task'
           ,function(done){
                var task={file:'notthere.json'}
                var checkfile = check_file(task)
                checkfile(function(err,cbtask){
                    // file should not exist
                    should.exist(err)
                    should.exist(cbtask)
                    cbtask.should.eql(task)
                    done()
                })
       })
    it('should find a file that exists and return null error'
           ,function(done){
                var task={file:'./test/test_checkfile.js'}
                var checkfile = check_file(task)
                checkfile(function(err,cbtask){
                    // file should not exist
                    should.not.exist(err)
                    should.exist(cbtask)
                    cbtask.should.eql(task)
                    done()
                })
       })
})
