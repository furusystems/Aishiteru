package com.furusystems.tilesheeter.magnifier 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Magnifier extends Bitmap
	{
		private var scaleMatrix:Matrix;
		private var clipRect:Rectangle;
		public var bmd:BitmapData = new BitmapData(48, 48, false, 0xFFFFFF);
		public function Magnifier() 
		{
			super(bmd);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			scaleMatrix = new Matrix();
			scaleMatrix.scale(4, 4);
			clipRect = new Rectangle(0, 0, 48, 48);
			filters = [new DropShadowFilter(4, 90, 0, 0.3, 8, 8, 1, 3)];
			visible = false;
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(Event.ENTER_FRAME, onMouseMove);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == Keyboard.SPACE) {
				visible = !visible;
			}
		}
		
		private function onMouseMove(e:Event):void 
		{
			if (!visible) return;
			bmd.fillRect(bmd.rect, 0xFFFFFF);
			scaleMatrix.identity();
			scaleMatrix.translate(-(stage.mouseX-4), -(stage.mouseY-4));
			scaleMatrix.scale(4, 4);
			bmd.draw(stage, scaleMatrix, null, null, clipRect, false);
			x = stage.mouseX+8;
			y = stage.mouseY+8;
		}
		
	}

}