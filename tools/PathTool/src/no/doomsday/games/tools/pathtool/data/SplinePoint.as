package no.doomsday.games.tools.pathtool.data 
{
	import flash.geom.Point;
	import org.osflash.signals.Signal;
	/**
	 * Linked list node describing a spline point and its neighbors
	 * @author Andreas Rønning
	 */
	public class SplinePoint extends Point
	{
		public var selected:Boolean = false;
		public var next:SplinePoint = null;
		public var previous:SplinePoint = null;
		public var angleToNext:Number = 0;
		public var time:Number = 0;
		public const changed:Signal = new Signal(SplinePoint);
		public function getHead():SplinePoint {
			if (next != null) {
				return next.getHead();
			}else {
				return this;
			}
		}
		public function getTail():SplinePoint {
			if (previous != null) {
				return previous.getTail();
			}else {
				return this;
			}
		}
		public function makeCopy():SplinePoint {
			var sp:SplinePoint = new SplinePoint(this);
			if (hasNext()) {
				var copy:SplinePoint = next.makeCopy();
				sp.next = copy;
				copy.previous = sp;
			}
			return sp;
		}
		public function SplinePoint(pt:Point = null,time:Number = -1) 
		{
			this.time = time;
			if (pt == null) {
				pt = new Point();
			}
			super(pt.x, pt.y);
		}
		public function size():int {
			var pt:SplinePoint = this;
			var out:int = 0;
			while(pt.hasNext()) {
				pt = pt.next;
				out++;
			}
			return out;
		}
		public function hasNext():Boolean {
			return next != null;
		}
		public function hasPrev():Boolean {
			return previous != null;
		}
		
		/* INTERFACE no.doomsday.games.tools.pathtool.data.ISerializable */
		
		
		public function calcAngle():void 
		{
			var diffX:Number, diffY:Number;
			if (hasNext()) {
				diffX = next.x - x;
				diffY = next.y - y;
				angleToNext = Math.atan2(diffY, diffX);
			}else if (hasPrev()) {
				diffX = x - previous.x;
				diffY = y - previous.y;
				angleToNext = Math.atan2(diffY, diffX);
			}else {
				angleToNext = 0;
			}
		}
		
		public function updateFromPoint(point:Point):void 
		{
			x = point.x;
			y = point.y;
		}
		
		public function append(currentPoint:SplinePoint):SplinePoint 
		{
			next = currentPoint;
			currentPoint.previous = this;
			return currentPoint;
		}
		
	}

}