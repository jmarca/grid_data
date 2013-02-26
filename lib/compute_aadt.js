/*global require process exports */

var _ = require('lodash')

function pad(n){return n<10 ? '0'+n : n}
function day_formatter(d){
    return [d.getFullYear()
           , pad(d.getMonth()+1)
           , pad(d.getDate())]
        .join('-')
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
    // going to compute this:


    function  calcaadt(value,key){

        // value is a list of elements
        // key is freeway or whatever

        var sum_variables = ['n','hh','not_hh']
        // start is the starting point for the map summing function
        var start=[0,0,0] // zero volume at start of summation
        var days={}

        // make two passes max.  first pass computes aadt.  then check
        // that all intervals put out less than aadt.  if not, drop
        // those periods, and recompute aadt in second pass
        function sum_aadt(memo,rec){
            // simple sums of volumes, ignore the rest
            _.each(sum_variables
                  ,function(v,i){
                       memo[i]+=rec[unmapper[v]]
                   });
            var d = new Date(rec[unmapper['ts']])
            var day = day_formatter(d)
            if(days[day]===undefined){
                days[day]=1
            }
            return memo
        }
        var end = _.reduce(data,sum_aadt,start)
        // have the sum of volumes.  Divide by days to get average annual daily
        var numdays=_.size(days)
        end =  _.map(end
                    ,function(value,veh_type){
                         return value / numdays
                     });
        var filtered = _.filter(data
                               ,function(rec){
                                    return rec[unmapper['n']]/end[0] < 1
                                })
        if(filtered.length < data.length){
            console.log('redo aadt computation')
            console.log(end)
            // if this is true, we have outliers, and must prune them.
            task.flatdata=filtered
            // reset reduce
            start=[0,0,0] // zero volume at start of summation
            days={}
            // redo reduce
            end = _.reduce(filtered,sum_aadt,start)
            numdays=_.size(days)
            end =  _.map(end
                        ,function(value,veh_type){
                             return value / numdays
                         });
            console.log(end)
            // okay, the worst outliers just got dropped.  Not
            // perfect, but better
        }
        task.aadt[key]={}
        _.each(end
              ,function(value,veh_type){
                   task.aadt[key][sum_variables[veh_type]] = value
               });
        return null
    }

    task.aadt = {}

    // header is an array of column names
    var header = task.data.features[0].properties.header
    // data is an array of arrays,
    // features is possibly an array
    // combine things
    var data = []
    _.each(task.data.features
          ,function(feature){
               data.push(feature.properties.data)
           });
        data = _.flatten(data,true)
    task.flatdata = data
    var unmapper = {}
    _.each(header
          ,function(value,idx){
               unmapper[value]=idx
           });

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

    // a function to group records by year.  Aren't they all one year
    var fwygrouper = function(element,index){
        return element[unmapper['freeway']]
    }

    var intermediate = _.groupBy(data,fwygrouper)

    // so intermediate holds groups.  now just have to
    // sum up and divide by days to get aadt per freeway
    _.each(intermediate
          ,calcaadt);

    return callback(null,task)

}
exports.compute_aadt=compute_aadt
