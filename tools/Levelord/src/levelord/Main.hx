package levelord;
import flash.desktop.NativeApplication;
import flash.display.Sprite;
import flash.events.Event;
import flash.Lib;

using Lambda;

/**
 * ...
 * @author Andreas Rønning
 */
class Main extends Sprite 
{
	
	public static function main() {
		Lib.current.stage.addChild(new Main());
	}
	
	public function new() 
	{
		super();
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}
	
	private function onAddedToStage(e:Event):Void 
	{
	
	}
	
	function onWindowClosing(e:Event) 
	{
		NativeApplication.nativeApplication.exit(0);
	}
	
}