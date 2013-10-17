// Generated on 2013-10-15 using generator-reveal 0.0.14
'use strict';

var path = require('path');
var config = require('./config.json');

module.exports = function (grunt) {
    // load all grunt tasks
    require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

    grunt.initConfig({
        jshint: {
            all: ['app.js', 'lib/**/*.js'],
            options: {
                curly: true,
                eqeqeq: true,
                immed: true,
                latedef: true,
                newcap: true,
                noarg: true,
                sub: true,
                undef: true,
                boss: true,
                eqnull: true,
                node: true,
                asi: true,
                laxcomma: true,
                couch: true
            }
        },
        mkcouchdb: {
            app: {
                db: [config.couchapp.root, config.couchapp.db].join('/'),
                auth: config.couchapp.auth,
                options: {
                    okay_if_exists: true
                }
            }
        },
        couchapp: {
            app: {
                db: [config.couchapp.root, config.couchapp.db].join('/'),
                auth: config.couchapp.auth,
                app: config.couchapp.app
            }
        }
    });

    grunt.registerTask('default', ['jshint', 'mkcouchdb', 'couchapp'])
};
