package com.furusystems.games.rendering.utils;
import flash.geom.Matrix;
import flash.geom.Point;

/**
 * ...
 * @author Andreas Rønning
 */
class PointUtils
{

	public static inline function setTo(p:Point, x:Float, y:Float):Void {
		p.x = x;
		p.y = y;
	}
	public static inline function transformPointInPlace(m:Matrix, inPos:Point):Point {
	   var x:Float = inPos.x * m.a + inPos.y * m.c + m.tx;
	   var y:Float = inPos.x * m.b + inPos.y * m.d + m.ty;
	   inPos.x = x;
	   inPos.y = y;
	   return inPos;
	}
	
}