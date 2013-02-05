/*global require process exports */
/**
 * This program will copy all of the files that I cached for grid and
 * put them in couchdb
 *
 */


var http = require('http');
var _ = require('underscore');
var async = require('async');
var pg = require('pg');

var i_min = 91
var i_max = 316
var j_min = 21
var j_max = 279

var  time_aggregation='hourly'

var years=['2007','2008','2009'];

var file_combinations = [];
