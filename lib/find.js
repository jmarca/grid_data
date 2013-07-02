/*global require process exports */

/**
 * July 2013, looking at this, it seems interesting and seems like I
 * was thinking of something but never finished it.  But anyway, the
 * copy_to_couchdb program does the same thing.
 */
var async = require('async');
var check_file=require('./check_file')
var read_file=require('./read_file')
var compute_aadt=require('calvad_compute_aadt')
var grab_geom=require('./grab_geom')
var couch_file=require('./couch_file')

function find(options){
    var root =  options.root || process.cwd();
    var subdir = options.subdir;
    //couchdb
    var chost = options.chost ? options.chost : '127.0.0.1';
    var cuser = options.cusername ? options.cusername : 'myname';
    var cpass = options.cpassword ? options.cpassword : 'secret';
    var cport = options.cport ? options.cport :  5984;

    if(root === undefined) root =  process.cwd();
    if(subdir === undefined) subdir = 'data';


    function file_worker(task,done){
        if(task.options === undefined )task.options = options
        async.waterfall([check_file(task)
                        ,read_file
                        ,compute_aadt
                        ,grab_geom
                        ,couch_file
                        ]
                       ,done)
    }
    return file_worker
}

exports=module.exports=find