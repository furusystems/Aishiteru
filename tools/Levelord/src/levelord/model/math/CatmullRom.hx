package levelord.model.math 
{
	typedef Pt = { x:Float, y:Float }
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	class CatmullRom 
	{
		public static inline function cm1D(p0:Float, p1:Float, p2:Float, p3:Float, t:Float):Float 
        {
            return 0.5 * ((2 * p1) + t * (( -p0 + p2) + t * ((2 * p0 - 5 * p1 + 4 * p2 - p3) + t * (  -p0 + 3 * p1 - 3 * p2 + p3))));
        }
        public static inline function cm2D(output:Pt, p0:Pt, p1:Pt, p2:Pt, p3:Pt, t:Float):Void
        {
			output.x = spline1D(p0.x, p1.x, p2.x, p3.x, t);
			output.y = spline1D(p0.y, p1.y, p2.y, p3.y, t);
        }
		
	}

}