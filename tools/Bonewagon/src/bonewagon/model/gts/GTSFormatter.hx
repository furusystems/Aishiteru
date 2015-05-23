package bonewagon.model.gts;
import bonewagon.model.gts.GTSSheet;
import flash.display.BitmapData;
import flash.errors.Error;
import flash.utils.ByteArray;
import flash.utils.IDataInput;
/**
 * ...
 * @author Andreas Rønning
 */
class GTSFormatter 
{
	public static function generate(json:String, images:Array<BitmapData>):ByteArray {
		var out:ByteArray = new ByteArray();
		out.writeUTF("2.0"); //version header
		out.writeUTF(json); //json descriptor
		
		out.writeShort(images.length);
		for (img in images) 
		{
			out.writeShort(img.width); //image dims
			trace("Adding texture bytes of size: " + img.width);
			var bytes:ByteArray = PNGEncoder.encode(img);
			out.writeUnsignedInt(bytes.length); //image filesize
			out.writeBytes(bytes, 0, bytes.length);
		}
		out.position = 0;
		out.compress();
		return out;
	}
	public static function read(bytes:ByteArray):GTSSheet {
		var sd:GTSSheet = new GTSSheet();
		bytes.uncompress();
		var version:String = bytes.readUTF();
		if (version != "2.0") {
			throw new Error("Old version GTS");
		}
		var desc:String = bytes.readUTF();
		sd.parseDescriptor(desc);
		
		var imgCount:Int = bytes.readShort();
		for (i in 0...imgCount) 
		{
			var squared:Int = bytes.readShort();
			if(squared==sd.textureBounds.width){
				var size:Int = bytes.readUnsignedInt();
				var imageBytes = new ByteArray();
				bytes.readBytes(imageBytes, 0, size);
				sd.addLayer(imageBytes, "texture_" + squared);
			}
		}
		return sd;
	}
	
}