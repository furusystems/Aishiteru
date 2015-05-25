package levelord.tools.timeline;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
/**
 * ...
 * @author Andreas Rønning
 */
class ChannelData extends Sprite
{
	var keys:Shape = new Shape();
	public var keyGraphics:Graphics;
	public var size = 0;
	public function new() 
	{
		super();
		addChild(keys);
		keyGraphics = keys.graphics;
	}
	public function setSize(w) {
		size = w;
		graphics.clear();
		graphics.lineStyle(0, 0);
		graphics.beginFill(0x333333);
		graphics.drawRect(0, 0, w, 20);
	}
	
}