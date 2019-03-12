package pako.zlib;

import haxe.io.UInt8Array;

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

class GZHeader
{
  /* true if compressed data believed to be text */
  public var text:Bool       = false;
  /* modification time */
  public var time:Int        = 0;
  /* extra flags (not used when writing a gzip file) */
  public var xflags:Int      = 0;
  /* operating system */
  public var os:Int          = 0;
  /* pointer to extra field or Z_NULL if none */
  public var extra:UInt8Array = null;
  /* extra field length (valid if extra != Z_NULL) */
  public var extra_len:Int   = 0; // Actually, we don't need it in JS,
                       // but leave for few code modifications

  //
  // Setup limits is not necessary because in js we should not preallocate memory
  // for inflate use constant limit in 65536 bytes
  //

  /* space at extra (only when reading header) */
  // public var extra_max  = 0;
  /* pointer to zero-terminated file name or Z_NULL */
  public var name:String     = '';
  /* space at name (only when reading header) */
  // public var name_max   = 0;
  /* pointer to zero-terminated comment or Z_NULL */
  public var comment:String  = '';
  /* space at comment (only when reading header) */
  // public var comm_max   = 0;
  /* true if there was or will be a header crc */
  public var hcrc:Int        = 0;
  /* true when done reading gzip header (not used when writing a gzip file) */
  public var done:Bool       = false;

  //NOTE(hx): change GZHeader to accept a GZOptions typedef?
  public function new() { }
}