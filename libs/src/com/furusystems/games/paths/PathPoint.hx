package com.furusystems.games.paths;

import flash.geom.Point;

/**
 * ...
 * @author Andreas Rønning
 */

class PathPoint extends Point
{
	public var time:Float;
	public var angle:Float;
	public function new(time:Float = 0,x:Float = 0,y:Float = 0,angle:Float = 0) 
	{
		super(x, y);
		this.time = time;
	}
	override public function clone():PathPoint {
		return new PathPoint(time, x, y, angle);
	}
	
}