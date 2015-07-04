package pako;

import haxe.io.UInt8Array;
import pako.Inflate.InflateOptions;
import pako.zlib.Inflate as ZlibInflate;
import pako.utils.Common;
import pako.zlib.Messages;
import pako.zlib.ZStream;
import pako.zlib.Constants;
import pako.zlib.Constants.CompressionLevel;
import pako.zlib.GZHeader;


typedef InflateOptions = {
  @:optional var chunkSize:Int;
  @:optional var windowBits:Int;
  @:optional var raw:Bool;
  //to: ''
}


/**
 * class Inflate
 *
 * Generic JS-style wrapper for zlib calls. If you don't need
 * streaming behaviour - use more simple functions: [[inflate]]
 * and [[inflateRaw]].
 **/

/* internal
 * inflate.chunks -> Array
 *
 * Chunks of output data, if [[Inflate#onData]] not overriden.
 **/

/**
 * Inflate.result -> Uint8Array|Array|String
 *
 * Uncompressed result, generated by default [[Inflate#onData]]
 * and [[Inflate#onEnd]] handlers. Filled after you push last chunk
 * (call [[Inflate#push]] with `Z_FINISH` / `true` param) or if you
 * push a chunk with explicit flush (call [[Inflate#push]] with
 * `Z_SYNC_FLUSH` param).
 **/

/**
 * Inflate.err -> Number
 *
 * Error code after inflate finished. 0 (Z_OK) on success.
 * Should be checked if broken data possible.
 **/

/**
 * Inflate.msg -> String
 *
 * Error message, if [[Inflate.err]] != 0
 **/


/**
 * new Inflate(options)
 * - options (Object): zlib inflate options.
 *
 * Creates new inflator instance with specified params. Throws exception
 * on bad params. Supported options:
 *
 * - `windowBits`
 *
 * [http://zlib.net/manual.html#Advanced](http://zlib.net/manual.html#Advanced)
 * for more information on these.
 *
 * Additional options, for internal needs:
 *
 * - `chunkSize` - size of generated data chunks (16K by default)
 * - `raw` (Boolean) - do raw inflate
 * - `to` (String) - if equal to 'string', then result will be converted
 *   from utf8 to utf16 (javascript) string. When string output requested,
 *   chunk length can differ from `chunkSize`, depending on content.
 *
 * By default, when no options set, autodetect deflate/gzip data format via
 * wrapper header.
 *
 * ##### Example:
 *
 * ```javascript
 * var pako = require('pako')
 *   , chunk1 = Uint8Array([1,2,3,4,5,6,7,8,9])
 *   , chunk2 = Uint8Array([10,11,12,13,14,15,16,17,18,19]);
 *
 * var inflate = new pako.Inflate({ level: 3});
 *
 * inflate.push(chunk1, false);
 * inflate.push(chunk2, true);  // true -> last chunk
 *
 * if (inflate.err) { throw new Error(inflate.err); }
 *
 * console.log(inflate.result);
 * ```
 **/
class Inflate 
{
  static var DEFAULT_OPTIONS:InflateOptions = {
    chunkSize: 16384,
    windowBits: 0,
    raw: false,
    //to: ''
  }
  
  public var options:InflateOptions = null;
  
  public var err:ErrorStatus    = Z_OK;      // error code, if happens (0 = Z_OK)
  public var msg:String    = '';     // error message
  public var ended:Bool  = false;  // used to avoid multiple onEnd() calls
  public var chunks:Array<UInt8Array> = [];     // chunks of compressed data

  public var strm:ZStream   = new ZStream();

  public var header:GZHeader = new GZHeader();
  
  public var result:UInt8Array = null;

  public function new(options:InflateOptions = null) {

    this.options = { };
    this.options.chunkSize = (options != null && options.chunkSize != null) ? options.chunkSize : DEFAULT_OPTIONS.chunkSize;
    this.options.windowBits = (options != null && options.windowBits != null) ? options.windowBits : DEFAULT_OPTIONS.windowBits;
    this.options.raw = (options != null && options.raw != null) ? options.raw : DEFAULT_OPTIONS.raw;
  
    // Force window size for `raw` data, if not set directly,
    // because we have no header for autodetect.
    if (this.options.raw && (this.options.windowBits >= 0) && (this.options.windowBits < 16)) {
      this.options.windowBits = -this.options.windowBits;
      if (this.options.windowBits == 0) { this.options.windowBits = -15; }
    }

    // If `windowBits` not defined (and mode not raw) - set autodetect flag for gzip/deflate
    if ((this.options.windowBits >= 0) && (this.options.windowBits < 16) &&
        (options == null || options.windowBits == null)) {
      this.options.windowBits += 32;
    }

    // Gzip header has no info about windows size, we can do autodetect only
    // for deflate. So, if window size not set, force it to max when gzip possible
    if ((this.options.windowBits > 15) && (this.options.windowBits < 48)) {
      // bit 3 (16) -> gzipped data
      // bit 4 (32) -> autodetect gzip/deflate
      if ((this.options.windowBits & 15) == 0) {
        this.options.windowBits |= 15;
      }
    }

    this.onData = _onData;
    this.onEnd = _onEnd;
    
    this.strm.avail_out = 0;

    var status  = ZlibInflate.inflateInit2(
      this.strm,
      this.options.windowBits
    );

    if (status != Z_OK) {
      throw Messages.get(status);
    }
    
    ZlibInflate.inflateGetHeader(this.strm, this.header);
  }

  /**
   * Inflate#push(data[, mode]) -> Boolean
   * - data (Uint8Array|Array|ArrayBuffer|String): input data
   * - mode (Number|Boolean): 0..6 for corresponding Z_NO_FLUSH..Z_TREE modes.
   *   See constants. Skipped or `false` means Z_NO_FLUSH, `true` meansh Z_FINISH.
   *
   * Sends input data to inflate pipe, generating [[Inflate#onData]] calls with
   * new output chunks. Returns `true` on success. The last data block must have
   * mode Z_FINISH (or `true`). That will flush internal pending buffers and call
   * [[Inflate#onEnd]]. For interim explicit flushes (without ending the stream) you
   * can use mode Z_SYNC_FLUSH, keeping the decompression context.
   *
   * On fail call [[Inflate#onEnd]] with error code and return false.
   *
   * We strongly recommend to use `Uint8Array` on input for best speed (output
   * format is detected automatically). Also, don't skip last param and always
   * use the same type in your code (boolean or number). That will improve JS speed.
   *
   * For regular `Array`-s make sure all elements are [0..255].
   *
   * ##### Example
   *
   * ```javascript
   * push(chunk, false); // push one of data chunks
   * ...
   * push(chunk, true);  // push last chunk
   * ```
   **/
  public function push(data:UInt8Array, mode:Dynamic) {
    var strm = this.strm;
    var chunkSize = this.options.chunkSize;
    var status, _mode:Flush;
    var next_out_utf8, tail, utf8str;

    if (this.ended) { return false; }
    
    //NOTE(hx): search codebase for ~~
    //_mode = (mode == ~~mode) ? mode : ((mode == true) ? Z_FINISH : Z_NO_FLUSH);
    if (Std.is(mode, Int)) _mode = mode;
    else if (Std.is(mode, Bool)) _mode = mode ? Z_FINISH : Z_NO_FLSH;
    else throw "Invalid mode.";

    // Convert data if needed
    //NOTE(hx): only supporting UInt8Array
    /*if (typeof data === 'string') {
      // Only binary strings can be decompressed on practice
      strm.input = strings.binstring2buf(data);
    } else if (toString.call(data) === '[object ArrayBuffer]') {
      strm.input = new Uint8Array(data);
    } else*/ {
      strm.input = data;
    }

    strm.next_in = 0;
    strm.avail_in = strm.input.length;

    do {
      if (strm.avail_out == 0) {
        strm.output = new UInt8Array(chunkSize);
        strm.next_out = 0;
        strm.avail_out = chunkSize;
      }

      status = ZlibInflate.inflate(strm, Flush.Z_NO_FLUSH);    /* no bad return value */

      if (status != Z_STREAM_END && status != Z_OK) {
        this.onEnd(status);
        this.ended = true;
        return false;
      }

      if (strm.next_out != 0) {
        if (strm.avail_out == 0 || status == Z_STREAM_END || (strm.avail_in == 0 && (_mode == Z_FINISH || _mode == Z_SYNC_FLUSH))) {

          //NOTE(hx): only supporting UInt8Array
          /*if (this.options.to === 'string') {

            next_out_utf8 = strings.utf8border(strm.output, strm.next_out);

            tail = strm.next_out - next_out_utf8;
            utf8str = strings.buf2string(strm.output, next_out_utf8);

            // move tail
            strm.next_out = tail;
            strm.avail_out = chunkSize - tail;
            if (tail) { utils.arraySet(strm.output, strm.output, next_out_utf8, tail, 0); }

            this.onData(utf8str);

          } else*/ {
            this.onData(Common.shrinkBuf(strm.output, strm.next_out));
          }
        }
      }
    } while ((strm.avail_in > 0) && status != Z_STREAM_END);

    if (status == Z_STREAM_END) {
      _mode = Z_FINISH;
    }

    // Finalize on the last chunk.
    if (_mode == Z_FINISH) {
      status = ZlibInflate.inflateEnd(this.strm);
      this.onEnd(status);
      this.ended = true;
      return status == Z_OK;
    }

    // callback interim results if Z_SYNC_FLUSH.
    if (_mode == Z_SYNC_FLUSH) {
      this.onEnd(Z_OK);
      strm.avail_out = 0;
      return true;
    }

    return true;
  }


  /**
   * Inflate#onData(chunk) -> Void
   * - chunk (Uint8Array|Array|String): ouput data. Type of array depends
   *   on js engine support. When string output requested, each chunk
   *   will be string.
   *
   * By default, stores data blocks in `chunks[]` property and glue
   * those in `onEnd`. Override this handler, if you need another behaviour.
   **/
  public var onData:UInt8Array->Void;
  
  function _onData(chunk:UInt8Array) {
    this.chunks.push(chunk);
  }


  /**
   * Inflate#onEnd(status) -> Void
   * - status (Number): inflate status. 0 (Z_OK) on success,
   *   other if not.
   *
   * Called either after you tell inflate that the input stream is
   * complete (Z_FINISH) or should be flushed (Z_SYNC_FLUSH)
   * or if an error happened. By default - join collected chunks,
   * free memory and fill `results` / `err` properties.
   **/
  public var onEnd:ErrorStatus->Void;
  
  function _onEnd(status:ErrorStatus) {
    // On success - join
    if (status == Z_OK) {
      //NOTE(hx): only supporting UInt8Array
      /*if (this.options.to === 'string') {
        // Glue & convert here, until we teach pako to send
        // utf8 alligned strings to onData
        this.result = this.chunks.join('');
      } else*/ {
        this.result = Common.flattenChunks(this.chunks);
      }
    }
    this.chunks = [];
    this.err = status;
    this.msg = this.strm.msg;
  }


  /**
   * inflate(data[, options]) -> Uint8Array|Array|String
   * - data (Uint8Array|Array|String): input data to decompress.
   * - options (Object): zlib inflate options.
   *
   * Decompress `data` with inflate/ungzip and `options`. Autodetect
   * format via wrapper header by default. That's why we don't provide
   * separate `ungzip` method.
   *
   * Supported options are:
   *
   * - windowBits
   *
   * [http://zlib.net/manual.html#Advanced](http://zlib.net/manual.html#Advanced)
   * for more information.
   *
   * Sugar (options):
   *
   * - `raw` (Boolean) - say that we work with raw stream, if you don't wish to specify
   *   negative windowBits implicitly.
   * - `to` (String) - if equal to 'string', then result will be converted
   *   from utf8 to utf16 (javascript) string. When string output requested,
   *   chunk length can differ from `chunkSize`, depending on content.
   *
   *
   * ##### Example:
   *
   * ```javascript
   * var pako = require('pako')
   *   , input = pako.deflate([1,2,3,4,5,6,7,8,9])
   *   , output;
   *
   * try {
   *   output = pako.inflate(input);
   * } catch (err)
   *   console.log(err);
   * }
   * ```
   **/
  static public function inflate(input:UInt8Array, ?options:InflateOptions) {
    var inflator = new Inflate(options);

    inflator.push(input, true);

    // That will never happens, if you don't cheat with options :)
    if (inflator.err != Z_OK) { throw inflator.msg; }

    return inflator.result;
  }


  /**
   * inflateRaw(data[, options]) -> Uint8Array|Array|String
   * - data (Uint8Array|Array|String): input data to decompress.
   * - options (Object): zlib inflate options.
   *
   * The same as [[inflate]], but creates raw data, without wrapper
   * (header and adler32 crc).
   **/
  static public function inflateRaw(input:UInt8Array, ?options:InflateOptions) {
    if (options == null) options = { };
    options.raw = true;
    return inflate(input, options);
  }


  /**
   * ungzip(data[, options]) -> Uint8Array|Array|String
   * - data (Uint8Array|Array|String): input data to decompress.
   * - options (Object): zlib inflate options.
   *
   * Just shortcut to [[inflate]], because it autodetects format
   * by header.content. Done for convenience.
   **/
}

/*
exports.Inflate = Inflate;
exports.inflate = inflate;
exports.inflateRaw = inflateRaw;
exports.ungzip  = inflate;
*/