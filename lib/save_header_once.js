var request = require('request')
var queue = require('d3-queue').queue

var once = true
function save_header_once(task,done){
    if(once){
        once = false
        console.log('saving header')
        var options = task.options
        //couchdb
        var chost = options.couchdb.host
        var cport = options.couchdb.port
        var cdb   = options.couchdb.db || ['carb','grid','state4k'].join('%2f')
        var couch = 'http://'+chost+':'+cport+'/'+cdb
        var header = task.header ||
                task.data.features[0].header ||
                task.data.features[0].properties.header
        // first make sure that the header file exists
        var unmapper = {}
        header.forEach(function(value,idx){
            unmapper[value]=idx
            return null
        })
        var putbody={'_id':'header'
                    ,'header':header
                    ,'unmapper':unmapper}
        var uri =  couch +'/header'
        var q = queue(1)
        var cdb_options = {
            'url':uri,
            'method':'PUT',
            'json':true
        }
        if(options.couchdb.auth){
            cdb_options.auth ={'username':options.couchdb.auth.username
                               ,'password':options.couchdb.auth.password
                              }
        }
        cdb_options.body = putbody
        request(cdb_options,function(e,r,b){
            if(e){
                console.log(e)
                throw new Error(e)
            }
            return done()
        })
        return null
    }
    return null
}

module.exports=save_header_once
