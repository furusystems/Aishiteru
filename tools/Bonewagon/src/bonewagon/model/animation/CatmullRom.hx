package bonewagon.model.animation 
{
	import flash.geom.Point;
	import flash.geom.Vector3D;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	class CatmullRom 
	{
		public static function spline1D(p0, p1, p2, p3, t) 
        {
            0.5 * ((2*p1) + t * (( -p0+p2) +
                    t * ((2*p0 -5*p1 +4*p2 -p3) +
                    t * (  -p0 +3 * p1 -3 * p2 +p3))));
        }
        public static function spline2D(p0:Point, p1:Point, p2:Point, p3:Point, t):Point 
        {
            return new Point (
                0.5 * ((          2*p1.x) +
                    t * (( -p0.x           +p2.x) +
                    t * ((2*p0.x -5*p1.x +4*p2.x -p3.x) +
                    t * (  -p0.x +3*p1.x -3*p2.x +p3.x)))),
                0.5 * ((          2*p1.y) +
                    t * (( -p0.y           +p2.y) +
                    t * ((2*p0.y -5*p1.y +4*p2.y -p3.y) +
                    t * (  -p0.y +3*p1.y -3*p2.y +p3.y))))
            );
        }
        public static function spline3D(p0:Vector3D, p1:Vector3D, p2:Vector3D, p3:Vector3D, t):Vector3D 
        {
            return new Vector3D (
                0.5 * ((          2*p1.x) +
                    t * (( -p0.x           +p2.x) +
                    t * ((2*p0.x -5*p1.x +4*p2.x -p3.x) +
                    t * (  -p0.x +3*p1.x -3*p2.x +p3.x)))),
                0.5 * ((          2*p1.y) +
                    t * (( -p0.y           +p2.y) +
                    t * ((2*p0.y -5*p1.y +4*p2.y -p3.y) +
                    t * (  -p0.y +3*p1.y -3*p2.y +p3.y)))),
                0.5 * ((          2*p1.z) +
                    t * (( -p0.z           +p2.z) +
                    t * ((2*p0.z -5*p1.z +4*p2.z -p3.z) +
                    t * (  -p0.z +3*p1.z -3*p2.z +p3.z))))
            );
        }
		
	}

}