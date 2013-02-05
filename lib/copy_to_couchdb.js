/*global require process */
/**
 * This program will copy all of the files that I cached for grid and
 * put them in couchdb
 *
 */


var fs = require('fs');
var http = require('http');
var _ = require('underscore');
var async = require('async');
var pg = require('pg');
var topojson = require('topojson')
var request = require('request')

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
    //couchdb
    var chost = options.chost ? options.chost : '127.0.0.1';
    var cuser = options.cusername ? options.cusername : 'myname';
    var cpass = options.cpassword ? options.cpassword : 'secret';
    var cport = options.cport ? options.cport :  5984;

    if(root === undefined) root =  process.cwd();
    if(subdir === undefined) subdir = 'data';


    function file_worker(task,done){
        if(task.options === undefined )task.options = options
        async.waterfall([check_file(task)
                        ,read_file
                        ,compute_aadt
                        ,grab_geom
                        ,couch_file
                        ]
                       ,done)
    }
    return file_worker
}

/**
 * couch_file
 *
 * save a doc in couchdb
 *
 */
function couch_file(task,callback){

    var options = task.options
    //couchdb
    var chost = options.chost ? options.chost : '127.0.0.1'
    var cuser = options.cusername ? options.cusername : 'myname'
    var cpass = options.cpassword ? options.cpassword : 'secret'
    var cport = options.cport ? options.cport :  5984
    var cdb   = options.couch_db || ['carb','grid','state4k'].join('%2f')
    var couch = 'http://'+chost+':'+cport+'/'+cdb

    // overwrite old docs??

    // hmm, for this one, each doc is an hour.  Let's go crazy.  Then
    // the views can be null and just get the doc too, maybe save some
    // space and time creating the views

    // not so great if I have to eventually update? granularity yes
    // because per hour docs.  although that is a lot of disk i/o

    // create the per-hour docs, each gets the geometry and AADT, plus
    // the hour record

    // going to use topojson for this, and so I am going to store
    // features and geometry information separately.  features will be
    // indexed by id, and by time.  geometry information just by id.


    var header = task.data.features.properties.header
    var unmapper = {}
    _.each(header
          ,function(value,idx){
               unmapper[value]=idx
           });

    var data = task.data.features.properties.data
    var geoms = {}
    var docs = _.map(data
                    ,function(v,i){
                         var doc={}
                         var geom
                         var id=[task.geom.i_cell,task.geom.j_cell,doc[unmapper['ts']]].join('_')
                         var geom_id = [task.geom.i_cell,task.geom.j_cell].join('_')
                         doc._id=id
                         doc.geom_id=geom_id
                         if(geoms[geom_id]===undefined){
                             var geo = {type: "Feature"
                                       ,id: geom_id
                                       ,properties: _.clone(task.geom)
                                       ,geometry: task.geom.geom4326}
                             geoms[geom_id]=geo
                         }
                         doc.data=v
                     })
    // now to save both docs, and topology
    var topo = topojson.topology(geoms)
    var uri = couch +'/topology'
    var opts = {'uri':uri
               , 'method': "PUT"
               , 'body': topo
               , 'headers': {}
               };
    opts.headers.authorization = 'Basic ' + new Buffer(cuser + ':' + cpass).toString('base64')
    opts.headers['Content-Type'] =  'application/json'
    request(opts
           ,function(e,r,b){
                if(e) return callback(e)
                return null
            });
    // now bulkdocs, 1000 at a time
    opts.uri= couch +'/_bulk_docs'
    opts.method='POST'
    opts.body=[]
    async.whilst(
        function(){
            return docs !== undefined && docs.length > 0
        }
      ,function(whilst_callback){
           var chunk = docs.splice(0,1000)
           console.log(['next',chunk.length,'records,',docs.length,'remaining'].join(' '))
           opts.body = JSON.stringify({'docs':chunk})
           request(opts
                  ,function(e,r,b){
                       if(e){
                           console.log('bulk doc save error '+e)
                           return whilst_callback(e)
                       }
                       return whilst_callback()
                   });
       }
      ,function(err){
           // all done saving docs
           if(err){ throw new Error('failed saving docs to couchdb')}
           return callback(err)
       }




}

/**
 * grab_geom
 *
 * go off to postgresql and get this grid cell's geometry and other details
 *
 */
function grab_geom(task,callback){
        //psql
    var host = task.options.host ? task.options.host : '127.0.0.1';
    var user = task.options.username ? task.options.username : 'myname';
    var pass = task.options.password ? task.options.password : 'secret';
    var port = task.options.port ? task.options.port :  5432;
    var osmConnectionString        = "pg://"+user+":"+pass+"@"+host+":"+port+"/osm";

    var file = task.file
    var parts = file.split('/')
    var filename = parts.pop()
    var j = filename.split('.')[0]
    var i = parts.pop()



    var query = ['select'
                ,'fid_state4,'
                ,'cell_id,'
                ,'i_cell,'
                ,'j_cell,'
                ,'st_cell_id,'
                ,'st_i_cell,'
                ,'st_j_cell,'
                ,'fid_ca,'
                ,'state,'
                ,'st_asgeojson(geom) as geom,'
                ,'st_asgeojson(geom4326) as geom4326'
                ,'from carbgrid.state4k'
                ,'where i_cell='+i+' and j_cell='+j
                ,'limit 1'].join(' ')

    pg.connect(osmConnectionString
              ,function(err,client){
                   task.grid={}
                   var result = client.query(query);
                   result.on('row',function(row){
                       _.each(row
                             ,function(v,k){
                                  task.grid[k]=v
                              });
                       return callback(null,task)
                   });

               })
    return null

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
              ,function(value,key){
                   // value is a list of elements
                   var start=[]
                   start.push(value[0][unmapper.ts])
                   if(header.freeway !== undefined){
                       start.push(value[0][unmapper.freeway])
                   }

                   var sum_variables = ['n','hh','not_hh']

                   // the fourth summation spot is the number of days
                   start=[0,0,0]
                   var days={}
                   // start is the starting point for the map summing function
                   var end = _.reduce(data
                                     ,function(memo,rec){
                                          // simple sums of volumes, ignore the rest
                                          _.each(sum_variables
                                                ,function(v,i){
                                                     memo[i]+=rec[unmapper[v]]
                                                 });
                                          var d = new Date(rec[unmapper['ts']])
                                          var day = d.dateFormat("Y-m-d")
                                          if(days[day]===undefined){
                                              days[day]=1
                                          }
                                          return memo
                                      },start);
                   // have the sum of volumes.  Divide by days to get average annual daily
                   var numdays=_.size(days)
                   task.aadt[key]={}
                   _.each(end
                         ,function(value,veh_type){
                                   task.aadt[key][veh_type] = value / numdays
                          });
               });

    }
