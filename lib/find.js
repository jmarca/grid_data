/*global require process exports */
var async = require('async');
var check_file=require('./check_file')
var read_file=require('./read_file')
var compute_aadt=require('./compute_aadt')
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