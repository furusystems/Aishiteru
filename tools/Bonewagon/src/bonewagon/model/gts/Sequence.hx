package bonewagon.model.gts;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxe.Json;
/**
 * ...
 * @author Andreas Rønning
 */
class Sequence 
{
	public static inline var NONE:Int = -1;
	public static inline var CIRCLE:Int = 0;
	public static inline var RECT:Int = 1;
	
	public var name:String = "";
	public var tiles:Array<Tile> = new Array<Tile>();
	public var color:Int;
	public var frameRate = 30;
	public var looping:Bool = false;
	public var hitbox:Rectangle = new Rectangle();
	public var hitcircle = 0;
	public var hitAreaType:Int = NONE;
	static var idxPool:Int = 0;
	public function new(name:String = "") 
	{
		if (name == "") name = "Sequence" + (idxPool++);
		color = cast (Math.random() * 0xFFFFFF);
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
		return Json.stringify(getObject());
	}
	
	public function getObject():Dynamic {
		if (tiles.length == 0) return null;
		var out:Dynamic = { };
		out.name = name;
		out.tiles = [];
		out.looping = looping;
		out.framerate = frameRate;
		out.hitareatype = hitAreaType;
		switch(hitAreaType) {
			case CIRCLE:
				out.radius = hitcircle;
			case RECT:
				out.hitbox = { };
				out.hitbox.width = hitbox.width;
				out.hitbox.height = hitbox.height;
		}
		for (t in tiles) {
			out.tiles.push(t.getObject());
		}
		
		out.bounds = { };
		var bt:Tile = getBiggestFrame();
		out.bounds.width = bt.width;
		out.bounds.height = bt.height;
		return out;
	}
	
	function getBiggestFrame():Tile 
	{
		trace("Get biggest frame");
		var t:Tile = null;
		var biggest = new Point(0, 0);
		for(t2 in tiles) {
			trace(t2.size.length, biggest.length);
			if (t2.size.length > biggest.length) {
				biggest = t2.size;
				t = t2;
			}
		}
		return t == null?tiles[0]:t;
	}
	
	static public function fromObject(ob:Dynamic):Sequence 
	{
		var out:Sequence = new Sequence(ob.name);
		out.frameRate = ob.framerate;
		out.looping = ob.looping;
		
		out.hitAreaType = ob.hitareatype == null?NONE:ob.hitareatype;
		switch(out.hitAreaType) {
			case CIRCLE:
				out.hitcircle = ob.radius;
			case RECT:
				out.hitbox.width = ob.hitbox.width;
				out.hitbox.height = ob.hitbox.height;
		}
		
		for (i in 0...ob.tiles.length) {
			var o = ob.tiles[i];
			var t:Tile = out.addTile(new Rectangle(o.rect.x, o.rect.y, o.rect.width, o.rect.height));
			t.center.x = o.center.x;
			t.center.y = o.center.y;
		}
		return out;
	}
	
}