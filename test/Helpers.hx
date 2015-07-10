package;

import haxe.io.ArrayBufferView;
import haxe.io.UInt8Array;
import haxe.Resource;
import pako.Pako;
import pako.Deflate;
import pako.Inflate;
import utest.Assert;


class Helpers
{
  // Load fixtures to test
  // return: { 'filename1': content1, 'filename2': content2, ...}
  //
  static public var samples(get, null):Map<String, UInt8Array> = null;
  static function get_samples():Map<String, UInt8Array> {
    if (samples != null) return samples;
    
    samples = new Map<String, UInt8Array>();
    for (name in Resource.listNames()) samples[name] = UInt8Array.fromBytes(Resource.getBytes(name));
    return samples;
  }
  
  static public function getSamplesWithPrefix(prefix:String = "samples/") {
    var filteredSamples = new Map<String, UInt8Array>();
    for (k in samples.keys()) if (k.indexOf(prefix) == 0) filteredSamples[k] = samples[k];
    if (!filteredSamples.keys().hasNext()) throw 'No resource prefixed with "$prefix" found.';
    return filteredSamples;
  }
  
  static public function getSample(fullname:String) {
    var sample = samples[fullname];
    if (sample == null) throw 'Resource "$fullname" not found.';
    return sample;
  }
  
  // Compare 2 buffers (can be Array, Uint8Array, Buffer).
  //
  //NOTE(hx): need to use `cast ` to work with all typed arrays
  static public function cmpBuf(a:ArrayBufferView, b:ArrayBufferView) {
    if (a.byteLength != b.byteLength) {
      return false;
    }

    for (i in 0...a.byteLength) {
      if (a.buffer.get(a.byteOffset + i) != b.buffer.get(b.byteOffset + i)) {
        return false;
      }
    }

    return true;
  }


  //NOTE(hx): zlib output has been precomputed and saved as resource, so we compare against them
  // Helper to test deflate/inflate with different options.
  // Use zlib streams, because it's the only way to define options.
  //
  static public function testSingle(zlib_factory, pako_deflate, data, options, callback, zlib_filename) {

    /*var zlib_options = _.clone(options);

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
    zlibStream.end();*/
    
    var pako_result = pako_deflate(data, options);
    var zlib_result = getSample("zlib_output/" + zlib_filename);

    if (!Helpers.cmpBuf(cast zlib_result, cast pako_result)) {
      callback(true);
      return;
    }
    
    callback(false);
  }

  static public function testSamples(zlib_factory, pako_deflate:Null<UInt8Array>->Dynamic->UInt8Array, samples:Map<String, UInt8Array>, options, callback:?Bool->Void, prefix) {

    for (k in samples.keys()) {
      var data = samples[k];
      
      // extract filename without ext
      var tmp = k.split("/").pop().split(".");
      tmp.pop();
      var name = tmp.join("");
      
      testSingle(zlib_factory, pako_deflate, data, options, function (err) {
        Assert.isFalse(err, 'Error in "' + name + '" (' + prefix + '): zlib result != pako result');
      }, prefix + "-" + name);
    }
    callback();
  }


  static public function testInflate(samples:Map<String, UInt8Array>, inflateOptions:InflateOptions, deflateOptions:DeflateOptions, callback:?Bool->Void) {
    var name, data, deflated, inflated;

    // inflate options have windowBits = 0 to force autodetect window size
    //
    for (name in samples.keys()) {
      data = samples[name];

      // always use the same data type to generate sample
      //pako_utils.setTyped(true);
      deflated = Pako.deflate(data, deflateOptions);

      // with untyped arrays
      //pako_utils.setTyped(false);
      inflated = Pako.inflate(deflated, inflateOptions);
      //pako_utils.setTyped(true);

      if (!cmpBuf(cast inflated, cast data)) {
        Assert.fail('Error in "' + name + '" - inflate result != original');
        return;
      }

      // with typed arrays
      inflated = Pako.inflate(deflated, inflateOptions);

      if (!cmpBuf(cast inflated, cast data)) {
        Assert.fail('Error in "' + name + '" - inflate result != original');
        return;
      }
    }

    callback();
  }
}