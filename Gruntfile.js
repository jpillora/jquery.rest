var fs = require('fs');

/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({

    pkg: require('./component.json'),
    meta: {
      banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
        '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
        ' * <%= pkg.homepage %>\n' +
        ' * Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
        ' Licensed <%= pkg.license %> */\n'
    },
    coffee: {
      dist: {
        files: {
         'dist/<%= pkg.name %>.js': 'src/<%= pkg.name %>.coffee'
        }
      }
    },
    concat: {
      options: {
        banner: '<%= meta.banner %>'
      },
      dist: {
        files:{
          'dist/<%= pkg.name %>.js': ['dist/<%= pkg.name %>.js']
        }
      }
    },
    uglify: {
      dist: {
        options: {
          banner: '<%= meta.banner %>',
          report: 'gzip',
          compress: true
        },
        files: {
          'dist/<%= pkg.name %>.min.js': ['dist/<%= pkg.name %>.js']
        }
      }
    },
    watch: {
      scripts: {
        files: 'src/*.coffee',
        tasks: 'default'
      }
    }
  });

  // Plugins
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-concat');

  // Default task.
  grunt.registerTask('default', ['coffee','concat','uglify']);

};
