package levelord.tools.timeline;
import levelord.model.animation.Animation;
import levelord.model.animation.ScriptKey;
import levelord.tools.Timeline;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
/**
 * ...
 * @author Andreas Rønning
 */
class ScriptChannel extends Channel
{
	var animation:Animation = null;
	public var tl:Timeline;
	public function new(tl:Timeline) 
	{
		super();
		this.tl = tl;
		cdata.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick, false, 0, true);
		cdata.doubleClickEnabled = true;
	}
	
	function onDoubleClick(e:MouseEvent) 
	{
		trace("Double click!");
		tl.createScript();
	}
	override public function drawTarget(min, max) 
	{
		var g:Graphics = cdata.keyGraphics;
		g.clear();
		g.beginFill(0x111111);
		g.drawRect(0, 0, cdata.size, 20);
		if (animation == null) return;
		for (s in animation.scripts) 
		{
			if (s.time < min||s.time>max) continue;
			g.beginFill(s.selected?0xFFFFFF:0x808080);
			var p = (s.time-min) / (max - min);
			g.drawRect(p * cdata.size-8, 2, 16, 16);
			g.endFill();
		}
		
	}
	public function populate(a:Animation) {
		this.animation = a;
	}
	
}