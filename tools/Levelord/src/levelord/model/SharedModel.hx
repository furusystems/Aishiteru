package levelord.model;

import flash.utils.ByteArray;
import levelord.model.animation.Playback;
import levelord.model.SharedModel.ChangedData;

/**
 * ...
 * @author Andreas Rønning
 */

class ChangedData {
	public var value:Dynamic;
	function new(?value:Dynamic) {
		this.value = value;
	}
	static var instance = new ChangedData();
	public static function next(?value:Dynamic):ChangedData {
		instance.value = value;
		return instance;
	}
}
 
class SharedModel 
{
	public static inline var STRUCTURE:Int = 2; //when skeleton structure is changed
	public static inline var BONES:Int = 4;  //When bones are transformed
	public static inline var META:Int = 8; //When bone metadata is changed
	public static inline var SELECTION:Int = 16; //When selections are made
	public static inline var ANIMATION:Int = 32; //When the timeline moves
	public static inline var CAMERA:Int = 64; //When the camera moves
	public static inline var LOAD:Int = 128; //When a file is loaded
	public static inline var ANIMATION_LIST:Int = 256; //When the list of animations change
	static public inline var ANIMATION_WEIGHT:Int = 512;
	
	public static var ALL:Int = 2 | 4 | 8 | 16 | 32 | 64 | 128 | 256 | 512;
	
	public static var playback = new Playback();
	
	public static function clear() {
	}
	
	public static function export():ByteArray {
		var out = new ByteArray();
		return out;
	}
	
	public static function serialize():String {
		return ""
	}
	
	public static function load(s:String) {
	}
	
	static public function updateWorld() 
	{
		worldMatrix.identity();
		worldMatrix.scale(SharedModel.zoom, SharedModel.zoom);
		worldMatrix.translate(cameraPos.x, cameraPos.y);
		worldMatrixInverse.copyFrom(SharedModel.worldMatrix);
		worldMatrixInverse.invert();
		onChanged.dispatch(SharedModel.CAMERA, null);
	}
}