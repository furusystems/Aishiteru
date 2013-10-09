package com.furusystems.games.editors.tools.timeline 
{
	import com.furusystems.games.editors.model.animation.AnimationTarget;
	import com.furusystems.games.editors.model.animation.SRT;
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
	public class Channel extends Sprite
	{
		public var color:uint = Math.random() * 0xFFFFFF;
		public var target:AnimationTarget = null;
		public var cname:ChannelName = new ChannelName();
		public var cdata:ChannelData = new ChannelData();
		public function Channel() 
		{
			addChild(cname);
			addChild(cdata);
		}
		public function setSize(w:Number):void {
			cdata.x = 60;
			cdata.setSize(w - 60);
		}
		public function dispose():void {
			target = null;
			parent.removeChild(this);
		}
		
		public function drawTarget(min:Number, max:Number):void 
		{
			var g:Graphics = cdata.keyGraphics;
			g.clear();
			if (target == null) return;
			for (var i:int = 0; i < target.srts.length; i++) 
			{
				var s:SRT = target.srts[i];
				if (s.time < min||s.time>max) continue;
				g.beginFill(s.selected?0xFFFFFF:0x808080);
				var p:Number = (s.time-min) / (max - min);
				switch(s.easing) {
					case 0:
						g.drawRect(p * cdata.size-8, 2, 16, 16);
						break;
					case 1:
						g.drawCircle(p * cdata.size, 10, 8);
						g.endFill();
						g.beginFill(s.selected?0xFFFFFF:0x808080);
						g.drawRect(p * cdata.size, 2, 8, 16);
						break;
					case 2:
						g.drawCircle(p * cdata.size, 10, 8);
						g.endFill();
						g.beginFill(s.selected?0xFFFFFF:0x808080);
						g.drawRect(p * cdata.size-8, 2, 8, 16);
						break;
					case 3:
						g.drawCircle(p * cdata.size, 10, 8);
						break;
				}
				g.endFill();
			}	
		}
		
	}

}