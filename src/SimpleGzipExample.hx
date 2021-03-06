import haxe.io.Bytes;
import haxe.io.Path;
import haxe.io.UInt8Array;
import pako.Deflate;
import pako.Pako;
import pako.zlib.GZHeader;
import pako.zlib.Constants;


class SimpleGzipExample {

    static public function main() {
    #if (!(sys || nodejs))
        exitWithUsage();
    #else

        var sysArgs = Sys.args();

        if (sysArgs.length < 1) {
            exitWithUsage();
        } else {
            var inputFile = sysArgs[0];
            if (!sys.FileSystem.exists(inputFile) || sys.FileSystem.isDirectory(inputFile)) {
                Sys.println('\n  Input file not found "$inputFile"');
                exitWithUsage();
            }

            var input = sys.io.File.getBytes(inputFile);
            var inputPath = new Path(inputFile);
            Sys.println('\n  Processing "${inputPath.toString()}"');
            var programDir = Path.directory(Sys.programPath());
            var outputFile = Path.join([programDir, inputPath.file + "." + inputPath.ext + ".gz"]);

            var gzipHeader = new GZHeader();
            gzipHeader.comment = 'created with hxPako (${Date.now().toString()})';
            Sys.println('\n  Gzipping bytes to "${outputFile}"');
            Sys.println('\n  (with comment: "${gzipHeader.comment}")');

            var options = { gzip:true, header:gzipHeader };
            var deflator = new Deflate(options);

            deflator.push(UInt8Array.fromBytes(input), true);

            if (deflator.err != ErrorStatus.Z_OK) {
              Sys.println('\n  ERROR(${deflator.err}): ${deflator.msg}');
              Sys.exit(deflator.err);
            }

            var output = deflator.result;

            sys.io.File.saveBytes(outputFile, output.view.buffer);
        }

    #end
    }

    static public function exitWithUsage() {
    #if (!(sys || nodejs))
        trace("This target doesn't support reading/writing files!");
    #else
        var executablePath = new Path(Sys.programPath());
        var programName = executablePath.file + "." + executablePath.ext;
        Sys.println('\n  Usage: $programName file.ext');
        Sys.exit(0);
    #end
    }

}