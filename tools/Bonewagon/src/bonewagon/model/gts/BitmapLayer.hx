package bonewagon.model.gts;
import bonewagon.model.gts.GTSSheet;
import bonewagon.model.SharedModel;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.utils.ByteArray;
import fsignal.Signal;
import fsignal.Signal1;
import haxe.Json;
/**
 * ...
 * @author Andreas Rønning
 */
class BitmapLayer extends Sprite
{
	var l:Loader;
	var mouseOffset:Point;
	var dragging:Bool;
	var sd:GTSSheet;
	public var filename:String;
	public var clicked = new Signal1<BitmapLayer>();
	public var bmd:BitmapData;
	public function new(sd:GTSSheet, textureData:ByteArray, filename:String) 
	{
		super();
		this.sd = sd;
		this.filename = filename;
		bmd = PNGDecoder.decodeImage(textureData);
		visible = false;
	}
	function onTextureLoaded(e:Event) 
	{
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
		visible = true;
	}
	public function getBitmapData():BitmapData {
		return bmd;
	}
	public function serialize():String {
		var out:Dynamic = { x:x, y:y, file:filename };
		return Json.stringify(out);
	}
	
}