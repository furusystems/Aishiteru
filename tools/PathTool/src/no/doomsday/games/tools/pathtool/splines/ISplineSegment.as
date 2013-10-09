package no.doomsday.games.tools.pathtool.splines 
{
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public interface ISplineSegment 
	{
		function getPointOnCurve(t:Number):Point;
		function get start():Point;
		function set start(p:Point):void;
		function get end():Point;
		function set end(p:Point):void;
		function getTangent(t:Number):Number;
	}
	
}