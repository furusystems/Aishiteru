package com.furusystems.tilesheeter.format 
{
	import com.adobe.images.PNGEncoder;
	import com.furusystems.tilesheeter.SharedData;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class GTSFormatter 
	{
		public static function generate(json:String, images:Vector.<BitmapData>):ByteArray {
			var out:ByteArray = new ByteArray();
			out.writeUTF("2.0"); //version header
			out.writeUTF(json); //json descriptor
			
			out.writeShort(images.length);
			for (var i:int = 0; i < images.length; i++) 
			{
				out.writeShort(images[i].width); //image dims
				var bytes:ByteArray = PNGEncoder.encode(images[i]);
				out.writeUnsignedInt(bytes.length); //image filesize
				out.writeBytes(bytes, 0, bytes.length);
			}
			out.position = 0;
			out.compress();
			return out;
		}
		public static function read(bytes:ByteArray, sd:SharedData):void {
			sd.clear();
			bytes.uncompress();
			var version:String = bytes.readUTF();
			if (version != "2.0") {
				throw new Error("Old version GTS");
			}
			var desc:String = bytes.readUTF();
			sd.parseDescriptor(desc);
			
			var imgCount:int = bytes.readShort();
			for (var i:int = 0; i < imgCount; i++) 
			{
				var squared:int = bytes.readShort();
				var size:int = bytes.readUnsignedInt();
				var imageBytes:ByteArray = new ByteArray();
				bytes.readBytes(imageBytes, 0, size);
				if(squared!=sd.textureBounds.width){
					sd.addSubtexture(imageBytes);
				}else {
					sd.setTexture(imageBytes);
				}
			}
		}
		
	}

}