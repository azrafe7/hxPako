package pako.zlib;

import haxe.ds.IntMap;
import pako.zlib.Constants.Error;

//NOTE(hx): might as well refactor Error to be over string
class Messages
{
  static var map:IntMap<String> = [
    Z_NEED_DICT =>      'need dictionary',     /* Z_NEED_DICT       2  */
    Z_STREAM_END =>     'stream end',          /* Z_STREAM_END      1  */
    Z_OK =>             '',                    /* Z_OK              0  */
    Z_ERRNO =>          'file error',          /* Z_ERRNO         (-1) */
    Z_STREAM_ERROR =>   'stream error',        /* Z_STREAM_ERROR  (-2) */
    Z_DATA_ERROR =>     'data error',          /* Z_DATA_ERROR    (-3) */
    Z_MEM_ERROR =>      'insufficient memory', /* Z_MEM_ERROR     (-4) */
    Z_BUF_ERROR =>      'buffer error',        /* Z_BUF_ERROR     (-5) */
    Z_VERSION_ERROR =>  'incompatible version' /* Z_VERSION_ERROR (-6) */
  ];
  
  static public function get(error:pako.zlib.Constants.Error) {
    return "ERROR: " + map.get(error);
  }
}
