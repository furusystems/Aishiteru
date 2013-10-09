package com.furusystems.games.editors.model.gts 
{
	import com.furusystems.games.editors.model.gts.GTSSheet;
	import com.furusystems.games.editors.model.SharedModel;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import ion.utils.png.PNGDecoder;
	import org.osflash.signals.Signal;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class BitmapLayer extends Sprite
	{
		private var l:Loader;
		private var mouseOffset:Point;
		private var dragging:Boolean;
		private var sd:GTSSheet;
		public var filename:String;
		public var clicked:Signal = new Signal(BitmapLayer);
		public var bmd:BitmapData;
		public function BitmapLayer(sd:GTSSheet, textureData:ByteArray, filename:String) 
		{
			this.sd = sd;
			this.filename = filename;
			bmd = PNGDecoder.decodeImage(textureData);
			visible = false;
		}
		private function onTextureLoaded(e:Event):void 
		{
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
			visible = true;
		}
		public function get bitmapData():BitmapData {
			return bmd;
		}
		public function serialize():String {
			var out:Object = { x:x, y:y, file:filename };
			return JSON.stringify(out);
		}
		
	}

}