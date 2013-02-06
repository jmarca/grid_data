/* global require console process it describe after before */

var should = require('should')

var async = require('async')
var _ = require('lodash')
var grab_geom = require('../lib/grab_geom').grab_geom
var fs = require('fs')


var env = process.env;
var puser = process.env.PSQL_USER
var ppass = process.env.PSQL_PASS
var phost = process.env.PSQL_TEST_HOST || '127.0.0.1'
var pport = process.env.PSQL_PORT || 5432

var options ={'host':phost
             ,'port':pport
             ,'username':puser
             ,'password':ppass
             }

describe('grab_geom',function(){
    it('should properly compute aadt from month file'
      ,function(done){
           var task={file:'./test/files/monthly/2009/100/263.json'
                    ,options:options}
           grab_geom(task
                    ,function(err,cbtask){
                         // err should not exist
                         should.not.exist(err)
                         should.exist(cbtask)
                         cbtask.should.have.property('grid')
                         cbtask.grid.should.have.property('i_cell',100)
                         cbtask.grid.should.have.property('j_cell',263)
                         done()
                     })
       })
})
