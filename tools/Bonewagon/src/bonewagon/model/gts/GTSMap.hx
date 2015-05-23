package bonewagon.model.gts;
import flash.errors.Error;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
/**
 * ...
 * @author Andreas Rønning
 */
class GTSMap
{
	public static var dict:Map<String, GTSSheet>;
	public static function clear() {
		dict = new Map<String, GTSSheet>();
	}
	public static function loadFromPath(path:String):GTSSheet {
		if(dict[path]==null){
			var f:File = new File(path);
			if (!f.exists) {
				throw new Error("Invalid GTS Path");
			}
			var fs = new FileStream();
			fs.open(f, FileMode.READ);
			var bytes = new ByteArray();
			fs.readBytes(bytes);
			var s = GTSFormatter.read(bytes);
			dict[path] = s;
			return s;
		}
		return dict[path];
	}
	
}