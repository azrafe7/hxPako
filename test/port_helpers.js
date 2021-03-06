'use strict';


var fs    = require('fs');
var path  = require('path');
var _     = require('lodash');
var async = require('async');

var pako_utils = require('../lib/utils/common');
var pako  = require('../index');

//NOTE: whether to generate files in zlib_output folder 
//     (remember to add the generated files to resources when testing from haxe)
var GEN_ZLIB_OUTPUT = true;

console.info('\nport_helpers.js: GEN_ZLIB_OUTPUT(' + GEN_ZLIB_OUTPUT + ')');

function writeToFile(buffer, name) {
	var filename = path.join(__dirname, 'fixtures/zlib_output/' + name);
	//console.log(filename + "  (" + buffer.length + ")");
	fs.writeFileSync(filename, buffer);
}

// Load fixtures to test
// return: { 'filename1': content1, 'filename2': content2, ...}
//
function loadSamples(subdir) {
  var result = {};
  var dir = path.join(__dirname, 'fixtures', subdir || 'samples');

  fs.readdirSync(dir).sort().forEach(function (sample) {
    var filepath = path.join(dir, sample),
        extname  = path.extname(filepath),
        basename = path.basename(filepath, extname),
        content  = new Uint8Array(fs.readFileSync(filepath));

    if (basename[0] === '_') { return; } // skip files with name, started with dash

    result[basename] = content;
  });

  return result;
}


// Compare 2 buffers (can be Array, Uint8Array, Buffer).
//
function cmpBuf(a, b) {
  if (a.length !== b.length) {
    return false;
  }

  for (var i=0, l=a.length; i<l; i++) {
    if (a[i] !== b[i]) {
      //console.log('pos: ' +i+ ' - ' + a[i].toString(16) + '/' + b[i].toString(16));
      return false;
    }
  }

  return true;
}


// Helper to test deflate/inflate with different options.
// Use zlib streams, because it's the only way to define options.
//
function testSingle(zlib_factory, pako_deflate, data, options, callback, name) {

  var zlib_options = _.clone(options);

  // hack for testing negative windowBits
  if (zlib_options.windowBits < 0) { zlib_options.windowBits = -zlib_options.windowBits; }

  var zlibStream = zlib_factory(zlib_options);
  var buffers = [], nread = 0;


  zlibStream.on('error', function(err) {
    zlibStream.removeAllListeners();
    zlibStream=null;
    console.log("zlib err");
	callback(err);
  });

  zlibStream.on('data', function(chunk) {
    buffers.push(chunk);
    nread += chunk.length;
  });

  zlibStream.on('end', function() {
    zlibStream.removeAllListeners();
    zlibStream=null;

    var buffer = Buffer.concat(buffers);

    var pako_result = pako_deflate(data, options);

    // One more hack: gzip header contains OS code, that can vary.
    // Override OS code if requested. For simplicity, we assume it on fixed
    // position (= no additional gzip headers used)
    if (options.ignore_os) {
      buffer[9] = pako_result[9];
    }
    
    if (name && GEN_ZLIB_OUTPUT) {
		writeToFile(buffer, name);
		//console.log(options);
	}
	
	if (!cmpBuf(buffer, pako_result)) {
      callback(new Error('zlib result != pako result'));
      return;
    }

    callback(null);
  });


  zlibStream.write(new Buffer(data));
  zlibStream.end();
}

function testSamples(zlib_factory, pako_deflate, samples, options, callback, prefix) {
  var queue = [];

  _.forEach(samples, function(data, name) {
    // with untyped arrays
    /*queue.push(function (done) {
      pako_utils.setTyped(false);

      testSingle(zlib_factory, pako_deflate, data, options, function (err) {
        if (err) {
          done('Error in "' + name + '" - zlib result != pako result');
          return;
        }
        done();
      });
    });*/

    // with typed arrays
    queue.push(function (done) {
      pako_utils.setTyped(true);

      testSingle(zlib_factory, pako_deflate, data, options, function (err) {
        if (err) {
          done('Error in "' + name + '" - zlib result != pako result');
          return;
        }
        done();
      }, prefix + "-" + name);
    });
  });

  async.series(queue, callback);
}


function testInflate(samples, inflateOptions, deflateOptions, callback) {
  var name, data, deflated, inflated;

  // inflate options have windowBits = 0 to force autodetect window size
  //
  for (name in samples) {
    data = samples[name];

    // always use the same data type to generate sample
    pako_utils.setTyped(true);
    deflated = pako.deflate(data, deflateOptions);

    // with untyped arrays
    pako_utils.setTyped(false);
    inflated = pako.inflate(deflated, inflateOptions);
    pako_utils.setTyped(true);

    if (!cmpBuf(inflated, data)) {
      callback('Error in "' + name + '" - inflate result != original');
      return;
    }

    // with typed arrays
    inflated = pako.inflate(deflated, inflateOptions);

    if (!cmpBuf(inflated, data)) {
      callback('Error in "' + name + '" - inflate result != original');
      return;
    }
  }

  callback();
}


exports.toType = function(obj) {
  return ({}).toString.call(obj).match(/\s([^\]]+)/)[1].toLowerCase();
}
exports.cmpBuf = cmpBuf;
exports.testSamples = testSamples;
exports.testInflate = testInflate;
exports.loadSamples = loadSamples;
