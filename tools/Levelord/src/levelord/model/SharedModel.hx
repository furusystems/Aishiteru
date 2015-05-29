package levelord.model;

import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.utils.ByteArray;
import fsignal.Signal1;
import fsignal.Signal2;
import levelord.model.animation.Playback;
import levelord.model.objects.EventBlock;
import levelord.model.objects.WorldSpline;
import flash.geom.Matrix3D;

/**
 * ...
 * @author Andreas Rønning
 */

 
enum ModelUpdate {
	ALL;
	BLOCK(?data:EventBlock); 					//when a sequence block is translated or scaled or its spline altered
	TIME(?data:Float);							//when the playhead moves
	CAMERA(world:Matrix3D, worldInv:Matrix3D); 	//when the camera translates
}

class SharedModel 
{
	
	public static var playback = new Playback();
	
	public static var onChanged = new Signal1<ModelUpdate>();
	
	public static var zoom:Float;
	public static var worldMatrix:Matrix3D;
	public static var worldMatrixInverse:Matrix3D;
	public static var cameraPos:Point;
	
	public static var blocks:Array<EventBlock>;
	
	public static function init() {
		zoom = 1.0;
		worldMatrix = new Matrix3D();
		worldMatrixInverse = new Matrix3D();
		cameraPos = new Point();
		blocks = [];
		onChanged.dispatch(ALL);
	}
	
	public static function export():ByteArray {
		var out = new ByteArray();
		return out;
	}
	
	public static function serialize():String {
		return "";
	}
	
	public static function load(s:String) {
		onChanged.dispatch(ALL);
	}
	
	static public function updateWorld() 
	{
		worldMatrix.identity();
		worldMatrix.appendScale(zoom, zoom, zoom);
		worldMatrix.appendTranslation(cameraPos.x, cameraPos.y, 0);
		worldMatrixInverse.copyFrom(worldMatrix);
		worldMatrixInverse.invert();
		onChanged.dispatch(CAMERA(worldMatrix, worldMatrixInverse));
	}
}