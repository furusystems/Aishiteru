package com.furusystems.games.editors.model 
{
	import com.bit101.components.TextArea;
	import com.furusystems.games.editors.model.animation.Animation;
	import com.furusystems.games.editors.model.animation.Playback;
	import com.furusystems.games.editors.model.gts.GTSMap;
	import com.furusystems.games.editors.model.gts.GTSSheet;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import com.furusystems.games.editors.model.skeleton.Skeleton;
	import com.furusystems.logging.slf4as.ILogger;
	import com.furusystems.logging.slf4as.Logging;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.FileFilter;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import org.osflash.signals.Signal;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class SharedModel 
	{
		public static const STRUCTURE:int = 2; //when skeleton structure is changed
		public static const BONES:int = 4;  //When bones are transformed
		public static const META:int = 8; //When bone metadata is changed
		public static const SELECTION:int = 16; //When selections are made
		public static const ANIMATION:int = 32; //When the timeline moves
		public static const CAMERA:int = 64; //When the camera moves
		public static const LOAD:int = 128; //When a file is loaded
		public static const ANIMATION_LIST:int = 256; //When the list of animations change
		static public const ANIMATION_WEIGHT:int = 512;
		
		public static const ALL:int = 2 | 4 | 8 | 16 | 32 | 64 | 128 | 256 | 512;
		
		static public const SAMPLERATE:int = 60; //Frames per second used when exporting
		
		public static var basePose:Animation = null;
		public static var animations:Vector.<Animation> = new Vector.<Animation>();
		public static var skeleton:Skeleton = new Skeleton();
		public static var onChanged:Signal = new Signal(int, Object);
		public static var worldMatrix:Matrix = new Matrix();
		public static var worldMatrixInverse:Matrix = new Matrix();
		public static var characterName:String = "Character";
		public static var zoom:Number = 1;
		public static var cameraPos:Point = new Point();
		public static var gtsPath:String = "n/a";
		static public var gts:GTSSheet = null;
		static public var currentFrame:int = 0;
		
		public static const L:ILogger = Logging.getLogger(SharedModel);
		
		static public const CHAR_FORMAT_VERSION:int = 3;
		static public const ANIMS_FORMAT_VERSION:int = 3;
		
		public static var playback:Playback = new Playback();
		
		public static function get selection():Bone {
			return skeleton.selectedBone;
		}
		public static function set selection(b:Bone):void {
			skeleton.selectedBone = b;
		}
		public static function clear():void {
			characterName = "Character";
			Bone.uidPool = 0;
			animations = new Vector.<Animation>();
			skeleton = new Skeleton();
			basePose = new Animation();
			playback.currentAnimation = basePose;
			onChanged.dispatch(BONES, skeleton.boneID);
			onChanged.dispatch(ALL,null);
		}
		
		public static function export():ByteArray {
			L.info("Beginning export at sample rate "+SAMPLERATE);
			var out:ByteArray = new ByteArray();
			out.writeShort(ANIMS_FORMAT_VERSION); //...
			skeleton.export(out); //Skeleton JSON
			out.writeShort(skeleton.listBones().length); //number of bones
			out.writeShort(animations.length + 1); //include basepose in count
			
			basePose.export(out);
			for (var i:int = 0; i < animations.length; i++) 
			{
				L.info("\tAnimation: " + animations[i].name + ", " + animations[i].duration);
				animations[i].export(out);
			}
			return out;
		}
		
		public static function serialize():String {
			var ob:Object = { };
			ob.name = characterName;
			ob.animations = [];
			var i:int;
			ob.version = CHAR_FORMAT_VERSION;
			ob.skeleton = skeleton.serialize();
			ob.gtsPath = gtsPath;
			ob.basePose = basePose.serialize();
			for (i = 0; i < animations.length; i++) 
			{
				ob.animations.push(animations[i].serialize());
			}
			return JSON.stringify(ob);
		}
		
		public static function load(s:String):void {
			GTSMap.clear();
			var ob:Object = JSON.parse(s);
			characterName = ob.name;
			gtsPath = ob.gtsPath;
			var browseForGTS:Boolean = false;
			if (gtsPath != "n/a") {
				try{
					gts = GTSMap.loadFromPath(gtsPath);
				}catch (e:Error) {
					browseForGTS = true;
					trace("Will browse for gts post");
				}
			}
			
			skeleton.deserialize(ob.skeleton);
			
			basePose = Animation.fromOb(ob.basePose);
			animations = new Vector.<Animation>();
			for (var i:int = 0; i < ob.animations.length; i++) 
			{
				animations.push(Animation.fromOb(ob.animations[i]));
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
		
		static private function onGtsLoadCancel(e:Event):void 
		{
			var f:File = e.currentTarget as File;
			f.removeEventListener(Event.SELECT, onGtsSelect);
			gts = null;
			gtsPath = "n/a";
			onChanged.dispatch(SharedModel.CAMERA | SharedModel.META | SharedModel.STRUCTURE | SharedModel.LOAD, null);
		}
		
		static private function onGtsSelect(e:Event):void 
		{
			var f:File = e.currentTarget as File;
			f.removeEventListener(Event.SELECT, onGtsSelect);
			gtsPath = f.nativePath;
			gts = GTSMap.loadFromPath(gtsPath);
			onChanged.dispatch(SharedModel.CAMERA | SharedModel.META | SharedModel.STRUCTURE | SharedModel.LOAD, null);
		}
		
		static public function updateWorld():void 
		{
			worldMatrix.identity();
			worldMatrix.scale(SharedModel.zoom, SharedModel.zoom);
			worldMatrix.translate(cameraPos.x, cameraPos.y);
			worldMatrixInverse.copyFrom(SharedModel.worldMatrix);
			worldMatrixInverse.invert();
			onChanged.dispatch(SharedModel.CAMERA, null);
		}
	}

}