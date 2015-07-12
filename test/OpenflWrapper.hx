package;

import flash.events.KeyboardEvent;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;
import haxe.Timer;

class OpenflWrapper extends Sprite
{ 
#if (cpp && telemetry)
  public var hxt:hxtelemetry.HxTelemetry;
  public var frames:Int = 0;
#end

  public function new() {
    super();
    
  #if (cpp && telemetry)
    var cfg = new hxtelemetry.HxTelemetry.Config();
    cfg.allocations = false;
    hxt = new hxtelemetry.HxTelemetry(cfg);
    hxt.advance_frame();
    frames++;
    trace("first frame");
  #end
  
    Lib.current.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    
  #if !flash
    var text = new TextField();
    text.width = 200;
    text.text = "Testing (look at the console for results)...";
    text.autoSize = TextFieldAutoSize.LEFT;
    
    addChild(text);
  #end
  
    // delayed so we have time to append the textfield
    Timer.delay(Main.main, 100);
  }
  
  function onEnterFrame(event:Event): Void {
  #if (cpp && telemetry)
    if (frames < 100) {
      hxt.advance_frame();
      frames++;
    }
  #end
  }
	
  function onKeyDown(event:KeyboardEvent):Void {
		if (event.keyCode == 27) {  // ESC
    #if (cpp && telemetry)
      trace("frames: " + frames);
    #end
    
    #if flash
      flash.system.System.exit(0);
    #elseif sys
      Sys.exit(0);
    #end
		}
	}
}