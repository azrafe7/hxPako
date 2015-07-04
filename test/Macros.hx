/****
* Copyright (c) 2013 Jason O'Neil
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
* 
****/

package ;

import ds.TSTree;
import haxe.macro.Context;
import haxe.macro.Expr.ExprOf;
import haxe.Serializer;

using StringTools;

/**
 * From https://github.com/jasononeil/compiletime/blob/master/src/CompileTime.hx
 * 
 * @author jasononeil
 */
class Macros
{
    /** Reads a file at compile time, and inserts the contents into your code as a string.  The file path is resolved using `Context.resolvePath`, so it will search all your class paths */
    macro public static function readFile(path:String):ExprOf<String> {
        return toExpr(loadFileAsString(path));
    }
	
    macro public static function readAndSplit(path:String):ExprOf<Array<String>> {
        return toExpr(loadFileAsString(path).split("\r\n"));
    }
	
#if macro
	static function toExpr(v:Dynamic) {
		return Context.makeExpr(v, Context.currentPos());
	}
	
	static function loadFileAsString(path:String) {
		try {
			var p = Context.resolvePath(path);
			Context.registerModuleDependency(Context.getLocalModule(),p);
			return sys.io.File.getContent(p);
		} 
		catch(e:Dynamic) {
			return haxe.macro.Context.error('Failed to load file $path: $e', Context.currentPos());
		}
	}
#end
}