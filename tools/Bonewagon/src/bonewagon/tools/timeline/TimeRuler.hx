package bonewagon.tools.timeline;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
/**
 * ...
 * @author Andreas Rønning
 */
class TimeRuler extends Sprite
{
	public var max:TextField;
	public var min:TextField;
	public var current:TextField;
	public var mouse:TextField;
	
	public function new() 
	{
		super();
		var tf:TextFormat = new TextFormat("_sans", 10, 0xbbbbbb);
		var t2:TextFormat = new TextFormat("_sans", 10, 0xbbbbbb,null,null,null,null,null,TextFormatAlign.RIGHT);
		var t3:TextFormat = new TextFormat("_sans", 10, 0xbbbbbb,null,null,null,null,null,TextFormatAlign.CENTER);
		min = new TextField();
		addChild(min);
		max = new TextField();
		addChild(max);
		current = new TextField();
		addChild(current);
		mouse = new TextField();
		addChild(mouse);
		min.x = 60;
		min.defaultTextFormat = tf;
		max.defaultTextFormat = t2;
		current.defaultTextFormat = mouse.defaultTextFormat = t3;
		mouseEnabled = mouseChildren = false;
	}
	public function redraw() {
		min.x = 60;
		max.x = stage.stageWidth - max.width-10;
		current.x = stage.stageWidth / 2 - current.width / 2;
	}
	
}