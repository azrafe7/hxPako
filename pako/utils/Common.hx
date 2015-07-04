package pako.utils;

import haxe.io.ArrayBufferView;
import haxe.io.UInt8Array;

class Common
{
  //NOTE(hx): blit (reset pos to respective offsets?)
  static public function arraySet(dest:ArrayBufferView, src:ArrayBufferView, src_offs:Int, len:Int, dest_offs:Int) {
    dest.buffer.blit(dest_offs, src.buffer, src_offs, len);
    
  }
  
  //NOTE(hx): moved here from Trees and Deflate
  static public function zero(buf:ArrayBufferView) { 
    var start = buf.byteOffset;
    var len = buf.byteLength; 
    buf.buffer.fill(start, len, 0);
  }
  
  //NOTE(hx): if ArrayBufferView.EMULATED it will be a copy
  // reduce buffer size, avoiding mem copy
  static public function shrinkBuf(buf:UInt8Array, size:Int) {
    if (buf.length == size) { return buf; }
    return buf.subarray(0, size);
  }
  
  //NOTE(hx): blit
  // Join array of chunks to single array.
  static public function flattenChunks(chunks:Array<UInt8Array>) {
    var i, l, len, pos, chunk:UInt8Array, result:UInt8Array;

    // calculate data length
    len = 0;
    l = chunks.length;
    for (i in 0...l) {
      len += chunks[i].length;
    }

    // join chunks
    result = new UInt8Array(len);
    pos = 0;
    for (i in 0...l) {
      chunk = chunks[i];
      result.view.buffer.blit(pos, chunk.view.buffer, 0, chunk.length);
      pos += chunk.length;
    }

    return result;
  }
}

/*'use strict';


var TYPED_OK =  (typeof Uint8Array !== 'undefined') &&
                (typeof Uint16Array !== 'undefined') &&
                (typeof Int32Array !== 'undefined');


exports.assign = function (obj /*from1, from2, from3, ...*//*) {
  var sources = Array.prototype.slice.call(arguments, 1);
  while (sources.length) {
    var source = sources.shift();
    if (!source) { continue; }

    if (typeof source !== 'object') {
      throw new TypeError(source + 'must be non-object');
    }

    for (var p in source) {
      if (source.hasOwnProperty(p)) {
        obj[p] = source[p];
      }
    }
  }

  return obj;
};


// reduce buffer size, avoiding mem copy
exports.shrinkBuf = function (buf, size) {
  if (buf.length === size) { return buf; }
  if (buf.subarray) { return buf.subarray(0, size); }
  buf.length = size;
  return buf;
};


var fnTyped = {
  arraySet: function (dest, src, src_offs, len, dest_offs) {
    if (src.subarray && dest.subarray) {
      dest.set(src.subarray(src_offs, src_offs+len), dest_offs);
      return;
    }
    // Fallback to ordinary array
    for (var i=0; i<len; i++) {
      dest[dest_offs + i] = src[src_offs + i];
    }
  },
  // Join array of chunks to single array.
  flattenChunks: function(chunks) {
    var i, l, len, pos, chunk, result;

    // calculate data length
    len = 0;
    for (i=0, l=chunks.length; i<l; i++) {
      len += chunks[i].length;
    }

    // join chunks
    result = new Uint8Array(len);
    pos = 0;
    for (i=0, l=chunks.length; i<l; i++) {
      chunk = chunks[i];
      result.set(chunk, pos);
      pos += chunk.length;
    }

    return result;
  }
};

var fnUntyped = {
  arraySet: function (dest, src, src_offs, len, dest_offs) {
    for (var i=0; i<len; i++) {
      dest[dest_offs + i] = src[src_offs + i];
    }
  },
  // Join array of chunks to single array.
  flattenChunks: function(chunks) {
    return [].concat.apply([], chunks);
  }
};


// Enable/Disable typed arrays use, for testing
//
exports.setTyped = function (on) {
  if (on) {
    exports.Buf8  = Uint8Array;
    exports.Buf16 = Uint16Array;
    exports.Buf32 = Int32Array;
    exports.assign(exports, fnTyped);
  } else {
    exports.Buf8  = Array;
    exports.Buf16 = Array;
    exports.Buf32 = Array;
    exports.assign(exports, fnUntyped);
  }
};

exports.setTyped(TYPED_OK);
*/