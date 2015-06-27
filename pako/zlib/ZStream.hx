package pako.zlib;

import haxe.io.UInt8Array;

class ZStream
{
  /* next input byte */
  public var input:UInt8Array = null; // JS specific, because we have no pointers
  public var next_in:Int = 0;
  /* number of bytes available at input */
  public var avail_in:Int = 0;
  /* total number of input bytes read so far */
  public var total_in:Int = 0;
  /* next output byte should be put there */
  public var output:UInt8Array = null; // JS specific, because we have no pointers
  public var next_out:Int = 0;
  /* remaining free space at output */
  public var avail_out:Int = 0;
  /* total number of bytes output so far */
  public var total_out:Int = 0;
  /* last error message, NULL if no error */
  public var msg = ''/*Z_NULL*/;
  /* not visible by applications */
  var state = null;
  /* best guess about the data type: binary or text */
  public var data_type:Constants.DataType = Constants.DataType.Z_UNKNOWN /*Z_UNKNOWN*/;
  /* adler32 value of the uncompressed data */
  public var adler:Int = 0;
  
  public function new():Void { }
}