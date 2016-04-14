/* global require console process it describe after before */

var should = require('should')

var grab_geom = require('../lib/grab_geom').grab_geom
var fs = require('fs')

var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = rootdir+'/../test.config.json'
var config_okay = require('config_okay')
var config={}
before(function(done){
    config_okay(config_file,function(err,c){
        if(err){
            console.log('Problem trying to parse options in ',config_file)
            throw new Error(err)
        }
        config = c

        return done()
    })
})

describe('grab_geom',function(){
    it('should get the right grid cell geometry, given a grid file name'
      ,function(done){
           var task={file:'./test/files/monthly/2009/100/263.json'
                    ,options:config}
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
