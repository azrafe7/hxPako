import haxe.io.Bytes;
import haxe.io.Path;
import haxe.io.UInt8Array;
import pako.Inflate;
import pako.Pako;
import pako.zlib.GZHeader;
import pako.zlib.Constants;


class SimpleUngzipExample {

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
            var outputFile = Path.join([programDir, inputPath.file + ".ungzipped"]);

            // using inflator to extract comments too (otherwise Pako.inflate() is sufficient to get the bytes back)
            var inflator = new Inflate();

            Sys.println('\n  Ungzipping bytes to "${outputFile}"');
            inflator.push(UInt8Array.fromBytes(input), true);

            if (inflator.err != ErrorStatus.Z_OK) {
              Sys.println('\n  ERROR(${inflator.err}): ${inflator.msg}');
              Sys.exit(inflator.err);
            }

            var output = inflator.result;

            sys.io.File.saveBytes(outputFile, output.view.buffer);
            var comment = inflator.header.comment;
            if (comment != null && comment != "") Sys.println('\n  (extracted comment: "${inflator.header.comment}")');
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