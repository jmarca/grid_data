/*global require process exports */
var fs = require('fs');

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

exports.check_file =  check_file
