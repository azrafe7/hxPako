package pako.zlib;

class Constants { }

/* Allowed flush values; see deflate() and inflate() below for details */
@:enum abstract Flush(Int) to Int from Int
{
  var Z_NO_FLUSH =         0;
  var Z_PARTIAL_FLUSH =    1;
  var Z_SYNC_FLUSH =       2;
  var Z_FULL_FLUSH =       3;
  var Z_FINISH =           4;
  var Z_BLOCK =            5;
  var Z_TREES =            6;
 
  @:from static function fromInt(i:Int) {
    if (i < Z_NO_FLUSH || i > Z_TREES) throw "Invalid Flush!";
    return cast i;
  }
	
  // forward comparison operators
  @:op(A == B) static function eq(a:Flush, b:Flush):Bool;
	@:op(A == B) @:commutative static function eqInt(a:Flush, b:Int):Bool;
	@:op(A == B) @:commutative static function eqFloat(a:Flush, b:Float):Bool;

	@:op(A != B) static function neq(a:Flush, b:Flush):Bool;
	@:op(A != B) @:commutative static function neqInt(a:Flush, b:Int):Bool;
	@:op(A != B) @:commutative static function neqFloat(a:Flush, b:Float):Bool;

	@:op(A < B) static function lt(a:Flush, b:Flush):Bool;
	@:op(A < B) static function ltInt(a:Flush, b:Int):Bool;
	@:op(A < B) static function intLt(a:Int, b:Flush):Bool;
	@:op(A < B) static function ltFloat(a:Flush, b:Float):Bool;
	@:op(A < B) static function floatLt(a:Float, b:Flush):Bool;

	@:op(A <= B) static function lte(a:Flush, b:Flush):Bool;
	@:op(A <= B) static function lteInt(a:Flush, b:Int):Bool;
	@:op(A <= B) static function intLte(a:Int, b:Flush):Bool;
	@:op(A <= B) static function lteFloat(a:Flush, b:Float):Bool;
	@:op(A <= B) static function floatLte(a:Float, b:Flush):Bool;

	@:op(A > B) static function gt(a:Flush, b:Flush):Bool;
	@:op(A > B) static function gtInt(a:Flush, b:Int):Bool;
	@:op(A > B) static function intGt(a:Int, b:Flush):Bool;
	@:op(A > B) static function gtFloat(a:Flush, b:Float):Bool;
	@:op(A > B) static function floatGt(a:Float, b:Flush):Bool;

	@:op(A >= B) static function gte(a:Flush, b:Flush):Bool;
	@:op(A >= B) static function gteInt(a:Flush, b:Int):Bool;
	@:op(A >= B) static function intGte(a:Int, b:Flush):Bool;
	@:op(A >= B) static function gteFloat(a:Flush, b:Float):Bool;
	@:op(A >= B) static function floatGte(a:Float, b:Flush):Bool;
}

/* Return codes for the compression/decompression functions. Negative values
* are errors, positive values are used for special but normal events.
*/
@:enum abstract ErrorStatus(Int) to Int
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

//NOTE(hx): check recursion and inline behaviour in abstract with comparison functions (CompressionLevel and Strategy)

/* compression levels */
abstract CompressionLevel(Int) to Int
{
  static public inline var Z_NO_COMPRESSION =         0;
  static public inline var Z_BEST_SPEED =             1;
  static public inline var Z_BEST_COMPRESSION =       9;
  static public inline var Z_DEFAULT_COMPRESSION =   -1;
  
  @:from static function fromInt(i:Int) {
    if (i < Z_DEFAULT_COMPRESSION || i > Z_BEST_COMPRESSION) throw "Invalid CompressionLevel!";
    return cast i;
  }
	
  // forward comparison operators
  @:op(A == B) static function eq(a:CompressionLevel, b:CompressionLevel):Bool;
	@:op(A == B) @:commutative static function eqInt(a:CompressionLevel, b:Int):Bool;
	@:op(A == B) @:commutative static function eqFloat(a:CompressionLevel, b:Float):Bool;

	@:op(A != B) static function neq(a:CompressionLevel, b:CompressionLevel):Bool;
	@:op(A != B) @:commutative static function neqInt(a:CompressionLevel, b:Int):Bool;
	@:op(A != B) @:commutative static function neqFloat(a:CompressionLevel, b:Float):Bool;

	@:op(A < B) static function lt(a:CompressionLevel, b:CompressionLevel):Bool;
	@:op(A < B) static function ltInt(a:CompressionLevel, b:Int):Bool;
	@:op(A < B) static function intLt(a:Int, b:CompressionLevel):Bool;
	@:op(A < B) static function ltFloat(a:CompressionLevel, b:Float):Bool;
	@:op(A < B) static function floatLt(a:Float, b:CompressionLevel):Bool;

	@:op(A <= B) static function lte(a:CompressionLevel, b:CompressionLevel):Bool;
	@:op(A <= B) static function lteInt(a:CompressionLevel, b:Int):Bool;
	@:op(A <= B) static function intLte(a:Int, b:CompressionLevel):Bool;
	@:op(A <= B) static function lteFloat(a:CompressionLevel, b:Float):Bool;
	@:op(A <= B) static function floatLte(a:Float, b:CompressionLevel):Bool;

	@:op(A > B) static function gt(a:CompressionLevel, b:CompressionLevel):Bool;
	@:op(A > B) static function gtInt(a:CompressionLevel, b:Int):Bool;
	@:op(A > B) static function intGt(a:Int, b:CompressionLevel):Bool;
	@:op(A > B) static function gtFloat(a:CompressionLevel, b:Float):Bool;
	@:op(A > B) static function floatGt(a:Float, b:CompressionLevel):Bool;

	@:op(A >= B) static function gte(a:CompressionLevel, b:CompressionLevel):Bool;
	@:op(A >= B) static function gteInt(a:CompressionLevel, b:Int):Bool;
	@:op(A >= B) static function intGte(a:Int, b:CompressionLevel):Bool;
	@:op(A >= B) static function gteFloat(a:CompressionLevel, b:Float):Bool;
	@:op(A >= B) static function floatGte(a:Float, b:CompressionLevel):Bool;
}

@:enum abstract Strategy(Int) to Int
{
  var Z_FILTERED =               1;
  var Z_HUFFMAN_ONLY =           2;
  var Z_RLE =                    3;
  var Z_FIXED =                  4;
  var Z_DEFAULT_STRATEGY =       0;
	
  // forward comparison operators
  @:op(A == B) static function eq(a:Strategy, b:Strategy):Bool;
	@:op(A == B) @:commutative static function eqInt(a:Strategy, b:Int):Bool;
	@:op(A == B) @:commutative static function eqFloat(a:Strategy, b:Float):Bool;

	@:op(A != B) static function neq(a:Strategy, b:Strategy):Bool;
	@:op(A != B) @:commutative static function neqInt(a:Strategy, b:Int):Bool;
	@:op(A != B) @:commutative static function neqFloat(a:Strategy, b:Float):Bool;

	@:op(A < B) static function lt(a:Strategy, b:Strategy):Bool;
	@:op(A < B) static function ltInt(a:Strategy, b:Int):Bool;
	@:op(A < B) static function intLt(a:Int, b:Strategy):Bool;
	@:op(A < B) static function ltFloat(a:Strategy, b:Float):Bool;
	@:op(A < B) static function floatLt(a:Float, b:Strategy):Bool;

	@:op(A <= B) static function lte(a:Strategy, b:Strategy):Bool;
	@:op(A <= B) static function lteInt(a:Strategy, b:Int):Bool;
	@:op(A <= B) static function intLte(a:Int, b:Strategy):Bool;
	@:op(A <= B) static function lteFloat(a:Strategy, b:Float):Bool;
	@:op(A <= B) static function floatLte(a:Float, b:Strategy):Bool;

	@:op(A > B) static function gt(a:Strategy, b:Strategy):Bool;
	@:op(A > B) static function gtInt(a:Strategy, b:Int):Bool;
	@:op(A > B) static function intGt(a:Int, b:Strategy):Bool;
	@:op(A > B) static function gtFloat(a:Strategy, b:Float):Bool;
	@:op(A > B) static function floatGt(a:Float, b:Strategy):Bool;

	@:op(A >= B) static function gte(a:Strategy, b:Strategy):Bool;
	@:op(A >= B) static function gteInt(a:Strategy, b:Int):Bool;
	@:op(A >= B) static function intGte(a:Int, b:Strategy):Bool;
	@:op(A >= B) static function gteFloat(a:Strategy, b:Float):Bool;
	@:op(A >= B) static function floatGte(a:Float, b:Strategy):Bool;
}

/* Possible values of the data_type field (though see inflate()) */
@:enum abstract DataType(Int) from Int
{
  var Z_BINARY =                 0;
  var Z_TEXT =                   1;
  //var Z_ASCII =                1; // = Z_TEXT (deprecated)
  var Z_UNKNOWN =                2;
}

/* The deflate compression method */
@:enum abstract Method(Int) to Int
{
  var Z_DEFLATED =               8;
  //var Z_NULL =                 null; // Use -1 or null inline, depending on var type
  
	@:op(A + B) @:commutative static function addInt(a:Method, b:Int):Int;  
}
