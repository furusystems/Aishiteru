package com.furusystems.tilesheeter.sequences 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Sequence 
	{
		public static const NONE:int = -1;
		public static const CIRCLE:int = 0;
		public static const RECT:int = 1;
		public var name:String = "";
		public var tiles:Vector.<Tile> = new Vector.<Tile>();
		public var color:uint;
		public var frameRate:Number = 30;
		public var looping:Boolean = false;
		public var hitbox:Rectangle = new Rectangle();
		public var hitcircle:Number = 0;
		public var hitAreaType:int = NONE;
		private static var idxPool:int = 0;
		public function Sequence(name:String = "") 
		{
			if (name == "") name = "Sequence" + (idxPool++);
			color = Math.random() * 0xFFFFFF;
			this.name = name;
		}
		public function addTile(rect:Rectangle):Tile {
			var t:Tile = new Tile();
			t.x = rect.x;
			t.y = rect.y;
			t.width = rect.width;
			t.height = rect.height;
			t.makeCenter();
			tiles.push(t);
			return t;
		}
		
		public function getJson():String 
		{
			return JSON.stringify(getObject());
		}
		public function getObject():Object {
			if (tiles.length == 0) return null;
			var out:Object = { };
			out.name = name;
			out.tiles = [];
			out.looping = looping;
			out.framerate = frameRate;
			out.hitareatype = hitAreaType;
			switch(hitAreaType) {
				case CIRCLE:
					out.radius = hitcircle;
					break;
				case RECT:
					out.hitbox = { };
					out.hitbox.width = hitbox.width;
					out.hitbox.height = hitbox.height;
					break;
			}
			for (var i:int = 0; i < tiles.length; i++) {
				out.tiles.push(tiles[i].getObject());
			}
			
			out.bounds = { };
			var bt:Tile = getBiggestFrame();
			out.bounds.width = bt.width;
			out.bounds.height = bt.height;
			return out;
		}
		
		private function getBiggestFrame():Tile 
		{
			trace("Get biggest frame");
			var t:Tile;
			var biggest:Point = new Point(0, 0);
			for each(var t2:Tile in tiles) {
				trace(t2.size.length, biggest.length);
				if (t2.size.length > biggest.length) {
					biggest = t2.size;
					t = t2;
				}
			}
			return t == null?tiles[0]:t;
		}
		
		static public function fromObject(ob:Object):Sequence 
		{
			var out:Sequence = new Sequence(ob.name);
			out.frameRate = ob.framerate;
			out.looping = ob.looping;
			
			trace("From object: "+ob.hitareatype);
			out.hitAreaType = ob.hitareatype == undefined?NONE:ob.hitareatype;
			trace("Hit area type: " + out.hitAreaType);
			switch(out.hitAreaType) {
				case CIRCLE:
					out.hitcircle = ob.radius;
					break;
				case RECT:
					out.hitbox.width = ob.hitbox.width;
					out.hitbox.height = ob.hitbox.height;
					break;
			}
			
			for (var i:int = 0; i < ob.tiles.length; i++) {
				var o:Object = ob.tiles[i];
				var t:Tile = out.addTile(new Rectangle(o.rect.x, o.rect.y, o.rect.width, o.rect.height));
				t.center.x = o.center.x;
				t.center.y = o.center.y;
			}
			return out;
		}
		
	}

}