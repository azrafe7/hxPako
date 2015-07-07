package;

import haxe.io.ArrayBufferView;
import haxe.io.Bytes;
import haxe.io.Int32Array;
import haxe.io.UInt16Array;
import haxe.io.UInt32Array;
import haxe.io.UInt8Array;
import haxe.Resource;
import haxe.Utf8;
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
import buddy.*;
import utest.Assert;
import Helpers;

using buddy.Should;


class Main implements Buddy<[Misc, Chunks/*, InflateCoverPorted, DeflateCover*/, GZipSpecials]> { }

class Misc extends BuddySuite {
    public function new() {
      
      describe('ArrayBuffer', {
        
        var sample = Helpers.getSample('lorem_utf_100k.txt');
        var deflated = Deflate.deflate(sample);

        it('Deflate ArrayBuffer', {
          Assert.isTrue(Helpers.cmpBuf(cast deflated, cast Deflate.deflate(sample)));
        });

        it('Inflate ArrayBuffer', {
          Assert.isTrue(Helpers.cmpBuf(cast sample, cast Inflate.inflate(deflated)));
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
        testChunk(buf, cast deflated, new pako.Deflate(), 1);
      });

      it('deflate 20000b by 10b chunk', {
        var buf = randomBuf(20000);
        var deflated = Deflate.deflate(buf);
        testChunk(buf, cast deflated, new pako.Deflate(), 10);
      });

      it('inflate 100b result by 1b chunk', {
        var buf = randomBuf(100);
        var deflated = Deflate.deflate(buf);
        testChunk(deflated, cast buf, new pako.Inflate(), 1);
      });

      it('inflate 20000b result by 10b chunk', {
        var buf = randomBuf(20000);
        var deflated = Deflate.deflate(buf);
        testChunk(deflated, cast buf, new pako.Inflate(), 10);
      });

    });


    describe('Dummy push (force end)', {

      it('deflate end', {
        var data = Helpers.getSample('lorem_utf_100k.txt');

        var deflator = new pako.Deflate();
        deflator.push(data);
        deflator.push(new UInt8Array(0), true);

        Assert.isTrue(Helpers.cmpBuf(cast deflator.result, cast Deflate.deflate(data)));
      });

      it('inflate end', {
        var data = Deflate.deflate(Helpers.getSample('lorem_utf_100k.txt'));

        var inflator = new pako.Inflate();
        inflator.push(data);
        inflator.push(new UInt8Array(0), true);

        Assert.isTrue(Helpers.cmpBuf(cast inflator.result, cast Inflate.inflate(data)));
      });

    });


    describe('Edge condition', {

      it('should be ok on buffer border', {
        var data = new UInt8Array(1024 * 16 + 1);

        for (i in 0...data.length) {
          data[i] = Math.floor(Math.random() * 255.999);
        }

        var deflated = Deflate.deflate(data);

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
    Assert.equals(expFlushCount, flushCount, 'onData called ' + flushCount + 'times, expected: ' + expFlushCount);
  }

}

class InflateCoverPorted extends BuddySuite
{
  static public function toStr(arr:ArrayBufferView) {
    var str = "[";
    for (i in arr.byteOffset...arr.byteOffset + arr.byteLength) str += arr.buffer.get(i) + ",";
    return str + "]";
  }
  
  function h2b(hex:String) {
    var array = hex.split(' ').map(function(hx) { return Std.parseInt("0x" + hx); } );
    var data8:UInt8Array = UInt8Array.fromArray(array);
    var data8str = toStr(cast data8);
    return data8;
  }


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
    inflator.push(h2b(hex), true);
    Assert.equals(status, inflator.err);
  }

  public function new():Void {
    describe('Inflate states', {
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

class DeflateCover extends BuddySuite
{
  var short_sample = UInt8Array.fromBytes(Bytes.ofString('hello world'));
  var long_sample = Helpers.samples['lorem_en_100k.txt'];

  function testDeflate(data, opts, flush) {
    var deflator = new pako.Deflate(opts);
    deflator.push(data, flush);
    deflator.push(data, true);

    Assert.equals(ErrorStatus.Z_OK, deflator.err, Messages.get(deflator.err));
  }

  public function new():Void {
    describe('Deflate support', {
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

class GZipSpecials extends BuddySuite
{
  function a2s(typedArray:UInt8Array) {
    var str = "";
    var arrStr = InflateCoverPorted.toStr(typedArray.view);
    for (i in 0...typedArray.length) {
      str += String.fromCharCode(typedArray[i]);
    }
    return str;
  }

  public function new():Void {
    describe('Gzip special cases', {

      it('Read custom headers', {
        var data = Helpers.getSample('gzip-headers.gz');
        var inflator = new pako.Inflate();
        inflator.push(data, true);

        Assert.equals('test name', inflator.header.name);
        Assert.equals('test comment', inflator.header.comment);
        Assert.equals('test extra', a2s(cast inflator.header.extra));
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