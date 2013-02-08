/*global require process exports */
/**
 * This program will copy all of the files that I cached for grid and
 * put them in couchdb
 *
 */


var http = require('http');
var _ = require('underscore');
var async = require('async');
var pg = require('pg');

var i_min = 0
var i_max = 400
var j_min = 0
var j_max = 300

var  time_aggregation='hourly'

var years=['2007','2008','2009'];

var file_q = async.queue(file_worker, 100)

    function file_worker(task,done){
        
        async.waterfall([check_dir(task)
                        ,check_file
                        ,aggregate
                        ]
                       ,done)
    }
