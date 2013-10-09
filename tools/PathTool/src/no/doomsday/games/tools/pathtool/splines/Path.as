package no.doomsday.games.tools.pathtool.splines 
{
	import flash.display.Graphics;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Path 
	{
		public var segments:Array = [];
		public var looping:Boolean = true;
		private var p:Point = new Point();
		public var currentSegment:int = 0;
		public function Path(startX:Number = 0,startY:Number = 0) 
		{
			p.x = startX;
			p.y = startY;
		}
		public function addPointLinear(x:Number, y:Number):ISplineSegment {
			var s:LineSegment = new LineSegment(0,0,0,0);
			if (segments.length < 1) {
				s.start.x = p.x;
				s.start.y = p.y;
			}else {
				s.start = segments[segments.length-1].end;
			}
			s.end.x = x;
			s.end.y = y;
			segments.push(s);
			return s;
		}
		
		public function addPointBezier(x:Number, y:Number, control1:Point, control2:Point):ISplineSegment { 
			var s:BezierSegment = new BezierSegment(new Point(),new Point(),new Point(),new Point());
			if (segments.length < 1) {
				s.start.x = p.x;
				s.start.y = p.y;
			}else {
				s.start = segments[segments.length-1].end;
			}
			s.control1 = control1;
			s.control2 = control2;
			s.end.x = x;
			s.end.y = y;
			segments.push(s)
			return s;
		}
		
		public function addSegment(s:ISplineSegment):void {
			segments.push(s);
		}
		public function convertToTotalPathTime(time:Number):Number {
			time = Math.max(0, Math.min(time, 1));
			time = time * (segments.length );
			return time;
		}
		public function getPointOnPath(time:Number):Point {
			currentSegment = Math.max(0, Math.min(Math.floor(time), segments.length - 1));
			var s:ISplineSegment = segments[currentSegment];
			return s.getPointOnCurve(time-currentSegment);
		}
		public function renderPath(g:Graphics, resolution:uint = 80):void {
			//g.clear();
			g.moveTo(segments[0].start.x, segments[0].start.y);
			g.lineStyle(3, 0xFF0000);
			var p:Point = new Point();
			for (var i:int = 0; i < resolution; i++) 
			{
				p = getPointOnPath(convertToTotalPathTime(i / (resolution - 1)));
				g.lineTo(p.x, p.y);
			}
			
		}
		public function convertToCatmullRom():void {
			var origSegments:Array = segments.concat();
			segments = [];
			var prevSeg:CatmullRomSegment;
			for (var i:int = 0; i < origSegments.length; i++) 
			{
				var lineSegment:LineSegment = origSegments[i];
				var newSeg:CatmullRomSegment;
				if (i == 0) {
					newSeg = new CatmullRomSegment(lineSegment.start, lineSegment.start, lineSegment.end, lineSegment.end);
					segments.push(newSeg);
				}else {
					newSeg = new CatmullRomSegment(prevSeg.control2, prevSeg.end, lineSegment.start, lineSegment.end);
					segments.push(newSeg);
				}
				prevSeg = newSeg;
			}
		}
		
	}
	
}