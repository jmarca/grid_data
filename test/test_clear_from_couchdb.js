/* global require console process it describe after before */

var should = require('should')

var queue = require('d3-queue').queue

var fs = require('fs')

var clear_grid = require('../lib/clear_grid_from_couchdb.js')
var request = require('request')

var path    = require('path')
var rootdir = path.normalize(__dirname)
var config_file = rootdir+'/../test.config.json'
var config_okay = require('config_okay')
var config={}

var utils=require('./utils.js')

var testdb ='test%2fcarb%2fgrid%2fstate4k_blablahblah'
var docs = {'docs':[{'_id':'118_192_2012-01-01 02:00'
                    ,foo:'bar'}
                   ,{'_id':'118_192_2012-01-01 03:00'
                    ,foo:'baz'}
                   ,{'_id':'118_192_2012-01-01 04:00'
                    ,foo:'bat'}
                   ,{'_id':'118_192_2012-01-01 05:00'
                    ,foo:'bah'}
                   ]
           }

before(function(done){
    config_okay(config_file,function(err,c){
        if(err){
            console.log('Problem trying to parse options in ',config_file)
            throw new Error(err)
        }
        config.couchdb = Object.assign({},c.couchdb)
        config.couchdb.db = testdb
        utils.create_tempdb(config,function(e,r){
            // put docs to be cleared
            var cdb = config.couchdb.host+':'
                    + config.couchdb.port + '/'
                    + config.couchdb.db
            if(!/^http/.test(cdb)){
                cdb = 'http://'+cdb
            }
            var opts ={}
            opts.method='POST'
            opts.json=docs
            opts.uri = cdb+ '/_bulk_docs'
            request(opts,function(e,r,b){
                if(e) {
                    console.log(e)
                    return done(e)
                }
                return done()
            })
            return null
        })
        return null
    })
    return null
})

after(function(done){
    // uncomment to bail in development
    // return done()
    utils.delete_tempdb(config,done)
    return null
})

describe('can set delete on docs',function(){

    it('delete everything from 2012'
       ,function(done){

           var task={'file':__dirname+'/files/hourly/2012/118/192.json'
                     ,'options':{
                         'couchdb':config.couchdb
                     }
                     ,'year':2012
                     ,'i':118
                     ,'j':192
                    }

           clear_grid(task,function(e,r){
               var cdb = config.couchdb.host+':'
                       + config.couchdb.port + '/'
                       + config.couchdb.db
               if(!/^http/.test(cdb)){
                   cdb = 'http://'+cdb
               }
               // console.log(cdb)
               should.exist(e)
               e.message.should.eql('no data')
               return request.get(cdb+'/_all_docs?include_docs=true'
                              ,function(e,r,b){
                                   if(e) return done(e)
                                   var c=JSON.parse(b)
                                   c.should.have.property('total_rows',0)
                                   return done()
                               })

           })
           return null
       })
    return null
})
