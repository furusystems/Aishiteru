package bonewagon.model;

import bonewagon.model.animation.Animation;
import bonewagon.model.animation.Playback;
import bonewagon.model.gts.GTSMap;
import bonewagon.model.gts.GTSSheet;
import bonewagon.model.SharedModel.ChangedData;
import bonewagon.model.skeleton.Bone;
import bonewagon.model.skeleton.Skeleton;
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.events.Event;
import flash.filesystem.File;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.net.FileFilter;
import flash.text.TextField;
import flash.utils.ByteArray;
import fsignal.Signal2;
import haxe.Json;

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
	
	static public var SAMPLERATE:Int = 60; //Frames per second used when exporting
	
	public static var basePose:Animation = null;
	public static var animations = new Array<Animation>();
	public static var skeleton = new Skeleton();
	public static var onChanged = new Signal2<Int, ChangedData>();
	public static var worldMatrix = new Matrix();
	public static var worldMatrixInverse = new Matrix();
	public static var characterName = "Character";
	public static var zoom = 1.0;
	public static var cameraPos = new Point();
	public static var gtsPath = "n/a";
	static public var gts:GTSSheet = null;
	static public var currentFrame:Int = 0;
	
	static public var CHAR_FORMAT_VERSION:Int = 3;
	static public var ANIMS_FORMAT_VERSION:Int = 3;
	
	public static var playback = new Playback();
	
	public static var selection(get, set):Bone;
	
	public static function get_selection():Bone {
		return skeleton.selectedBone;
	}
	public static function set_selection(b:Bone) {
		return skeleton.selectedBone = b;
	}
	
	public static function clear() {
		characterName = "Character";
		Bone.uidPool = 0;
		animations = new Array<Animation>();
		skeleton = new Skeleton();
		basePose = new Animation();
		playback.currentAnimation = basePose;
		onChanged.dispatch(BONES, ChangedData.next(skeleton.boneID));
		onChanged.dispatch(ALL,null);
	}
	
	public static function export():ByteArray {
		trace("Beginning export at sample rate "+SAMPLERATE);
		var out:ByteArray = new ByteArray();
		out.writeShort(ANIMS_FORMAT_VERSION); //...
		skeleton.export(out); //Skeleton Json
		out.writeShort(skeleton.listBones().length); //number of bones
		out.writeShort(animations.length + 1); //include basepose in count
		
		basePose.export(out);
		for (a in animations) 
		{
			trace("\tAnimation: " + a.name + ", " + a.getDuration());
			a.export(out);
		}
		return out;
	}
	
	public static function serialize():String {
		var ob:Dynamic = { };
		ob.name = characterName;
		ob.animations = [];
		var i:Int;
		ob.version = CHAR_FORMAT_VERSION;
		ob.skeleton = skeleton.serialize();
		ob.gtsPath = gtsPath;
		ob.basePose = basePose.serialize();
		for (a in animations) 
		{
			ob.animations.push(a.serialize());
		}
		return Json.stringify(ob);
	}
	
	public static function load(s:String) {
		GTSMap.clear();
		var ob:Dynamic = Json.parse(s);
		characterName = ob.name;
		gtsPath = ob.gtsPath;
		var browseForGTS:Bool = false;
		if (gtsPath != "n/a") {
			try{
				gts = GTSMap.loadFromPath(gtsPath);
			}catch (e:Dynamic) {
				browseForGTS = true;
				trace("Will browse for gts post");
			}
		}
		
		skeleton.deserialize(ob.skeleton);
		
		basePose = Animation.fromOb(ob.basePose);
		animations = new Array<Animation>();
		for (i in 0...ob.animations.length) 
		{
			var a = ob.animations[i];
			animations.push(Animation.fromOb(a));
		}
		playback.currentAnimation = basePose;
		if (browseForGTS) {
			var gtsFile:File = new File();
			gtsFile.addEventListener(Event.SELECT, onGtsSelect);
			gtsFile.addEventListener(Event.CANCEL, onGtsLoadCancel);
			gtsFile.browse([new FileFilter("Corrected path for GTS", "*.gts")]);
		}else {
			onChanged.dispatch(SharedModel.CAMERA | SharedModel.META | SharedModel.STRUCTURE | SharedModel.LOAD, null);
		}
	}
	
	static function onGtsLoadCancel(e:Event) 
	{
		var f:File = cast e.currentTarget;
		f.removeEventListener(Event.SELECT, onGtsSelect);
		gts = null;
		gtsPath = "n/a";
		onChanged.dispatch(SharedModel.CAMERA | SharedModel.META | SharedModel.STRUCTURE | SharedModel.LOAD, null);
	}
	
	static function onGtsSelect(e:Event) 
	{
		var f:File = cast e.currentTarget;
		f.removeEventListener(Event.SELECT, onGtsSelect);
		gtsPath = f.nativePath;
		gts = GTSMap.loadFromPath(gtsPath);
		onChanged.dispatch(SharedModel.CAMERA | SharedModel.META | SharedModel.STRUCTURE | SharedModel.LOAD, null);
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