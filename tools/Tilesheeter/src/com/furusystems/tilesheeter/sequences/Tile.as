package com.furusystems.tilesheeter.sequences 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Tile extends Rectangle
	{
		public var center:Point = new Point();
		public function Tile() 
		{
			
		}
		public function makeCenter():Point {
			center.x = width / 2;
			center.y = height / 2;
			return center;
		}
		
		public function getJson():String 
		{
			return JSON.stringify(getObject());
		}
		
		public function getObject():Object 
		{
			var out:Object = { };
			out.center = { x:center.x,y:center.y};
			out.rect = { x:x, y:y, width:width, height:height };
			return out;
		}
		
	}

}