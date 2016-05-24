/* global require console process it describe after before */

var should = require('should')

var _ = require('lodash')
var finder = require('../lib/find_existing_aggregate_files.js')
var rootdir = process.cwd()

describe('find files',function(){
    it('should find files that are json and the path and all that'
       ,function(done){
           var task={path:rootdir+'/test/files/grid/hourly/2009'}
           finder(task
                  ,function(err,files){
                      should.not.exist(err)
                      should.exist(files)
                      files.should.have.length(2)
                      files.sort().should.eql([rootdir+'/test/files/hourly/2009/100/263.json'
                                               ,rootdir+'/test/files/hourly/2009/133/154.json'])
                      return done()
                  })
           return null
       })
    return null
})
