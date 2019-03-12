package pako.zlib;

import haxe.ds.IntMap;
import pako.zlib.Constants;

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

//NOTE(hx): might as well refactor Error to be over string
class Messages
{
  static var map:IntMap<String> = [
    ErrorStatus.Z_NEED_DICT =>      'need dictionary',     /* Z_NEED_DICT       2  */
    ErrorStatus.Z_STREAM_END =>     'stream end',          /* Z_STREAM_END      1  */
    ErrorStatus.Z_OK =>             '',                    /* Z_OK              0  */
    ErrorStatus.Z_ERRNO =>          'file error',          /* Z_ERRNO         (-1) */
    ErrorStatus.Z_STREAM_ERROR =>   'stream error',        /* Z_STREAM_ERROR  (-2) */
    ErrorStatus.Z_DATA_ERROR =>     'data error',          /* Z_DATA_ERROR    (-3) */
    ErrorStatus.Z_MEM_ERROR =>      'insufficient memory', /* Z_MEM_ERROR     (-4) */
    ErrorStatus.Z_BUF_ERROR =>      'buffer error',        /* Z_BUF_ERROR     (-5) */
    ErrorStatus.Z_VERSION_ERROR =>  'incompatible version' /* Z_VERSION_ERROR (-6) */
  ];

  static public function get(error:Int) {
    return "ERROR: " + map.get(error);
  }
}
