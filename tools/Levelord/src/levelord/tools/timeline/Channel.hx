package levelord.tools.timeline;
import levelord.model.animation.AnimationTarget;
import levelord.model.animation.SRT;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.text.AutoCapitalize;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
/**
 * ...
 * @author Andreas Rønning
 */
class Channel extends Sprite
{
	public var color:Int = cast( Math.random() * 0xFFFFFF);
	public var target:AnimationTarget = null;
	public var cname:ChannelName = new ChannelName();
	public var cdata:ChannelData = new ChannelData();
	public function new() 
	{
		super();
		addChild(cname);
		addChild(cdata);
	}
	public function setSize(w) {
		cdata.x = 60;
		cdata.setSize(w - 60);
	}
	public function dispose() {
		target = null;
		parent.removeChild(this);
	}
	
	public function drawTarget(min, max) 
	{
		var g:Graphics = cdata.keyGraphics;
		g.clear();
		if (target == null) return;
		for (s in target.srts) 
		{
			if (s.time < min||s.time>max) continue;
			g.beginFill(s.selected?0xFFFFFF:0x808080);
			var p = (s.time-min) / (max - min);
			switch(s.easing) {
				case 0:
					g.drawRect(p * cdata.size-8, 2, 16, 16);
				case 1:
					g.drawCircle(p * cdata.size, 10, 8);
					g.endFill();
					g.beginFill(s.selected?0xFFFFFF:0x808080);
					g.drawRect(p * cdata.size, 2, 8, 16);
				case 2:
					g.drawCircle(p * cdata.size, 10, 8);
					g.endFill();
					g.beginFill(s.selected?0xFFFFFF:0x808080);
					g.drawRect(p * cdata.size-8, 2, 8, 16);
				case 3:
					g.drawCircle(p * cdata.size, 10, 8);
			}
			g.endFill();
		}	
	}
	
}