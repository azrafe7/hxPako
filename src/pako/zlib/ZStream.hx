package pako.zlib;

import haxe.io.UInt8Array;
import pako.zlib.Deflate.DeflateState;
import pako.zlib.Inflate.InflateState;

// (C) 1995-2013 Jean-loup Gailly and Mark Adler
// (C) 2014-2017 Vitaly Puzrin and Andrey Tupitsin
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//   claim that you wrote the original software. If you use this software
//   in a product, an acknowledgment in the product documentation would be
//   appreciated but is not required.
// 2. Altered source versions must be plainly marked as such, and must not be
//   misrepresented as being the original software.
// 3. This notice may not be removed or altered from any source distribution.

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
  public var deflateState:DeflateState = null;
  public var inflateState:InflateState = null;
  /* best guess about the data type: binary or text */
  public var data_type:Int = Constants.DataType.Z_UNKNOWN /*Z_UNKNOWN*/;
  /* adler32 value of the uncompressed data */
  public var adler:Int = 0;

  public function new():Void { }
}