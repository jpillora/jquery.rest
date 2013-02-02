mocha.setup('bdd');

afterEach(function() {
$("#konacha").empty();
});

var initScripts = {};

var expect = chai.expect;
var should = chai.should();

var assert = function(expr, msg) {
  if (!expr) throw new Error(msg || 'failed');
};

$(function() {

  "use strict";

  //define test names

  var tests = null, testsLoaded = 0;

  $.getJSON('specs.json', function(tests) {
    $.each(tests, runTest);
  });

  function runTest(i,url) {
    $.ajax({ 
      type:'GET', 
      url: url,
      success: function(result) {
        evalResult(result, url);
      }
    });
  }

  function evalResult(result, url) {

    console.log("Loaded test: " + url);
    var ext = url.substr(url.lastIndexOf('.')+1);

    switch(ext) {
      case "coffee":
        try {
          CoffeeScript.eval(result);
        } catch(e) {
          console.error(e);
          return;
        } 
        break;
      case "js":
        try {
          eval(result);
        } catch(e) {
          console.error(e);
          return;
        }
        break;
      case "html":
        $('body').append(result);
        break;
      default:
        console.warn("Unsupported file: " + url);
    }

    if((++testsLoaded) === tests.length)
    setTimeout( function() {
      mocha.run();
    },500);

  }

});//$ on ready