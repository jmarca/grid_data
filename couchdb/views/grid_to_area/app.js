var couchapp = require('couchapp')
var cellmembership = require('./lib/cellmembership.json')
var county = require('./lib/dump_county_membership')
var airbasin = require('./lib/dump_airbasin_membership')
var airdistrict = require('./lib/dump_airdistrict_membership')

var ddoc = {
    _id: '_design/calvad',
    rewrites: [{
      from: '',
      to: 'index.html',
      method: 'GET',
      query: {}
    },{
      from: '/*',
      to: '/*'
    }],
    views: {
        "lib":{
            "cellmembership":"exports.lookup="+JSON.stringify(cellmembership)
        }
      ,"county":{
          "map":county,
          "reduce":"_sum"
      }
      ,"airdistrict":{
          "map":airdistrict,
          "reduce":"_sum"
      }
      ,"airbasin":{
          "map":airbasin,
          "reduce":"_sum"
      }
    },
    lists: {},
    shows: {}
};


module.exports = ddoc;