module.exports = function(doc){
    if(doc.geom_id !== undefined && doc.aadt_frac !== undefined){
        var lookup = require('views/lib/cellmembership').lookup
        if(lookup[doc.geom_id] === undefined){
            var ts_match = /(\d*)-0?(\d*)-0?(\d*)/.exec(doc.data[0])
            emit([doc.geom_id,+ts_match[1],+ts_match[2],+ts_match[3]],1)
        }
    }
    return null
}
