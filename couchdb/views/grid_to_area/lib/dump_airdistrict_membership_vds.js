module.exports = function(doc){
    if(doc.geom_id !== undefined && doc.aadt_frac !== undefined){
        var lookup = require('views/lib/cellmembership').lookup
        if(lookup[doc.geom_id] !== undefined){
            var ts_match = /(\d*)-0?(\d*)-0?(\d*)/.exec(doc.data[0])
            var n = doc.aadt_frac.n
            var hh = doc.aadt_frac.hh
            var nhh = doc.aadt_frac.not_hh
            if(!n){
                n=0
            }
            if(!hh){
                hh=0
            }
            if(!nhh){
                nhh=0
            }
            emit([lookup[doc.geom_id].airdistrict,+ts_match[1],doc.geom_id,+ts_match[2],+ts_match[3]],[n,hh,nhh])
        }
    }
    return null
}
