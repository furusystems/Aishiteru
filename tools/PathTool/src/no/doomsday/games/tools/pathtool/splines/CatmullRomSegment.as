package no.doomsday.games.tools.pathtool.splines
{
	import flash.display.Graphics;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class CatmullRomSegment implements ISplineSegment
	{
		public var p1:Point;
		public var p2:Point;
		public var control1:Point;
		public var control2:Point;
		/**
		 * Create a new 4-point catmull-rom curve segment
		 * @param	control1
		 * The first Point. This is the point "leading into" the first point actually on the segment
		 * @param	p1
		 * The first actual segment Point
		 * @param	p2
		 * The second actual segment Point
		 * @param	control2
		 * The last Point. This is the point "leading out" of the curve
		 */
		public function CatmullRomSegment(control1:Point,p1:Point,p2:Point,control2:Point) 
		{
			this.p1 = p1;
			this.p2 = p2;
			this.control1 = control1;
			this.control2 = control2;
		}
		/**
		 * Get a point along the "actual" curve segment
		 * @param	t
		 * A value between 0 and 1 (p1 and p2 respectively) 
		 * @return
		 */
		public function getPointOnCurve(t:Number):Point {
			var x:Number = 0.5 * (2 * p1.x + ( -control1.x + p2.x) * t + (2 * control1.x - 5 * p1.x + 4 * p2.x - control2.x) * (t * t) + ( -control1.x + 3 * p1.x - 3 * p2.x + control2.x) * (t * t * t));
			var y:Number = 0.5 * (2 * p1.y + ( -control1.y + p2.y) * t + (2 * control1.y - 5 * p1.y + 4 * p2.y - control2.y) * (t * t) + ( -control1.y + 3 * p1.y - 3 * p2.y + control2.y) * (t * t * t));
			return new Point(x, y);
		}
		
		public function getNormal(t:Number):Point {	
			var p1:Point = getPointOnCurve(t);
			var p2:Point = getPointOnCurve(t + 0.0001);
			var vec:Point = new Point(p2.x - p1.x, p2.y - p1.y);
			var out:Point = new Point( -vec.y, vec.x);
			return out;
		}
		
		public function getTangent(t:Number):Number {	
			var p1:Point = getPointOnCurve(t);
			var p2:Point = getPointOnCurve(t + 0.01);
			var vec:Point = new Point(p2.x - p1.x, p2.y - p1.y);
			return Math.atan2(vec.y,vec.x);
		}
		/**
		 * Render the curve segment
		 * @param	graphics
		 * Which Graphics instance to draw with
		 * @param	segments
		 * How many line segments to use for the render
		 * @param	renderPoints
		 * Draw circles on control and end points
		 */
		public function render(graphics:Graphics, segments:int = 40, renderPoints:Boolean = true):void {
			if (renderPoints) {
				graphics.lineStyle(0, 0,0);
				graphics.beginFill(0);
				graphics.drawCircle(p1.x, p1.y, 4);
				graphics.drawCircle(p2.x, p2.y, 4);
				graphics.beginFill(0xFF0000);
				graphics.drawCircle(control1.x, control1.y, 3);
				graphics.drawCircle(control2.x, control2.y, 3);
				graphics.endFill();
			}
			graphics.lineStyle(0, 0);
			graphics.moveTo(p1.x, p1.y);
			for (var i:int = 0; i < segments; i++) 
			{
				var t:Number = i / (segments - 1);	
				var p:Point = getPointOnCurve(t);
				graphics.lineTo(p.x, p.y);
			}
		}
		
		/* INTERFACE no.doomsday.math.geom.splines.ISplineSegment */
		
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