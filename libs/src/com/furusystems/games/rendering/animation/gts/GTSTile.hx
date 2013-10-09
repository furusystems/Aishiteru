package com.furusystems.games.rendering.animation.gts;
import flash.geom.Point;
import flash.geom.Rectangle;

/**
 * ...
 * @author Andreas Rønning
 */

class GTSTile extends Rectangle
{

	public var center:Point;
	public var tileSheetIndex:Int;
	public function new(rect:Rectangle) 
	{
		super();
		center = new Point();
		x = rect.x;
		y = rect.y;
		width = rect.width;
		height = rect.height;
	}
	public function makeCenter():Point {
		center.x = width / 2;
		center.y = height / 2;
		return center;
	}
	
}