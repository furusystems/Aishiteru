package com.furusystems.tilesheeter.dialog 
{
	import com.bit101.components.Label;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Dialog extends Sprite
	{
		
		public function Dialog(str:String) 
		{
			new Label(this, 0, 0, str);
			graphics.beginFill(0xFFFFFF);
			graphics.drawRect(0, 0, width, 80);
			addEventListener(MouseEvent.CLICK, onClick);
			Dialog.stage.addChild(this);
			x = (Dialog.stage.stageWidth - width) * .5;
			y = (Dialog.stage.stageHeight - height) * .5;
			filters = [new DropShadowFilter(6,90,0,0.3,16,16)];
		}
		
		private function onClick(e:MouseEvent):void 
		{
			parent.removeChild(this);
		}
		public static var stage:Stage = null;
		
	}

}