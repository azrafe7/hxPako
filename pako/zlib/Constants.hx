package pako.zlib;

/* Allowed flush values; see deflate() and inflate() below for details */
@:enum abstract Flush(Int) 
{
  var Z_NO_FLUSH =         0;
  var Z_PARTIAL_FLUSH =    1;
  var Z_SYNC_FLUSH =       2;
  var Z_FULL_FLUSH =       3;
  var Z_FINISH =           4;
  var Z_BLOCK =            5;
  var Z_TREES =            6;
}

/* Return codes for the compression/decompression functions. Negative values
* are errors, positive values are used for special but normal events.
*/
@:enum abstract Error(Int) to Int
{
  var Z_OK =               0;
  var Z_STREAM_END =       1;
  var Z_NEED_DICT =        2;
  var Z_ERRNO =           -1;
  var Z_STREAM_ERROR =    -2;
  var Z_DATA_ERROR =      -3;
  var Z_MEM_ERROR =       -4; //NOTE(hx): commented out in pako.js
  var Z_BUF_ERROR =       -5;
  var Z_VERSION_ERROR =   -6; //NOTE(hx): commented out in pako.js
}

/* compression levels */
abstract CompressionLevel(Int) from Int to Int
{
  static public inline var Z_NO_COMPRESSION =         0;
  static public inline var Z_BEST_SPEED =             1;
  static public inline var Z_BEST_COMPRESSION =       9;
  static public inline var Z_DEFAULT_COMPRESSION =   -1;
}

@:enum abstract Strategy(Int)
{
  var Z_FILTERED =               1;
  var Z_HUFFMAN_ONLY =           2;
  var Z_RLE =                    3;
  var Z_FIXED =                  4;
  var Z_DEFAULT_STRATEGY =       0;
}

/* Possible values of the data_type field (though see inflate()) */
@:enum abstract DataType(Int)
{
  var Z_BINARY =                 0;
  var Z_TEXT =                   1;
  //var Z_ASCII =                1; // = Z_TEXT (deprecated)
  var Z_UNKNOWN =                2;
}

/* The deflate compression method */
@:enum abstract Method(Int)
{
  var Z_DEFLATED =               8;
  //var Z_NULL =                 null; // Use -1 or null inline, depending on var type
}
