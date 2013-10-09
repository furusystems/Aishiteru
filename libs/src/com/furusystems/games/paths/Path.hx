package com.furusystems.games.paths;
import haxe.Json;
import flash.display.Graphics;
import flash.geom.Point;


/**
 * ...
 * @author Andreas Rønning
 */

class Path 
{
	private var maxT:Float;
	private var minT:Float;
	private var points:Array<PathPoint>;
	public var maxTime(get_maxTime, never):Float;
	private function get_maxTime():Float {
		return maxT;
	}
	public function new() 
	{
		clear();
	}
	public function addPoint(x:Float, y:Float, ?time:Float,?angle:Float):Void {
		if (time == null) {
			time = points.length;
		}
		points.push(new PathPoint(time, x, y, angle));
		updateInfo();
	}
	public function clear():Void {
		points = new Array<PathPoint>();
	}
	
	private inline function updateInfo():Void
	{
		points.sort(sortFunc);
		minT = points[0].time;
		maxT = points[points.length - 1].time;
	}
	private function sortFunc(a:PathPoint, b:PathPoint):Int {
		if (a.time < b.time) return -1;
		if (a.time > b.time) return 1;
		return 0;
	}
	public function drawPath(g:Graphics):Void {
		var first:Bool = true;
		for (p in points) {
			if (first) {
				g.moveTo(p.x, p.y);
				first = false;
			}else {
				g.lineStyle(1, 0xFF0000);
				g.lineTo(p.x, p.y);
			}
			g.lineStyle();
			g.beginFill(0x880000);
			g.drawCircle(p.x, p.y, 3);
			g.endFill();
		}
	}
	public function center(copy:Bool = false):Path {
		var pth:Path;
		if (copy) pth = clone();
		else pth = this;
		var x:Float = pth.points[0].x;
		var y:Float = pth.points[0].y;
		for (p in pth.points) {
			p.x -= x;
			p.y -= y;
		}
		return pth;
	}
	public function clone():Path {
		var out:Path = new Path();
		for (p in points) {
			out.points.push(p.clone());
		}
		out.updateInfo();
		return out;
	}
	public function getPoint(time:Float):PathPoint {
		if (points.length == 0) return new PathPoint();
		time = Math.max(minT, Math.min(maxT, time));
		if (points.length == 1||time==0) points[0];
		//bracket
		var first:PathPoint = null;
		var second:PathPoint = null;
		for (idx in 0...points.length) {
			var pt:PathPoint = points[idx];
			if (time <= pt.time) { 
				second = pt;
				first = points[idx-1];
				break;
			}
		}
		var m:Float;
		
		if (first == null || second == null) {
			return points[0];
		}else {
			m = (time-first.time) / (second.time-first.time);
			return new PathPoint(time, first.x + ((second.x - first.x) * m), first.y + ((second.y - first.y) * m), first.angle);
		}
			
		//normalize range
	}
	public function flipVertical(copy:Bool = false):Path {
		var pth:Path;
		if (copy) pth = clone();
		else pth = this;
		
		var medianX:Float = pth.points[0].x;
		var medianY:Float = pth.points[0].y;
		pth.center();
		for (p in pth.points) {
			p.y = (-p.y)+medianY;
			p.x += medianX;
		}
		
		return pth;
	}
	
	public function getPointNormalized(time:Float):Point {
		time = Math.max(0, Math.min(time, 1));
		if (time == 0) return points[0].clone();
		time = time * maxT;
		return getPoint(time);
	}
	
	public function serialize():String {
		var out:Dynamic = {};
		out.points = new Array<Dynamic>();
		for (p in points) {
			out.points.push( { x:p.x, y:p.y, time:p.time,angle:p.angle } );
		}
		return Json.stringify(out);
	}
	
	public static function deserialize(json:String):Path {
		var ob:Dynamic = Json.parse(json);
		var path:Path = new Path();
		for (i in 0...ob.points.length) {
			var o:Dynamic = ob.points[i];
			path.addPoint(o.x, o.y, o.time, o.angle);
		}
		//trace("MaxT: " + path.maxTime);
		return path;
	}
	public function getExitAngle():Float {
		return points[points.length - 1].angle;
	}
}