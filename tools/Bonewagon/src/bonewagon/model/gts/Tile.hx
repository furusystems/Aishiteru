package bonewagon.model.gts;
import flash.geom.Point;
import flash.geom.Rectangle;
import haxe.Json;
/**
 * ...
 * @author Andreas Rønning
 */
class Tile extends Rectangle
{
	public var center:Point = new Point();
	public function new() 
	{
		super();
	}
	public function makeCenter():Point {
		center.x = width / 2;
		center.y = height / 2;
		return center;
	}
	
	public function getJson():String 
	{
		return Json.stringify(getObject());
	}
	
	public function getObject():Dynamic 
	{
		var out:Dynamic = { };
		out.center = { x:center.x,y:center.y};
		out.rect = { x:x, y:y, width:width, height:height };
		return out;
	}
	
}