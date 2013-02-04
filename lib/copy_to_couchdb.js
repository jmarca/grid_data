/**
 * This program will copy all of the files that I cached for grid and
 * put them in couchdb
 *
 */


var fs = require('fs');
var http = require('http');
var _ = require('underscore');
var async = require('async');

var i_min = 91
var i_max = 316
var j_min = 21
var j_max = 279

var  time_aggregation='hourly'

var years=['2007','2008','2009'];

var file_combinations = [];

function find(options){
    var root =  options.root || process.cwd();
    var subdir = options.subdir;

    if(root === undefined) root =  process.cwd();
    if(subdir === undefined) subdir = 'data';

    function file_worker(task,done){
        async.waterfall([check_file(task)
                        ,read_file
                        ,compute_aadt
                        ,couch_file
                        ]
                       ,done)
    }

    /**
     * check_file(task)
     *
     * check if a file exists
     *
     * actually returns a function that takes 'callback' as its
     * argument, so that you can use it as the first step in
     * async.waterfall
     *
     * task is a hash, must hold an element 'file' containing the
     * filename
     *
     * returns (null,task) if the file is found,
     * returns (task) (an error condition) if the file is not found
     *
     * The idea is to use it in async.waterfall, so that the waterfall
     * is aborted if the file is not there, and continues if it does
     */
    function check_file(task){
        return function(callback){
            fs.stat(task.file,function(err,stats){
                if(err){
                    //console.log('not there yet, nothing to do')
                    callback(task)
                }else{
                    //console.log('file there, pass it along');
                    callback(null,task)
                }
            })
            return null
        }
    }
    /**
     * read_file(task,callback)
     *
     * read the file, save it in task
     *
     * task is a hash, must hold an element 'file' containing the
     * filename
     *
     * callback is a callback, which expects (error,task)
     *
     * returns (null,task) if the file is found, task.data will hold
     * the (parsed JSON) contents of the file
     *
     * returns (task) (an error condition) if there is a problem
     * reading the file, and task.error will hold the error condition
     *
     */
    function read_file(task,callback){
        fs.readFile(task.file
                   ,function(err,text){
                        if(err){
                            task.error=err
                            return callback(task)
                        }
                        // parse the file as JSON, pass along
                        task.data = JSON.parse(text)
                        return callback(null,task)

                    })
        return null
    }

    /**
     * compute_aadt
     *
     * compute the average annual daily traffic based on hourly contents
     * for all vehicle categories
     *
     * task is a hash, task.data holds the parsed JSON hourly data from the file
     * callback is the waterfall callback, expects error, task
     *
     * returns (task) if there is an error, task.error holds error condition
     *
     * returns(null,task) if there isn't a problem, task.aadt has the
     * computed aadt for each vehicle type
     */
    function compute_aadt(task,callback){
        // header is an array of column names
        var header = task.data.features.properties.header
        // data is an array of arrays,
        var data = task.data.features.properties.data

        // iterate over the hours.
        // count up the days
        // add up the hourly volumes for n,heavyheavy,not_heavyheavy
        // divide volumes by number of days to get AADT
        //

        // want to keep track of freeways here, and also compute the
        // total aadt for the grid.
        //
        // the per-freeway AADT is useless, but perhaps a way to check
        // if my underlying assumption that the hourly vol/aadt is a
        // common characteristic of the grid.

        // need to check if data is arrays by freeway, or just lumped data

        var grouper = function(header){
            var unmapper = {}
            _.each(header
                  ,function(v,i){
                       unmapper[v]=i
                   })

            return function(element,index){
                // group by time, this is hourly, so do it
                return element[unmapper.ts]
            }
        }
        // group, ignoring the freeways
        var intermediate = _.groupBy(_.flatten(data),grouper)

        // so intermediate holds groups by hours.  now just have to
        // sum up by hour, sum everything, and divide the two.  Oh and
        // sum the days too.  hmm.


    }
}
