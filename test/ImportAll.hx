package;

import pako.zlib.Adler32;
import pako.zlib.Constants;
import pako.zlib.Constants.Error;
import pako.zlib.CRC32;
import pako.zlib.Messages;
import pako.zlib.ZStream;
import pako.zlib.GZHeader;
import pako.zlib.InfTrees;

class ImportAll
{
	static public function main() {
    trace(Messages.get(Error.Z_NEED_DICT));
    var zs = new ZStream();
    var gzhdr = new GZHeader();
	}
}