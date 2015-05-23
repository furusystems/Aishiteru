package extensions;
import flash.display.BitmapData;
import flash.utils.ByteArray;

import format.png.Data;
import format.png.Reader;
import format.png.Writer;
import format.png.Tools;

/**
 * ...
 * @author Andreas Rønning
 */
class PNGTools
{

	public static function toPngBytes(bmd:BitmapData):ByteArray {
		var out = new ByteArray();
		var w = new Writer(out);
		return out;
	}
	public static function fromPngBytes(bytes:ByteArray):BitmapData {
		return null;
	}
	
}