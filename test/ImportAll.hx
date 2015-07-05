package;

import haxe.io.Path;
import haxe.io.UInt8Array;
import haxe.Resource;
import pako.zlib.Adler32;
import pako.zlib.Constants;
import pako.zlib.CRC32;
import pako.zlib.Messages;
import pako.zlib.ZStream;
import pako.zlib.GZHeader;
import pako.zlib.InfTrees;
import pako.zlib.Trees;
import pako.zlib.Deflate;
import pako.zlib.InfFast;
import pako.zlib.Inflate;
import pako.Deflate;
import pako.Inflate;
#if sys
import sys.io.File;
#end
import Helpers;

class ImportAll
{
	static public function main() {
		
  #if flash
    flash.Lib.current.stage.addEventListener(flash.events.KeyboardEvent.KEY_DOWN, onKeyDown);
  #end
  
    var zs = new ZStream();
    var gzhdr = new GZHeader();
    trace(Messages.get(ErrorStatus.Z_NEED_DICT));
    
  #if sys
    trace("...");
    //var input = Sys.stdin().readLine();
  #end
    
    misc();
    quit();
	}
  
  static public function misc():Void {
    
    var file   = Path.join(["./", 'fixtures/samples/lorem_utf_100k.txt']);
  
  #if sys
    var bytes = File.getBytes(file);
  #else
    var bytes = Resource.getBytes('lorem_utf_100k.txt');
  #end
    
    trace(bytes.length);
  
    var sample = UInt8Array.fromBytes(bytes);
    trace(bytes.length, sample.length);
    var deflated = Deflate.deflate(sample);

    trace('Deflate ArrayBuffer ' + deflated.length);
    trace(Helpers.cmpBuf(deflated, Deflate.deflate(sample)));

    trace('Inflate ArrayBuffer');
    trace(Helpers.cmpBuf(sample, Inflate.inflate(deflated)));
  }
	
#if flash
  static function onKeyDown(event:flash.events.KeyboardEvent):Void
	{
		if (event.keyCode == 27) quit(); // ESC
	}
#end

  static function quit() {
  #if flash
    flash.system.System.exit(0);
  #elseif sys
    Sys.exit(0);
  #end
  }
}