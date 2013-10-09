package com.furusystems.games.editors.utils 
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Transformations 
	{
		
		public static function transformPoint(p:Point, mat:Matrix):Point {
			
			var m:Matrix = mat.clone();
			m.invert();
			p = m.deltaTransformPoint(p);
			return p;
		}
		
	}

}