package no.doomsday.games.tools.pathtool.splines
{
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class LineSegment implements ISplineSegment
	{
		public var p1:Point = new Point();
		public var p2:Point = new Point();
		public function LineSegment(x1:Number,y1:Number,x2:Number,y2:Number) 
		{
			p1.x = x1;
			p2.x = x2;
			p1.y = y1;
			p2.y = y2;
		}
		public function getPointOnCurve(t:Number):Point {
			//time = -Math.cos(time * 1.57)*0.5+0.5;
			var p:Point = new Point();
			var diffX:Number = p2.x - p1.x;
			var diffY:Number = p2.y - p1.y;
			
			return new Point(p1.x+diffX*t,p1.y+diffY*t);
		}
		
		/* INTERFACE no.doomsday.math.geom.splines.ISplineSegment */
		
		public function getTangent(t:Number):Number
		{
			return 0;
		}
		
		/* INTERFACE no.creuna.geom.splines.ISplineSegment */
		
		public function set start(p:Point):void
		{
			p1 = p;
		}
		
		public function set end(p:Point):void
		{
			p2 = p;
		}
		
		/* INTERFACE no.creuna.geom.splines.ISplineSegment */
		
		public function get start():Point
		{
			return p1;
		}
		
		public function get end():Point
		{
			return p2;
		}
		
	}
	
}