package com.furusystems.tilesheeter.canvas 
{
	import flash.display.BitmapData;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Subtexture 
	{
		public var bmd:BitmapData;
		public var name:String = "";
		
		public function Subtexture(bmd:BitmapData) 
		{
			this.bmd = bmd;
			name = bmd.width+"";
			if (bmd.width != bmd.height) name = bmd.width + "x" + bmd.height + "(NPT)";
		}
		
	}

}