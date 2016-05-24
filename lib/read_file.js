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
    console.log('reading',task.file)
    fs.readFile(task.file
                ,function(err,text){
                    //console.log(task.file,'error is',err)
                   if(err){
                       console.log(err)
                       throw new Error(err)
                        task.error=err
                        return callback(task)
                    }
                    // parse the file as JSON, pass along
                    var data = JSON.parse(text)
                    if(data.features === undefined ||
                       data.features[0] === undefined ||
                       data.features[0].properties === undefined){
                        task.data ={'features':[{'properties':{'data':[]}}]}
                    }
                    task.data = data
                    return callback(null,task)

                })
    return null
}
exports.read_file=read_file
