package;

import haxe.io.UInt8Array;
import pako.Deflate;
import pako.Inflate;


class Helpers
{
  // Load fixtures to test
  // return: { 'filename1': content1, 'filename2': content2, ...}
  //
  static public function loadSamples(subdir) {
    var result = {};
    /*var dir = path.join(__dirname, 'fixtures', subdir || 'samples');

    fs.readdirSync(dir).sort().forEach(function (sample) {
      var filepath = path.join(dir, sample),
          extname  = path.extname(filepath),
          basename = path.basename(filepath, extname),
          content  = new Uint8Array(fs.readFileSync(filepath));

      if (basename[0] === '_') { return; } // skip files with name, started with dash

      result[basename] = content;
    });

    return result;*/
  }


  // Compare 2 buffers (can be Array, Uint8Array, Buffer).
  //
  static public function cmpBuf(a:UInt8Array, b:UInt8Array) {
    if (a.length != b.length) {
      return false;
    }

    for (i in 0...a.length) {
      if (a[i] != b[i]) {
        //console.log('pos: ' +i+ ' - ' + a[i].toString(16) + '/' + b[i].toString(16));
        return false;
      }
    }

    return true;
  }


  // Helper to test deflate/inflate with different options.
  // Use zlib streams, because it's the only way to define options.
  //
  /*static public function testSingle(zlib_factory, pako_deflate, data, options, callback) {

    var zlib_options = _.clone(options);

    // hack for testing negative windowBits
    if (zlib_options.windowBits < 0) { zlib_options.windowBits = -zlib_options.windowBits; }

    var zlibStream = zlib_factory(zlib_options);
    var buffers = [], nread = 0;


    zlibStream.on('error', function(err) {
      zlibStream.removeAllListeners();
      zlibStream=null;
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

      if (!cmpBuf(buffer, pako_result)) {
        callback(new Error('zlib result != pako result'));
        return;
      }

      callback(null);
    });


    zlibStream.write(new Buffer(data));
    zlibStream.end();
  }

  function testSamples(zlib_factory, pako_deflate, samples, options, callback) {
    var queue = [];

    _.forEach(samples, function(data, name) {
      // with untyped arrays
      queue.push(function (done) {
        pako_utils.setTyped(false);

        testSingle(zlib_factory, pako_deflate, data, options, function (err) {
          if (err) {
            done('Error in "' + name + '" - zlib result != pako result');
            return;
          }
          done();
        });
      });

      // with typed arrays
      queue.push(function (done) {
        pako_utils.setTyped(true);

        testSingle(zlib_factory, pako_deflate, data, options, function (err) {
          if (err) {
            done('Error in "' + name + '" - zlib result != pako result');
            return;
          }
          done();
        });
      });
    });

    async.series(queue, callback);
  }*/


    static public function testInflate(samples:Map<String, UInt8Array>, inflateOptions:InflateOptions, deflateOptions:DeflateOptions, callback:String->Void) {
    var name, data, deflated, inflated;

    // inflate options have windowBits = 0 to force autodetect window size
    //
    for (name in samples.keys()) {
      data = samples[name];

      // always use the same data type to generate sample
      //pako_utils.setTyped(true);
      deflated = Deflate.deflate(data, deflateOptions);

      // with untyped arrays
      //pako_utils.setTyped(false);
      inflated = Inflate.inflate(deflated, inflateOptions);
      //pako_utils.setTyped(true);

      if (!cmpBuf(inflated, data)) {
        callback('Error in "' + name + '" - inflate result != original');
        return;
      }

      // with typed arrays
      inflated = Inflate.inflate(deflated, inflateOptions);

      if (!cmpBuf(inflated, data)) {
        callback('Error in "' + name + '" - inflate result != original');
        return;
      }
    }

    callback("");
  }
}