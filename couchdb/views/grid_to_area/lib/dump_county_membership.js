module.exports = function(doc){
    if(doc.geom_id !== undefined && doc.aadt_frac !== undefined){
        var lookup = require('views/lib/cellmembership').lookup
        var ts_match = /(\d*)-0?(\d*)-0?(\d*)/.exec(doc.ts)

        emit([lookup[doc.geom_id].county,+ts_match[1],doc.geom_id,+ts_match[2],+ts_match[3]],[doc.aadt_frac.n,doc.aadt_frac.hh,doc.aadt_frac.nhh])
    }
    return null
}
