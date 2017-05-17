package;

import haxe.io.ArrayBufferView;
import haxe.io.Bytes;
import haxe.io.Int32Array;
import haxe.io.UInt16Array;
import haxe.io.UInt32Array;
import haxe.io.UInt8Array;
import haxe.Resource;
import haxe.Timer;
import haxe.Utf8;
import pako.Pako;
import pako.zlib.Adler32;
import pako.zlib.Constants;
import pako.zlib.CRC32;
import pako.zlib.Messages;
import pako.zlib.ZStream;
import pako.zlib.GZHeader;
import pako.zlib.InfTrees;
import pako.zlib.Trees;
import pako.zlib.Deflate as ZlibDeflate;
import pako.zlib.InfFast;
import pako.zlib.Inflate as ZlibInflate;
import pako.Deflate;
import pako.Inflate;
import pako.utils.Common;
import buddy.BuddySuite;
import buddy.Buddy;
import buddy.SuitesRunner;
import utest.Assert;
import Helpers;


@reporter("MochaReporter")
class TestAll /*implements Buddy <[
    TestMisc, 
    TestChunks, 
    TestDeflate,
    TestInflate, 
    TestInflateCover, 
    TestDeflateCover,
    TestGZipSpecials,
    TestStrings,
  ]>*/ { 

  
  static var count:Int = 0;
  
#if (cpp && telemetry)
  static public var hxt:hxtelemetry.HxTelemetry;
#end  

  static public function main():Void {
    
    // workaround for openfl html5, where SuitesRunner runs twice (not sure why)
    if (++count > 1) {
      trace("Prevented running again!");
      return; 
    }
    
  #if (cpp && telemetry)
    var cfg = new hxtelemetry.HxTelemetry.Config();
    cfg.allocations = false;
    hxt = new hxtelemetry.HxTelemetry(cfg);
  #end
    
    var reporter = new MochaReporter();
  
    var runner = new SuitesRunner([
      new TestMisc(), 
      new TestChunks(), 
      new TestDeflate(),
      new TestInflate(), 
      new TestInflateCover(), 
      new TestDeflateCover(),
      new TestGZipSpecials(),
      new TestStrings(),
    ], reporter);
    
    trace("ArrayBufferView.EMULATED: " + ArrayBufferView.EMULATED);
  
  #if debug
    trace("DEBUG: true");
  #else
    trace("DEBUG: false");
  #end
  
  #if (cpp && HXCPP_PROFILER)
    trace("start profiler");
    cpp.vm.Profiler.start("profile.log");
  #end
  
    runner.run();
    
  #if (cpp && HXCPP_PROFILER)
    trace("stop profiler");
    cpp.vm.Profiler.stop();
  #end
  
  #if sys
    Sys.exit(0);
  #end
  }
}  

class TestMisc extends BuddySuite {
  public function new() {
    
    describe('ArrayBuffer', {
    
    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      var sample = Helpers.getSample('samples/lorem_utf_100k.txt');
      var deflated = Pako.deflate(sample);

      it('Deflate ArrayBuffer', {
        Assert.isTrue(Helpers.cmpBuf(cast deflated, cast Pako.deflate(sample)));
      });

      it('Inflate ArrayBuffer', {
        Assert.isTrue(Helpers.cmpBuf(cast sample, cast Pako.inflate(deflated)));
      });
    });
  }
}

class TestChunks extends BuddySuite {
  public function new() {
    
    describe('Small input chunks', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('deflate 100b by 1b chunk', {
        var buf = randomBuf(100);
        var deflated = Pako.deflate(buf);
        testChunk(buf, cast deflated, new pako.Deflate(), 1);
      });

      it('deflate 20000b by 10b chunk', {
        var buf = randomBuf(20000);
        var deflated = Pako.deflate(buf);
        testChunk(buf, cast deflated, new pako.Deflate(), 10);
      });

      it('inflate 100b result by 1b chunk', {
        var buf = randomBuf(100);
        var deflated = Pako.deflate(buf);
        testChunk(deflated, cast buf, new pako.Inflate(), 1);
      });

      it('inflate 20000b result by 10b chunk', {
        var buf = randomBuf(20000);
        var deflated = Pako.deflate(buf);
        testChunk(deflated, cast buf, new pako.Inflate(), 10);
      });

    });


    describe('Dummy push (force end)', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('deflate end', {
        var data = Helpers.getSample('samples/lorem_utf_100k.txt');

        var deflator = new pako.Deflate();
        deflator.push(data);
        deflator.push(new UInt8Array(0), true);

        Assert.isTrue(Helpers.cmpBuf(cast deflator.result, cast Pako.deflate(data)));
      });

      it('inflate end', {
        var data = Pako.deflate(Helpers.getSample('samples/lorem_utf_100k.txt'));

        var inflator = new pako.Inflate();
        inflator.push(data);
        inflator.push(new UInt8Array(0), true);

        Assert.isTrue(Helpers.cmpBuf(cast inflator.result, cast Pako.inflate(data)));
      });

    });


    describe('Edge condition', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('should be ok on buffer border', {
        var data = new UInt8Array(1024 * 16 + 1);

        for (i in 0...data.length) {
          data[i] = Math.floor(Math.random() * 255.999);
        }

        var deflated = Pako.deflate(data);

        var inflator = new Inflate();

        for (i in 0...deflated.length) {
          inflator.push(deflated.subarray(i, i+1), false);
          Assert.isTrue(inflator.err == ErrorStatus.Z_OK, 'Inflate failed with status ' + inflator.err);
        }

        inflator.push(new UInt8Array(0), true);

        Assert.isTrue(inflator.err == ErrorStatus.Z_OK, 'Inflate failed with status ' + inflator.err);
        Assert.isTrue(Helpers.cmpBuf(cast data, cast inflator.result));
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

    var onData = packer.onData;
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
    Assert.equals(expFlushCount, flushCount, 'onData called ' + flushCount + 'times, expected: ' + expFlushCount);
  }

}

class TestInflateCover extends BuddySuite
{

  //step argument from original tests is missing because it have no effect
  //we have similar behavior in chunks.js tests
  function testInflate(hex, wbits, status) {
    var inflator;
    try {
      inflator= new pako.Inflate({ windowBits: wbits });
    } catch (e:Dynamic) {
      Assert.isTrue(e.toString() == Messages.get(status));
      return;
    }
    inflator.push(Helpers.h2b(hex), true);
    Assert.equals(status, inflator.err);
  }

  public function new():Void {
    describe('Inflate states', {
    
      #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      //in port checking input parameters was removed
      it('inflate bad parameters', {
        var ret;

        ret = ZlibInflate.inflate(null, 0);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);

        ret = ZlibInflate.inflateEnd(null);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);
        
        //skip: inflateCopy is not implemented
        //ret = zlib_inflate.inflateCopy(null, null);
        //assert(ret == c.Z_STREAM_ERROR);
      });
      it('bad gzip method', {
        testInflate('1f 8b 0 0', 31, ErrorStatus.Z_DATA_ERROR);
      });
      it('bad gzip flags', {
        testInflate('1f 8b 8 80', 31, ErrorStatus.Z_DATA_ERROR);
      });
      it('bad zlib method', {
        testInflate('77 85', 15, ErrorStatus.Z_DATA_ERROR);
      });
      it('set window size from header', {
        testInflate('8 99', 0, ErrorStatus.Z_OK);
      });
      it('bad zlib window size', {
        testInflate('78 9c', 8, ErrorStatus.Z_DATA_ERROR);
      });
      it('check adler32', {
        testInflate('78 9c 63 0 0 0 1 0 1', 15, ErrorStatus.Z_OK);
      });
      it('bad header crc', {
        testInflate('1f 8b 8 1e 0 0 0 0 0 0 1 0 0 0 0 0 0', 47, ErrorStatus.Z_DATA_ERROR);
      });
      it('check gzip length', {
        testInflate('1f 8b 8 2 0 0 0 0 0 0 1d 26 3 0 0 0 0 0 0 0 0 0', 47, ErrorStatus.Z_OK);
      });
      it('bad zlib header check', {
        testInflate('78 90', 47, ErrorStatus.Z_DATA_ERROR);
      });
      it('need dictionary', {
        testInflate('8 b8 0 0 0 1', 8, ErrorStatus.Z_NEED_DICT);
      });
      it('compute adler32', {
        testInflate('78 9c 63 0', 15, ErrorStatus.Z_OK);
      });
    });

    describe('Inflate cover', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('invalid stored block lengths', {
        testInflate('0 0 0 0 0', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('fixed', {
        testInflate('3 0', -15, ErrorStatus.Z_OK);
      });
      it('invalid block type', {
        testInflate('6', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('stored', {
        testInflate('1 1 0 fe ff 0', -15, ErrorStatus.Z_OK);
      });
      it('too many length or distance symbols', {
        testInflate('fc 0 0', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid code lengths set', {
        testInflate('4 0 fe ff', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid bit length repeat', {
        testInflate('4 0 24 49 0', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid bit length repeat', {
        testInflate('4 0 24 e9 ff ff', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid code -- missing end-of-block', {
        testInflate('4 0 24 e9 ff 6d', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid literal/lengths set', {
        testInflate('4 80 49 92 24 49 92 24 71 ff ff 93 11 0', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid literal/length code', {
        testInflate('4 80 49 92 24 49 92 24 f b4 ff ff c3 84', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid distance code', {
        testInflate('2 7e ff ff', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('invalid distance too far back', {
        testInflate('c c0 81 0 0 0 0 0 90 ff 6b 4 0', -15, ErrorStatus.Z_DATA_ERROR);
      });
      it('incorrect data check', {
        testInflate('1f 8b 8 0 0 0 0 0 0 0 3 0 0 0 0 1', 47, ErrorStatus.Z_DATA_ERROR);
      });
      it('incorrect length check', {
        testInflate('1f 8b 8 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 1', 47, ErrorStatus.Z_DATA_ERROR);
      });
      it('pull 17', {
        testInflate('5 c0 21 d 0 0 0 80 b0 fe 6d 2f 91 6c', -15, ErrorStatus.Z_OK);
      });
      it('long code', {
        testInflate('5 e0 81 91 24 cb b2 2c 49 e2 f 2e 8b 9a 47 56 9f fb fe ec d2 ff 1f', -15, ErrorStatus.Z_OK);
      });
      it('length extra', {
        testInflate('ed c0 1 1 0 0 0 40 20 ff 57 1b 42 2c 4f', -15, ErrorStatus.Z_OK);
      });
      it('long distance and extra', {
        testInflate('ed cf c1 b1 2c 47 10 c4 30 fa 6f 35 1d 1 82 59 3d fb be 2e 2a fc f c', -15, ErrorStatus.Z_OK);
      });
      it('window end', {
        testInflate('ed c0 81 0 0 0 0 80 a0 fd a9 17 a9 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 6',
          -15, ErrorStatus.Z_OK);
      });
      it('inflate_fast TYPE return', {
        testInflate('2 8 20 80 0 3 0', -15, ErrorStatus.Z_OK);
      });
      it('window wrap', {
        testInflate('63 18 5 40 c 0', -8, ErrorStatus.Z_OK);
      });
    });

    describe('cover trees', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('inflate_table not enough errors', {
        //NOTE(hx): check sizes (512 should be enough)
        var ret, bits, next:Int32Array, table = new Int32Array(512), lens = new UInt16Array(512), work = new UInt16Array(512);
        var DISTS = 2;
        /* we need to call inflate_table() directly in order to manifest not-
         enough errors, since zlib insures that enough is always enough */
        for (bits in 0...15) {
          lens[bits] = bits + 1;
        }
        lens[15] = 15;
        next = table;

        ret = InfTrees.inflate_table(DISTS, lens, 0, 16, next, 0, work, {bits: 15});
        Assert.isTrue(ret == 1);

        next = table;
        ret = InfTrees.inflate_table(DISTS, lens, 0, 16, next, 0, work, {bits: 1});
        Assert.isTrue(ret == 1);
      });
    });

    describe('Inflate fast', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('fast length extra bits', {
        testInflate('e5 e0 81 ad 6d cb b2 2c c9 01 1e 59 63 ae 7d ee fb 4d fd b5 35 41 68' +
          ' ff 7f 0f 0 0 0', -8, ErrorStatus.Z_DATA_ERROR);
      });
      it('fast distance extra bits', {
        testInflate('25 fd 81 b5 6d 59 b6 6a 49 ea af 35 6 34 eb 8c b9 f6 b9 1e ef 67 49' +
          ' 50 fe ff ff 3f 0 0', -8, ErrorStatus.Z_DATA_ERROR);
      });
      it('fast invalid literal/length code', {
        testInflate('1b 7 0 0 0 0 0', -8, ErrorStatus.Z_DATA_ERROR);
      });
      it('fast 2nd level codes and too far back', {
        testInflate('d c7 1 ae eb 38 c 4 41 a0 87 72 de df fb 1f b8 36 b1 38 5d ff ff 0', -8, ErrorStatus.Z_DATA_ERROR);
      });
      it('very common case', {
        testInflate('63 18 5 8c 10 8 0 0 0 0', -8, ErrorStatus.Z_OK);
      });
      it('contiguous and wrap around window', {
        testInflate('63 60 60 18 c9 0 8 18 18 18 26 c0 28 0 29 0 0 0', -8, ErrorStatus.Z_OK);
      });
      it('copy direct from output', {
        testInflate('63 0 3 0 0 0 0 0', -8, ErrorStatus.Z_OK);
      });
    });

    describe('Inflate support', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      // `inflatePrime` not implemented
      /*it('prime', {
        var ret;
        var strm = new zlib_stream();
        strm.avail_in = 0;
        strm.input = null;

        ret = zlib_inflate.inflateInit(strm);
        assert(ret === ErrorStatus.Z_OK);

        ret = zlib_inflate.inflatePrime(strm, 5, 31);
        assert(ret === ErrorStatus.Z_OK);

        ret = zlib_inflate.inflatePrime(strm, -1, 0);
        assert(ret === ErrorStatus.Z_OK);

        // `inflateSetDictionary` not implemented
        // ret = zlib_inflate.inflateSetDictionary(strm, null, 0);
        // assert(ret === ErrorStatus.Z_STREAM_ERROR);

        ret = zlib_inflate.inflateEnd(strm);
        assert(ret === ErrorStatus.Z_OK);
      });*/
      it('force window allocation', {
        testInflate('63 0', -15, ErrorStatus.Z_OK);
      });
      it('force window replacement', {
        testInflate('63 18 5', -15, ErrorStatus.Z_OK);
      });
      it('force split window update', {
        testInflate('63 18 68 30 d0 0 0', -15, ErrorStatus.Z_OK);
      });
      it('use fixed blocks', {
        testInflate('3 0', -15, ErrorStatus.Z_OK);
      });
      it('bad window size', {
        testInflate('', -15, ErrorStatus.Z_OK);
      });
    });
  }
}

class TestDeflateCover extends BuddySuite
{
  var short_sample = UInt8Array.fromBytes(Bytes.ofString('hello world'));
  var long_sample = Helpers.getSample('samples/lorem_en_100k.txt');

  function testDeflate(data, opts, flush) {
    var deflator = new pako.Deflate(opts);
    deflator.push(data, flush);
    deflator.push(data, true);

    Assert.equals(ErrorStatus.Z_OK, deflator.err, Messages.get(deflator.err));
  }

  public function new():Void {
    describe('Deflate support', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('stored', {
        testDeflate(short_sample, {level: 0, chunkSize: 200}, 0);
        testDeflate(short_sample, {level: 0, chunkSize: 10}, 5);
      });
      it('fast', {
        testDeflate(short_sample, {level: 1, chunkSize: 10}, 5);
        testDeflate(long_sample, {level: 1, memLevel: 1, chunkSize: 10}, 0);
      });
      it('slow', {
        testDeflate(short_sample, {level: 4, chunkSize: 10}, 5);
        testDeflate(long_sample, {level: 9, memLevel: 1, chunkSize: 10}, 0);
      });
      it('rle', {
        testDeflate(short_sample, {strategy: 3}, 0);
        testDeflate(short_sample, {strategy: 3, chunkSize: 10}, 5);
        testDeflate(long_sample, {strategy: 3, chunkSize: 10}, 0);
      });
      it('huffman', {
        testDeflate(short_sample, {strategy: 2}, 0);
        testDeflate(short_sample, {strategy: 2, chunkSize: 10}, 5);
        testDeflate(long_sample, {strategy: 2, chunkSize: 10}, 0);

      });
    });

    describe('Deflate states', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      //in port checking input parameters was removed
      it('inflate bad parameters', {
        var ret, strm;

        ret = ZlibDeflate.deflate(null, 0);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);

        strm = new ZStream();

        ret = ZlibDeflate.deflateInit(null);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);

        ret = ZlibDeflate.deflateInit(strm, 6);
        Assert.isTrue(ret == ErrorStatus.Z_OK);

        ret = ZlibDeflate.deflateSetHeader(null);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);

        @:privateAccess strm.deflateState.wrap = 1;
        ret = ZlibDeflate.deflateSetHeader(strm, null);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);

        @:privateAccess strm.deflateState.wrap = 2;
        ret = ZlibDeflate.deflateSetHeader(strm, null);
        Assert.isTrue(ret == ErrorStatus.Z_OK);

        ret = ZlibDeflate.deflate(strm, Flush.Z_FINISH);
        Assert.isTrue(ret == ErrorStatus.Z_BUF_ERROR);

        ret = ZlibDeflate.deflateEnd(null);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);

        //BS_NEED_MORE
        @:privateAccess strm.deflateState.status = 5;
        ret = ZlibDeflate.deflateEnd(strm);
        Assert.isTrue(ret == ErrorStatus.Z_STREAM_ERROR);
      });
    });
  }
}

class TestGZipSpecials extends BuddySuite
{
  public function new():Void {
    describe('Gzip special cases', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('Read custom headers', {
        var data = Helpers.getSample('gzip-headers.gz');
        var inflator = new pako.Inflate();
        inflator.push(data, true);

        Assert.equals('test name', inflator.header.name);
        Assert.equals('test comment', inflator.header.comment);
        Assert.equals('test extra', Helpers.a2s(cast inflator.header.extra));
      });

      it('Write custom headers', {
        var data = UInt8Array.fromBytes(Bytes.ofString('           '));

        //NOTE(hx): change GZHeader to accept a GZOptions typedef?
        var header = new GZHeader();
        header.hcrc = 1;
        header.time = 1234567;
        header.os = 15;
        header.name = 'test name';
        header.comment = 'test comment';
        header.extra = UInt8Array.fromArray([0, 4, 0, 5, 0, 6]);
        
        var deflator = new pako.Deflate({
          gzip: true,
          header: header
        });
        deflator.push(data, true);

        var inflator = new pako.Inflate();
        inflator.push(deflator.result, true);

        Assert.equals(ErrorStatus.Z_OK, inflator.err);
        Assert.isTrue(Helpers.cmpBuf(cast data, cast inflator.result));

        var inflatedHeader = inflator.header;
        Assert.equals(1234567, inflatedHeader.time);
        Assert.equals(15, inflatedHeader.os);
        Assert.equals('test name', inflatedHeader.name);
        Assert.equals('test comment', inflatedHeader.comment);
        Assert.isTrue(Helpers.cmpBuf(cast inflatedHeader.extra, cast header.extra));
      });

      it('Read stream with SYNC marks', {
        var inflator, strm, _in, len, pos = 0, i = 0;
        var data = Helpers.getSample('gzip-joined.gz');

        do {
          len = data.length - pos;
          _in = new UInt8Array(len);
          Common.arraySet(cast _in, cast data, pos, len, 0);

          inflator = new pako.Inflate();
          strm = inflator.strm;
          inflator.push(_in, true);

          Assert.isTrue(inflator.err == ErrorStatus.Z_OK);

          pos += strm.next_in;
          i++;
        } while (strm.avail_in != 0);

        Assert.isTrue(i == 2, 'invalid blobs count');
      });

    });
  }
}

class TestInflate extends BuddySuite
{
  public function new() { 

    // only files in the fixture/samples
    var samples = Helpers.getSamplesWithPrefix("samples/");

    describe('Inflate defaults', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('inflate, no options', function(done) {
        Helpers.testInflate(samples, {}, {}, done);
      });

      it('inflate raw, no options', function(done) {
        Helpers.testInflate(samples, { raw: true }, { raw: true }, done);
      });

      it('inflate raw from compressed samples', function(done) {
        var compressed_samples = Helpers.getSamplesWithPrefix("samples_deflated_raw/");
        Helpers.testSamples(null, Pako.inflateRaw, compressed_samples, {}, done, 'inflate_raw');
      });
    });


    describe('Inflate ungzip', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('with autodetect', function(done) {
        Helpers.testInflate(samples, {}, { gzip: true }, done);
      });

      it('with method set directly', function(done) {
        Helpers.testInflate(samples, { windowBits: 16 }, { gzip: true }, done);
      });
    });


    describe('Inflate levels', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('level 9', function(done) {
        Helpers.testInflate(samples, {}, { level: 9 }, done);
      });
      it('level 8', function(done) {
        Helpers.testInflate(samples, {}, { level: 8 }, done);
      });
      it('level 7', function(done) {
        Helpers.testInflate(samples, {}, { level: 7 }, done);
      });
      it('level 6', function(done) {
        Helpers.testInflate(samples, {}, { level: 6 }, done);
      });
      it('level 5', function(done) {
        Helpers.testInflate(samples, {}, { level: 5 }, done);
      });
      it('level 4', function(done) {
        Helpers.testInflate(samples, {}, { level: 4 }, done);
      });
      it('level 3', function(done) {
        Helpers.testInflate(samples, {}, { level: 3 }, done);
      });
      it('level 2', function(done) {
        Helpers.testInflate(samples, {}, { level: 2 }, done);
      });
      it('level 1', function(done) {
        Helpers.testInflate(samples, {}, { level: 1 }, done);
      });
      it('level 0', function(done) {
        Helpers.testInflate(samples, {}, { level: 0 }, done);
      });

    });


    describe('Inflate windowBits', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('windowBits 15', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 15 }, done);
      });
      it('windowBits 14', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 14 }, done);
      });
      it('windowBits 13', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 13 }, done);
      });
      it('windowBits 12', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 12 }, done);
      });
      it('windowBits 11', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 11 }, done);
      });
      it('windowBits 10', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 10 }, done);
      });
        
      timeoutMs = 10000; // set timeout to 10.0s
      it('windowBits 9', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 9 }, done);
      });
      timeoutMs = 10000; // set timeout to 10.0s
      it('windowBits 8', function(done) {
        Helpers.testInflate(samples, {}, { windowBits: 8 }, done);
      });

    });

    describe('Inflate strategy', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('Z_DEFAULT_STRATEGY', function(done) {
        Helpers.testInflate(samples, {}, { strategy: 0 }, done);
      });
      it('Z_FILTERED', function(done) {
        Helpers.testInflate(samples, {}, { strategy: 1 }, done);
      });
      it('Z_HUFFMAN_ONLY', function(done) {
        Helpers.testInflate(samples, {}, { strategy: 2 }, done);
      });
      it('Z_RLE', function(done) {
        Helpers.testInflate(samples, {}, { strategy: 3 }, done);
      });
      it('Z_FIXED', function(done) {
        Helpers.testInflate(samples, {}, { strategy: 4 }, done);
      });

    });


    describe('Inflate RAW', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      // Since difference is only in rwapper, test for store/fast/slow methods are enougth
      it('level 9', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 9, raw: true }, done);
      });
      it('level 8', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 8, raw: true }, done);
      });
      it('level 7', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 7, raw: true }, done);
      });
      it('level 6', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 6, raw: true }, done);
      });
      it('level 5', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 5, raw: true }, done);
      });
      it('level 4', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 4, raw: true }, done);
      });
      it('level 3', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 3, raw: true }, done);
      });
      it('level 2', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 2, raw: true }, done);
      });
      it('level 1', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 1, raw: true }, done);
      });
      it('level 0', function(done) {
        Helpers.testInflate(samples, { raw: true }, { level: 0, raw: true }, done);
      });

    });
    
    
    describe('Inflate with dictionary', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end

      it('should throw on the wrong dictionary', function () {
        var zCompressed = Pako.deflate(Helpers.s2a('world'), { dictionary: Helpers.s2a('hello') });
        //var zCompressed = new Buffer([ 120, 187, 6, 44, 2, 21, 43, 207, 47, 202, 73, 1, 0, 6, 166, 2, 41 ]);

        Assert.raises(function () {
          Pako.inflate(zCompressed, { dictionary: Helpers.s2a('world') });
        }, Messages.get(ErrorStatus.Z_DATA_ERROR));
        
      });

      it('trivial dictionary', function (done) {
        var dict = Helpers.s2a('abcdefghijklmnoprstuvwxyz');
        Helpers.testInflate(samples, { dictionary: dict }, { dictionary: dict }, done);
      });

      it('spdy dictionary', function (done) {
        var spdyDict = Helpers.getSample('spdy_dict.txt');

        Helpers.testInflate(samples, { dictionary: spdyDict }, { dictionary: spdyDict }, done);
      });

  });

  }
}

class TestDeflate extends BuddySuite
{ 
  public function new() { 
    var samples = Helpers.getSamplesWithPrefix('samples/');
    
    describe('Deflate defaults', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('deflate, no options', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, {}, done, 'deflate_no_opt');
      });

      it('deflate raw, no options', function(done) {
        Helpers.testSamples(null, Pako.deflateRaw, samples, {}, done, 'deflate_raw_no_opt');
      });

      // OS_CODE can differ. Probably should add param to compare function
      // to ignore some buffer positions
      it('gzip, no options'/*, function(done) {
        Helpers.testSamples(null, Pako.gzip, samples, {}, done, 'gzip_no_opt');
      }*/);
    });


    describe('Deflate levels', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('level 9', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 9 }, done, 'deflate_lev9');
      });
      it('level 8', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 8 }, done, 'deflate_lev8');
      });
      it('level 7', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 7 }, done, 'deflate_lev7');
      });
      it('level 6', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 6 }, done, 'deflate_lev6');
      });
      it('level 5', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 5 }, done, 'deflate_lev5');
      });
      it('level 4', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 4 }, done, 'deflate_lev4');
      });
      it('level 3', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 3 }, done, 'deflate_lev3');
      });
      it('level 2', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 2 }, done, 'deflate_lev2');
      });
      it('level 1', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 1 }, done, 'deflate_lev1');
      });
      it('level 0', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 0 }, done, 'deflate_lev0');
      });
      it('level -1 (implicit default)', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { level: 0 }, done, 'deflate_lev-1');
      });
    });


    describe('Deflate windowBits', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('windowBits 15', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 15 }, done, 'deflate_wb15');
      });
      it('windowBits 14', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 14 }, done, 'deflate_wb14');
      });
      it('windowBits 13', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 13 }, done, 'deflate_wb13');
      });
      it('windowBits 12', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 12 }, done, 'deflate_wb12');
      });
      it('windowBits 11', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 11 }, done, 'deflate_wb11');
      });
      it('windowBits 10', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 10 }, done, 'deflate_wb10');
      });
      it('windowBits 9', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 9 }, done, 'deflate_wb9');
      });
      it('windowBits 8', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: 8 }, done, 'deflate_wb8');
      });
      it('windowBits -15 (implicit raw)', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { windowBits: -15 }, done, 'deflate_wb-15');
      });

    });


    describe('Deflate memLevel', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('memLevel 9', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 9 }, done, 'deflate_mem9');
      });
      it('memLevel 8', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 8 }, done, 'deflate_mem8');
      });
      it('memLevel 7', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 7 }, done, 'deflate_mem7');
      });
      it('memLevel 6', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 6 }, done, 'deflate_mem6');
      });
      it('memLevel 5', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 5 }, done, 'deflate_mem5');
      });
      it('memLevel 4', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 4 }, done, 'deflate_mem4');
      });
      it('memLevel 3', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 3 }, done, 'deflate_mem3');
      });
      it('memLevel 2', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 2 }, done, 'deflate_mem2');
      });
      
      timeoutMs = 10000; // set timeout to 10.0s
      it('memLevel 1', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { memLevel: 1 }, done, 'deflate_mem1');
      });

    });


    describe('Deflate strategy', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('Z_DEFAULT_STRATEGY', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { strategy: 0 }, done, 'deflate_strat_def');
      });
      it('Z_FILTERED', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { strategy: 1 }, done, 'deflate_strat_filt');
      });
      it('Z_HUFFMAN_ONLY', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { strategy: 2 }, done, 'deflate_strat_huff');
      });
      it('Z_RLE', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { strategy: 3 }, done, 'deflate_strat_rle');
      });
      it('Z_FIXED', function(done) {
        Helpers.testSamples(null, Pako.deflate, samples, { strategy: 4 }, done, 'deflate_strat_fix');
      });

    });


    describe('Deflate RAW', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      // Since difference is only in rwapper, test for store/fast/slow methods are enougth
      it('level 4', function(done) {
        Helpers.testSamples(null, Pako.deflateRaw, samples, { level: 4 }, done, 'deflate_raw_lev4');
      });
      it('level 1', function(done) {
        Helpers.testSamples(null, Pako.deflateRaw, samples, { level: 1 }, done, 'deflate_raw_lev1');
      });
      it('level 0', function(done) {
        Helpers.testSamples(null, Pako.deflateRaw, samples, { level: 0 }, done, 'deflate_raw_lev0');
      });

    });
    
    
    describe('Deflate dictionary', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('trivial dictionary', function (done) {
        var dict = Helpers.s2a('abcdefghijklmnoprstuvwxyz');
        Helpers.testSamples(null, Pako.deflate, samples, { dictionary: dict }, done, 'deflate_dict_trivial');
      });

      it('spdy dictionary', function (done) {
        var spdyDict = Helpers.getSample('spdy_dict.txt');

        Helpers.testSamples(null, Pako.deflate, samples, { dictionary: spdyDict }, done, 'deflate_dict_spdy');
      });

      it('handles multiple pushes', function () {
        var dict = Helpers.s2a('abcd');
        var deflate = new pako.Deflate({ dictionary: dict });

        deflate.push(Helpers.s2a('hello'), false);
        deflate.push(Helpers.s2a('hello'), false);
        deflate.push(Helpers.s2a(' world'), true);

        if (deflate.err != ErrorStatus.Z_OK) { throw Messages.get(deflate.err); }

        var uncompressed = Pako.inflate(deflate.result, { dictionary: dict });

        if (!Helpers.cmpBuf(cast Helpers.s2a('hellohello world'), cast uncompressed)) {
          throw 'Result not equal for p -> z';
        }
      });

    });
    
    
    describe('Deflate issues', {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('#78', function () {
        var data = Helpers.getSample('issue_78.bin');
        var deflatedPakoData = Pako.deflate(data, { memLevel: 1 });
        var inflatedPakoData = Pako.inflate(deflatedPakoData);

        Assert.equals(data.length, inflatedPakoData.length);

      });

    });
  }
}

// NOTE(hx): dummy strings tests (not supported in the hx port)
class TestStrings extends BuddySuite {
  public function new() {
    
    describe('Encode/Decode strings', {
    
    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('utf-8 border detect', function () {
        
      });

      it('Encode string to utf8 buf', function () {
        
      });

      it('Decode utf8 buf to string', function () {
        
      });

    });


    describe('Deflate/Inflate strings', function () {

    #if (cpp && telemetry)
      before(TestAll.hxt.advance_frame());
      after(TestAll.hxt.advance_frame());
    #end
    
      it('Deflate javascript string (utf16) on input', function () {
        
      });

      it('Deflate with binary string output', function () {
        
      });

      it('Inflate binary string input', function () {
        
      });

      it('Inflate with javascript string (utf16) output', function () {
        
      });
      
    });
  }
}

