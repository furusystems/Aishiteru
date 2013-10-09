package com.furusystems.games.editors.view 
{
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Manipulator extends Sprite
	{
		public static const TRANSLATE:int = 0;
		public static const ROTATE:int = 1;
		public static const SCALE:int = 2;
		private var modes:Array = [TRANSLATE, ROTATE, SCALE];
		public var mode:int = TRANSLATE;
		public function Manipulator() 
		{
			blendMode = BlendMode.INVERT;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			setMode(mode);
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(e:MouseEvent):void 
		{
			x = parent.mouseX - 8;
			y = parent.mouseY - 8;
		}
		public function cycleMode():void {
			modes.push(modes.shift());
			setMode(modes[0]);
		}
		
		public function setMode(mode:int):void 
		{
			this.mode = mode;
			graphics.clear();
			graphics.lineStyle(0, 0, 1);
			switch(mode) {
				case TRANSLATE:
					graphics.moveTo( -5, 0);
					graphics.lineTo( 6, 0);
					graphics.moveTo( 0, -5);
					graphics.lineTo( 0, 6);
					break;
				case ROTATE:
					graphics.drawCircle(0, 0, 5);
					break;
				case SCALE:
					graphics.drawRect( -5, -5, 10, 10);
					break;
			}
		}
		
	}

}