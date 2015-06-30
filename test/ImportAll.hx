package;

import pako.zlib.Adler32;
import pako.zlib.Constants;
import pako.zlib.Constants.Error;
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


class ImportAll
{
	static public function main() {
    var zs = new ZStream();
    var gzhdr = new GZHeader();
    trace(Messages.get(Error.Z_NEED_DICT));
	}
}