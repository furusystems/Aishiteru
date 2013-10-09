package com.furusystems.games.editors.tools.timeline 
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ChannelData extends Sprite
	{
		private var keys:Shape = new Shape();
		public var keyGraphics:Graphics = keys.graphics;
		public var size:Number = 0;
		public function ChannelData() 
		{
			addChild(keys);
		}
		public function setSize(w:Number):void {
			size = w;
			graphics.clear();
			graphics.lineStyle(0, 0);
			graphics.beginFill(0x333333);
			graphics.drawRect(0, 0, w, 20);
		}
		
	}

}