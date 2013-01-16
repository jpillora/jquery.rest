var fs = require('fs'),
    _;

/*global module:false*/
module.exports = function(grunt) {


  // Project configuration.
  grunt.initConfig({

    pkg: '<json:component.json>',
    meta: {
      banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
        '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
        '<%= pkg.homepage ? "* " + pkg.homepage + "\n" : "" %>' +
        '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
        ' Licensed <%= pkg.license %> */',
      header:
        '(function() {',
      footer:
        '}());'
    },
    coffee: {
      compile: {
        files: {
          'compile/<%= pkg.name %>.js': 'src/<%= pkg.name %>.coffee'
        }
      }
    },
    concat: {
      dist: {
        src: ['<banner:meta.banner>', '<file_strip_banner:compile/<%= pkg.name %>.js>'],
        dest: 'dist/<%= pkg.name %>.js'
      }
    },
    lint: {
      files: ['grunt.js', 'src/**/*.js', 'test/**/*.js']
    },
    min: {
      dist: {
        src: ['<banner:meta.banner>', 'dist/<%= pkg.name %>.js'],
        dest: 'dist/<%= pkg.name %>.min.js'
      }
    },

    watch: {
      scripts: {
        files: 'src/**/*.coffee',
        tasks: 'default',
        options: {
          debounceDelay: 1000
        }
      }
    },
    jshint: {
      options: {
        eqeqeq: true,
        immed: true,
        latedef: true,
        newcap: true,
        noarg: true,
        sub: true,
        undef: true,
        boss: true,
        eqnull: true,
        browser: true
      },
      globals: {
        require: true,
        jQuery: true,
        "$": true
      }
    }
  });

  // Plugins
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-mocha');



  // Default task.
  grunt.registerTask('default', 'coffee concat lint min');
  grunt.renameTask('watch', 'real-watch');
  grunt.registerTask('watch', 'default real-watch');

};
