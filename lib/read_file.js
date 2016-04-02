/*global require process exports JSON */

var fs = require('fs')

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
                    var data = JSON.parse(text)
                    if(data.features === undefined || data.features.length === 0 ) return callback(task)
                    task.data = data
                    return callback(null,task)

                })
    return null
}
exports.read_file=read_file
