package no.doomsday.games.tools.pathtool.export
{
	import flash.geom.Point;

	/**
	 * ...
	 * @author Andreas Rønning
	 */

	public class PathPoint extends Point
	{
		public var time:Number;
		public var angle:Number;
		public function PathPoint(time:Number,x:Number,y:Number,angle:Number = 0) 
		{
			super(x, y);
			this.angle = angle;
			this.time = time;
		}
		
	}
}