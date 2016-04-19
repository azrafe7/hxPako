package;

import haxe.CallStack.StackItem;
import haxe.Timer;
import promhx.Deferred;
import promhx.Promise;

import buddy.reporting.Reporter;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.BuddySuite.SpecStatus;

using Lambda;
using StringTools;

#if nodejs
import buddy.internal.sys.NodeJs;
private typedef Sys = NodeJs;
#elseif js
import buddy.internal.sys.Js;
private typedef Sys = Js;
#elseif flash
import buddy.internal.sys.Flash;
private typedef Sys = Flash;
#end


/** A mocha-like reporter (with timings) */
class MochaReporter implements Reporter
{
#if php
    var cli : Bool;
#end

    var startTime:Float;
    var overallProgress:StringBuf;
  
    public var timings:Map<Spec, Float>;
  
	
    public function new() {}

	public function start()
	{
		// A small convenience for PHP, to avoid creating a new reporter.
    #if php
		cli = (untyped __call__("php_sapi_name")) == 'cli';
		if(!cli) println("<pre>");
    #end

        startTime = Timer.stamp();
        timings = new Map();
        overallProgress = new StringBuf();
    
		return resolveImmediately(true);
	}

	public function progress(spec:Spec)
	{
        var elapsed = Timer.stamp() - startTime;
        elapsed = Std.int(elapsed * 1000) / 1000;
        timings[spec] = elapsed;
        startTime = Timer.stamp();
    
		print(switch(spec.status) {
			case SpecStatus.Failed: "X";
			case SpecStatus.Passed: ".";
			case SpecStatus.Pending: "P";
			case SpecStatus.Unknown: "?";
		});

		return resolveImmediately(spec);
	}

	public function done(suites : Iterable<Suite>, status : Bool)
	{
    
    #if js
        println(overallProgress.toString());
    #end
  
        println();

		var total = 0;
		var failures = 0;
		var successes = 0;
		var pending = 0;
		var unknowns = 0;

		var countTests : Suite -> Void = null;
		var printTests : Suite -> Int -> Void = null;

		countTests = function(s : Suite) {
			for (sp in s.steps) switch sp {
				case TSpec(sp):
					total++;
					if (sp.status == SpecStatus.Failed) failures++;
					if (sp.status == SpecStatus.Passed) successes++;
					else if (sp.status == SpecStatus.Pending) pending++;
				case TSuite(s):
					countTests(s);
			}
		};

		suites.iter(countTests);

		printTests = function(s : Suite, indentLevel : Int) {
			var printIndent = function(str : String) println(str.lpad(" ", str.length + (indentLevel + 1) * 2));

            var statusToStr = function(status : SpecStatus) {
                return switch (status) {
                    case SpecStatus.Failed:  "[FAIL]";
                    case SpecStatus.Passed:  "[ OK ]";
                    case SpecStatus.Pending: "[PEND]";
                    case SpecStatus.Unknown: "[ ?? ]";
                }
            }

			function printStack(stack : Array<StackItem>) {
				if (stack == null || stack.length == 0) return;
				for (s in stack) switch s {
					case FilePos(_, file, line) if (line > 0 && file.indexOf("buddy/internal/") != 0):
						printIndent('    @ $file:$line');
					case _:
				}
			}
			
			function printTraces(spec : Spec) {
				for (t in spec.traces) printIndent("    " + t);
			}
            
            println();
			if (s.description.length > 0) printIndent(s.description);
			
			if (s.error != null) {
				// The whole suite crashed.
				printIndent("ERROR: " + s.error);
				printStack(s.stack);
				return;
			}

			for (step in s.steps) switch step
			{
				case TSpec(sp):
					if (sp.status == SpecStatus.Failed)
					{
						printIndent("  " + statusToStr(sp.status) + " " + sp.description + " (ERROR: " + sp.error + ")" + "  (" + timings[sp] + "s)");
						printTraces(sp);
                        printStack(sp.stack);
					}
					else
					{
						printIndent("  " + statusToStr(sp.status) + " " + sp.description + "  (" + timings[sp] + "s)");
						printTraces(sp);
					}
				case TSuite(s):
					printTests(s, indentLevel + 2);
			}
		};

		suites.iter(printTests.bind(_, -1));

        println();
		println('$total specs, $successes passed, $failures failed, $pending pending');

        var totalTime:Float = .0;
        for (t in timings) totalTime += t;
        totalTime = Std.int(totalTime * 1000) / 1000;
        println("total time: " + totalTime + "s");
		println();
    
    #if php
		if(!cli) println("</pre>");
    #end

        return resolveImmediately(suites);
	}

	private function print(s : String)
	{
	#if js
        overallProgress.add(s);
    #else
        Sys.print(s);
    #end
	}

	private function println(s : String = "")
	{
    #if js
		untyped __js__("console.log(s)");
    #else
        Sys.println(s);
    #end
	}

	private function resolveImmediately<T>(o : T) : Promise<T>
	{
		var def = new Deferred<T>();
		var pr = def.promise();
		def.resolve(o);
		return pr;
	}
}