package com.furusystems.games.extensions;
import flash.geom.Matrix;
import flash.geom.Point;
/**
 * ...
 * @author Andreas Rønning
 */
class Transformations 
{
	
	public static function transform(p:Point, mat:Matrix):Point {
		
		var m:Matrix = mat.clone();
		m.invert();
		p = m.deltaTransformPoint(p);
		return p;
	}
	
}