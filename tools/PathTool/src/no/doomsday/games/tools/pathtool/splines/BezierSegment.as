package no.doomsday.games.tools.pathtool.splines
{
	import flash.display.Graphics;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class BezierSegment implements ISplineSegment
	{
		public var p1:Point;
		public var p2:Point;
		public var control1:Point;
		public var control2:Point;
		/**
		 * Creates a Bezier curve segment based on two points and two control points
		 * @param	p1
		 * The starting point
		 * @param	p2
		 * The end point
		 * @param	control1
		 * The starting point's control point
		 * @param	control2
		 * The ending point's control point
		 */
		public function BezierSegment(p1:Point,p2:Point,control1:Point,control2:Point) 
		{
			this.p1 = p1;
			this.p2 = p2;
			this.control1 = control1;
			this.control2 = control2;
		}
		/**
		 * Get a point along the segment
		 * @param	t
		 * A value between 0 and 1 (start and end respectively) 
		 * @return
		 * A Point instance 
		 */
		public function getPointOnCurve(t:Number):Point {
			var x:Number = 0;
			//solve for x
			var cX:Number = 3 * (control1.x - p1.x);
			var bX:Number = 3 * (control2.x - control1.x) - cX;
			var aX:Number = p2.x - p1.x - 3 * (control2.x - control1.x);
			x = aX * (t * t * t) + bX * (t * t) + cX * t + p1.x;
			
			var y:Number = 0;
			//solve for y
			var cY:Number = 3 * (control1.y - p1.y);
			var bY:Number = 3 * (control2.y - control1.y) - cY;
			var aY:Number = p2.y - p1.y - 3 * (control2.y - control1.y);
			y = aY * (t * t * t) + bY * (t * t) + cY * t + p1.y;
			return new Point(x, y);
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
		public function render(graphics:Graphics, segments:int = 40,renderPoints:Boolean = true,pointRadius:Number = 4):void {
			var t:Number = 0;
			if (renderPoints) {
				graphics.beginFill(0);
				graphics.drawCircle(p1.x, p1.y, pointRadius);
				graphics.drawCircle(p2.x, p2.y, pointRadius);
				graphics.beginFill(0xFF0000);
				graphics.drawCircle(control1.x, control1.y, pointRadius);
				graphics.drawCircle(control2.x, control2.y, pointRadius);
				graphics.endFill();
			}
			graphics.lineStyle(0, 0);
			graphics.moveTo(p1.x, p1.y);
			for (var i:int = 0; i < segments; i++) 
			{
				t = i / (segments - 1);
				var p:Point = getPointOnCurve(t);
				graphics.lineTo(p.x, p.y);
			}
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