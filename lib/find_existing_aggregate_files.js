var glob = require('glob')

function find_files(opts,cb){
    // have path, read it, process all the files
    var pattern = '**/*[0123456789].json'
    console.log(opts.path)
    glob(pattern,{cwd:opts.path,dot:true,follow:true,realpath:true},function(e,list){
        if(e) console.log('error',e)
        return cb(e,list)
    })
    return null
}

module.exports = find_files
