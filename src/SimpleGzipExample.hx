import haxe.io.Bytes;
import haxe.io.Path;
import haxe.io.UInt8Array;
import pako.Pako;
import pako.zlib.GZHeader;

#if (sys)
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
#end


class SimpleGzipExample {
    
    static public function main() {
    #if (!sys) 
        exitWithUsage();
    #else
    
        var sysArgs = Sys.args();
        
        if (sysArgs.length != 1) {
            exitWithUsage();
        } else {
            var inputFile = sysArgs[0];
            if (!sys.FileSystem.exists(inputFile) || sys.FileSystem.isDirectory(inputFile)) {
                Sys.println('\n  Input file not found "$inputFile"');
                exitWithUsage();
            }
            
            var input = File.getBytes(inputFile);
            var inputPath = new Path(inputFile);
            Sys.println('\n  Processing "${inputPath.toString()}"');
            var programDir = Path.directory(Sys.programPath());
            var outputFile = Path.join([programDir, inputPath.file + "." + inputPath.ext + ".gz"]);
            
            var gzipHeader = new GZHeader();
            gzipHeader.comment = 'created with hxPako (${Date.now().toString()})';
            var output = Pako.deflate(UInt8Array.fromBytes(input), {gzip:true, header:gzipHeader});
            Sys.println('\n  Gzip bytes to "${outputFile}"');
            Sys.println('\n  (added comment: "${gzipHeader.comment}"');
            File.saveBytes(outputFile, output.view.buffer);
        }
        
    #end
    }
    
    static public function exitWithUsage() {
    #if (!sys)
        trace("Not supported on non-sys targets!");
    #else
        var executablePath = new Path(Sys.programPath());
        var programName = executablePath.file + "." + executablePath.ext;
        Sys.println('\n  Usage: $programName file.ext');
        Sys.exit(0);
    #end
    }
    
}