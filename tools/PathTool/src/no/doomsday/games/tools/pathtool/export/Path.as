package no.doomsday.games.tools.pathtool.export
{
	import flash.display.Graphics;
	import flash.geom.Point;
	import no.doomsday.games.tools.pathtool.export.PathPoint;

	/**
	 * ...
	 * @author Andreas Rønning
	 */

	public class Path 
	{
		public var maxT:Number = 0;
		public var minT:Number = 0;
		public var points:Vector.<PathPoint>;
		public function Path() 
		{
			clear();
		}
		public function addPoint(x:Number, y:Number, time:Number = -1, angleToNext:Number = 0):void {
			if (time == -1) {
				time = points.length;
			}
			points.push(new PathPoint(time, x, y,angleToNext));
			updateInfo();
		}
		public function clear():void {
			points = new Vector.<PathPoint>();
		}
		
		private function updateInfo():void
		{
			points.sort(sortFunc);
			minT = points[0].time;
			maxT = points[points.length - 1].time;
		}
		private function sortFunc(a:PathPoint, b:PathPoint):int {
			if (a.time < b.time) return -1;
			if (a.time > b.time) return 1;
			return 0;
		}
		public function drawPath(g:Graphics):void {
			var first:Boolean = true;
			for each(var p:PathPoint in points) {
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
		
		public function getPoint(time:Number):Point {
			time = Math.max(0, time);
			if (points.length == 0) return new Point();
			if (points.length == 1 || time == 0) return points[0];
			if (time > maxT) return points[points.length - 1];
			//bracket
			var first:PathPoint = null;
			var second:PathPoint = null;
			for (var idx:int = 0; idx < points.length; idx++ ) {
				var pt:PathPoint = points[idx];
				if (time <= pt.time) { 
					second = pt;
					first = points[idx - 1];
					break;
				}
			}
			//normalize range
			var m:Number = (time-first.time) / (second.time-first.time);
			return new Point(first.x + ((second.x - first.x) * m), first.y + ((second.y - first.y) * m));
		}
		
		public function serialize():String {
			var out:Object = {};
			out.points = new Array();
			for each(var p:PathPoint in points) {
				out.points.push( { x:p.x, y:p.y, time:p.time,angle:p.angle } );
			}
			return JSON.stringify(out);
		}
		
		public static function deserialize(json:String):Path {
			var ob:Object = JSON.parse(json);
			var path:Path = new Path();
			for (var i:int = 0; i < ob.points.length;i++ ) {
				var o:Object = ob.points[i];
				path.addPoint(o.x, o.y, o.time,o.angle);
			}
			return path;
		}
		
	}
}