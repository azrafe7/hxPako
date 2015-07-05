package;

import haxe.io.Path;
import haxe.io.UInt8Array;
import haxe.Resource;
import pako.zlib.Adler32;
import pako.zlib.Constants;
import pako.zlib.CRC32;
import pako.zlib.Messages;
import pako.zlib.ZStream;
import pako.zlib.GZHeader;
import pako.zlib.InfTrees;
import pako.zlib.Trees;
import pako.zlib.Deflate;
import pako.zlib.InfFast;
import pako.zlib.Inflate;
import pako.Deflate;
import pako.Inflate;
import pako.utils.Common;
#if sys
import sys.io.File;
#end
import buddy.*;
import utest.Assert;
import Helpers;

using buddy.Should;


class Main implements Buddy<[Misc, Chunks]> { }

class Misc extends BuddySuite {
    public function new() {
      
      describe('ArrayBuffer', {

        var file   = Path.join(["./", 'fixtures/samples/lorem_utf_100k.txt']);
      
      #if sys
        var bytes = File.getBytes(file);
      #else
        var bytes = Resource.getBytes('lorem_utf_100k.txt');
      #end
        
        trace(bytes.length);
      
        var sample = UInt8Array.fromBytes(bytes);
        trace(bytes.length, sample.length);
        var deflated = Deflate.deflate(sample);

        it('Deflate ArrayBuffer', {
          Assert.isTrue(Helpers.cmpBuf(deflated, Deflate.deflate(sample)));
        });

        it('Inflate ArrayBuffer', {
          Assert.isTrue(Helpers.cmpBuf(sample, Inflate.inflate(deflated)));
        });
      });
    }
}

class Chunks extends BuddySuite {
  public function new() {
    
    describe('Small input chunks', {

      it('deflate 100b by 1b chunk', {
        var buf = randomBuf(100);
        var deflated = Deflate.deflate(buf);
        testChunk(buf, deflated, new pako.Deflate(), 1);
      });

      it('deflate 20000b by 10b chunk', {
        var buf = randomBuf(20000);
        var deflated = Deflate.deflate(buf);
        testChunk(buf, deflated, new pako.Deflate(), 10);
      });

      it('inflate 100b result by 1b chunk', {
        var buf = randomBuf(100);
        var deflated = Deflate.deflate(buf);
        testChunk(deflated, buf, new pako.Inflate(), 1);
      });

      it('inflate 20000b result by 10b chunk', {
        var buf = randomBuf(20000);
        var deflated = Deflate.deflate(buf);
        testChunk(deflated, buf, new pako.Inflate(), 10);
      });

    });


    describe('Dummy push (force end)', {

      var file   = Path.join(["./", 'fixtures/samples/lorem_utf_100k.txt']);
      
      #if sys
        var bytes = File.getBytes(file);
      #else
        var bytes = Resource.getBytes('lorem_utf_100k.txt');
      #end

      it('deflate end', {
        var data = UInt8Array.fromBytes(bytes);

        var deflator = new pako.Deflate();
        deflator.push(data);
        deflator.push(new UInt8Array(0), true);

        Assert.isTrue(Helpers.cmpBuf(deflator.result, Deflate.deflate(data)));
      });

      it('inflate end', {
        var data = Deflate.deflate(UInt8Array.fromBytes(bytes));

        var inflator = new pako.Inflate();
        inflator.push(data);
        inflator.push(new UInt8Array(0), true);

        Assert.isTrue(Helpers.cmpBuf(inflator.result, Inflate.inflate(data)));
      });

    });


    describe('Edge condition', {

      it('should be ok on buffer border', {
        var i;
        var data = new UInt8Array(1024 * 16 + 1);

        for (i in 0...data.length) {
          data[i] = Math.floor(Math.random() * 255.999);
        }

        var deflated = Deflate.deflate(data);
        trace(deflated.length);

        var inflator = new Inflate();

        //NOTE(hx): there was an error in pako.js which copied out of bounds (deflated[length])
        for (i in 0...deflated.length) {
          if (i == 16395) {
            var x = i;
            trace(i + " " + inflator.err);
          }
          inflator.push(deflated.subarray(i, i+1), false);
          Assert.isTrue(inflator.err == ErrorStatus.Z_OK, 'Inflate failed with status ' + inflator.err);
        }

        inflator.push(new UInt8Array(0), true);

        Assert.isTrue(inflator.err == ErrorStatus.Z_OK, 'Inflate failed with status ' + inflator.err);
        trace(data == null);
        trace(inflator.result == null);
        Assert.isTrue(Helpers.cmpBuf(data, inflator.result));
      });

    });
  }
  
  function randomBuf(size) {
    var buf = new UInt8Array(size);
    for (i in 0...size) {
      buf[i] = Math.round(Math.random() * 256);
    }
    return buf;
  }

  function testChunk(buf:UInt8Array, expected, packer:Dynamic, chunkSize) {
    var i, _in, count, pos, size, expFlushCount;

    var onData = @:privateAccess packer._onData;
    var flushCount = 0;

    packer.onData = function(buffer) {
      flushCount++;
      onData(buffer);
    };

    count = Math.ceil(buf.length / chunkSize);
    pos = 0;
    for (i in 0...count) {
      size = (buf.length - pos) < chunkSize ? buf.length - pos : chunkSize;
      _in = new UInt8Array(size);
      Common.arraySet(cast _in, cast buf, pos, size, 0);
      var mode:Bool = i == count - 1;
      packer.push(_in, mode);
      pos += chunkSize;
    }

    //expected count of onData calls. 16384 output chunk size
    expFlushCount = Math.ceil(packer.result.byteLength / 16384);

    Assert.isTrue(packer.err == ErrorStatus.Z_OK, 'Packer error: ' + packer.err);
    Assert.isTrue(Helpers.cmpBuf(packer.result, expected), 'Result is different');
    Assert.equals(flushCount, expFlushCount, 'onData called ' + flushCount + 'times, expected: ' + expFlushCount);
  }

}