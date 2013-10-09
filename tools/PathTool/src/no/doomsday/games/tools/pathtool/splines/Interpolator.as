package no.doomsday.games.tools.pathtool.splines 
{
	import flash.geom.Point;
	import no.doomsday.games.tools.pathtool.data.SplinePoint;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Interpolator 
	{
		public function Interpolator() 
		{
			
		}
		public static function interpolate(root:SplinePoint, resolution:int = 2 ):SplinePoint {
			var out:SplinePoint = new SplinePoint(root);
			var spline:Path = new Path(out.x, out.y);
			var pt:SplinePoint = root;
			while (pt.hasNext()) {
				pt = pt.next;
				spline.addPointLinear(pt.x, pt.y);
				trace("Adding pt",pt);
			}
			spline.convertToCatmullRom();
			var t:Number = 0;
			pt = out;
			var l:int = spline.segments.length;
			for (var i:int = 0; i < spline.segments.length; i++) {
				var seg:CatmullRomSegment = spline.segments[i];
				t = 0;
				while (t < 1) {
					t += 1 / resolution;
					pt = pt.append(new SplinePoint(seg.getPointOnCurve(t)));
				}
			}
			return out;
		}
		
	}

}