package com.furusystems.games.editors.tools.timeline 
{
	import com.furusystems.games.editors.model.animation.Animation;
	import com.furusystems.games.editors.model.animation.ScriptKey;
	import com.furusystems.games.editors.tools.Timeline;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ScriptChannel extends Channel
	{
		private var animation:Animation = null;
		public var tl:Timeline;
		public function ScriptChannel(tl:Timeline) 
		{
			super();
			this.tl = tl;
			cdata.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClick, false, 0, true);
			cdata.doubleClickEnabled = true;
		}
		
		private function onDoubleClick(e:MouseEvent):void 
		{
			trace("Double click!");
			tl.createScript();
		}
		override public function drawTarget(min:Number, max:Number):void 
		{
			var g:Graphics = cdata.keyGraphics;
			g.clear();
			g.beginFill(0x111111);
			g.drawRect(0, 0, cdata.size, 20);
			if (animation == null) return;
			for (var i:int = 0; i < animation.scripts.length; i++) 
			{
				var s:ScriptKey = animation.scripts[i];
				if (s.time < min||s.time>max) continue;
				g.beginFill(s.selected?0xFFFFFF:0x808080);
				var p:Number = (s.time-min) / (max - min);
				g.drawRect(p * cdata.size-8, 2, 16, 16);
				g.endFill();
			}
			
		}
		public function populate(a:Animation):void {
			this.animation = a;
		}
		
	}

}