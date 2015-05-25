package com.furusystems.games.extensions;
import flash.display.BitmapData;
import flash.utils.ByteArray;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;

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
		var out = new BytesOutput();
		var w = new Writer(out);
		var pixels = bmd.getPixels(bmd.rect);
		var d = Tools.build32ARGB(bmd.width, bmd.height, Bytes.ofData(pixels));
		w.write(d);
		return out.getBytes().getData();
	}
	public static function toPngBMD(bytes:ByteArray):BitmapData {
		var b = Bytes.ofData(bytes);
		var input = new BytesInput(b);
		var d = new Reader(input).read();
		var header = Tools.getHeader(d);
		var bmd = new BitmapData(header.width, header.height, true, 0);
		Tools.reverseBytes(b);
		var pixels = Tools.extract32(d);
		bmd.setPixels(bmd.rect, pixels.getData());
		return bmd;
	}
	
}