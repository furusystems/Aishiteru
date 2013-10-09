package com.furusystems.games.editors.model.gts 
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class GTSMap
	{
		public static var dict:Dictionary = new Dictionary();
		public static function clear():void {
			dict = new Dictionary();
		}
		public static function loadFromPath(path:String):GTSSheet {
			if(dict[path]==null){
				var f:File = new File(path);
				if (!f.exists) {
					throw new Error("Invalid GTS Path");
				}
				var fs:FileStream = new FileStream();
				fs.open(f, FileMode.READ);
				var bytes:ByteArray = new ByteArray();
				fs.readBytes(bytes);
				var s:GTSSheet = GTSFormatter.read(bytes);
				dict[path] = s;
				return s;
			}
			return dict[path] as GTSSheet;
		}
		
	}

}