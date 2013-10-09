package com.furusystems.tilesheeter.canvas 
{
	import com.furusystems.tilesheeter.SharedData;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
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
		private var sd:SharedData;
		public var filename:String;
		public var clicked:Signal = new Signal(BitmapLayer);
		public function BitmapLayer(sd:SharedData, textureData:ByteArray, filename:String) 
		{
			this.sd = sd;
			this.filename = filename;
			l = new Loader();
			l.contentLoaderInfo.addEventListener(Event.COMPLETE, onTextureLoaded);
			l.loadBytes(textureData);
			addChild(l);
			visible = false;
		}
		
		private function onTextureLoaded(e:Event):void 
		{
			visible = true;
		}
		public function get bitmapData():BitmapData {
			return Bitmap(l.content).bitmapData;
		}
		public function serialize():String {
			var out:Object = { x:x, y:y, file:filename };
			return JSON.stringify(out);
		}
		
	}

}