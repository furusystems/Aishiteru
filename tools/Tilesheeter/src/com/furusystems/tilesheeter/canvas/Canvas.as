package com.furusystems.tilesheeter.canvas 
{
	import com.furusystems.tilesheeter.IResizable;
	import com.furusystems.tilesheeter.SharedData;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Canvas extends Sprite implements IResizable
	{
		private var gameRectView:Shape;
		public var layerContainer:Sprite = new Sprite();
		public var tileContainer:Sprite = new Sprite();
		public var bgColor:uint = 0xFFFFFF;
		public var bgColors:Array = [0xFFFFFF, 0, 0xFF0000, 0x00FF00, 0x0000FF, 0xFF00FF];
		
		private var _model:SharedData;
		private var _viewDirty:Boolean = false;
		private var outline:Shape;
		private var _alphaMask:Boolean = false;
		
		private var alphamaskOverlay:Bitmap = new Bitmap();
		private var canvasContainer:Sprite;
		
		private var offsetMatrix:Matrix = new Matrix();
		
		private var offsetPt:Point = new Point();
		private var prevMouse:Point = new Point();
		private var clickOffset:Point = new Point();
		private var zoom:Number = 1;
		
		public function Canvas(model:SharedData) 
		{
			_model = model;
			_model.changed.add(onModelChanged);
			gameRectView = new Shape();
			outline = new Shape();
			
			canvasContainer = new Sprite();
			canvasContainer.addChild(gameRectView);
			canvasContainer.addChild(layerContainer);
			canvasContainer.addChild(alphamaskOverlay);
			canvasContainer.addChild(outline);
			canvasContainer.addChild(tileContainer);
			
			addChildAt(canvasContainer, 0);
			
			outline.blendMode = BlendMode.INVERT;
			addEventListener(Event.ENTER_FRAME, updateView);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			switch(e.keyCode) {
				case Keyboard.BACKSPACE:
					_model.deleteObject();
					break;
				case Keyboard.LEFT:
					_model.nudgeLayer( -1, 0, e.shiftKey, e.ctrlKey);
					break;
				case Keyboard.RIGHT:
					_model.nudgeLayer( 1, 0, e.shiftKey, e.ctrlKey);
					break;
				case Keyboard.UP:
					_model.nudgeLayer( 0, -1, e.shiftKey, e.ctrlKey);
					break;
				case Keyboard.DOWN:
					_model.nudgeLayer( 0, 1, e.shiftKey, e.ctrlKey);
					break;
			}
		}
		
		
		private function onRightMouseDown(e:MouseEvent):void 
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onRightDrag);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightUp);
			clickOffset.x = prevMouse.x = stage.mouseX;
			clickOffset.y = prevMouse.y = stage.mouseY;
		}
		
		private function onRightUp(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onRightDrag);
			stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightUp);
		}
		
		private function onRightDrag(e:MouseEvent):void 
		{
			var newX:Number = stage.mouseX;
			var newY:Number = stage.mouseY;
			offsetPt.x += newX-prevMouse.x;
			offsetPt.y += newY-prevMouse.y;
			prevMouse.x = newX;
			prevMouse.y = newY;
		}
		
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onModelChanged():void 
		{
			_viewDirty = true;
			layerContainer.removeChildren();
			layerContainer.addChild(new Bitmap(_model.baseTexture));
		}
		
		private function updateView(e:Event):void 
		{
			if (_viewDirty) {
				redraw();
				_viewDirty = false;
			}
			offsetMatrix.identity();
			offsetMatrix.translate(offsetPt.x, offsetPt.y);
			canvasContainer.transform.matrix = offsetMatrix;
		}
		public function turnoffAlphaMask():void {
			_alphaMask = false;
			redraw();
		}
		public function toggleAlphaMask(e:Event = null):void {
			_alphaMask = !_alphaMask;
			redraw();
		}
		private function redraw():void 
		{
			//removeChild(gameRectView);
			
			graphics.clear();
			graphics.beginFill(0x808080);
			graphics.drawRect(0, 0, stage.stageWidth - x, stage.stageHeight);
			graphics.endFill();
			
			gameRectView.graphics.clear();
			gameRectView.graphics.beginFill(bgColor);
			gameRectView.graphics.drawRect(0, 0, _model.textureBounds.width, _model.textureBounds.height);
			gameRectView.graphics.endFill();
			
			outline.graphics.clear();
			outline.graphics.lineStyle(0, 0, 0.5);
			outline.graphics.drawRect(0, 0, _model.textureBounds.width, _model.textureBounds.height);
			
			if (_model.gridEnabled) {
				var cellWidth:Number = _model.textureBounds.width / _model.gridColumns;
				var cellHeight:Number = _model.textureBounds.height / _model.gridRows;
				var w:int = _model.textureBounds.width / cellWidth;
				var h:int = _model.textureBounds.height / cellHeight;
				gameRectView.graphics.lineStyle(0, 0xbbbbbb);
				var i:int = w;
				while (i--) {
					gameRectView.graphics.moveTo(i*cellWidth, 0);
					gameRectView.graphics.lineTo(i*cellWidth, _model.textureBounds.height);
				}
				i = h;
				while (i--) {
					gameRectView.graphics.moveTo(0, i * cellHeight);
					gameRectView.graphics.lineTo(_model.textureBounds.width, i * cellHeight);
				}
			}
			
			alphamaskOverlay.visible = _alphaMask;
			if (_alphaMask) {
				var bmd:BitmapData = _model.getTexture().clone();
				bmd.threshold(bmd, bmd.rect, new Point(), ">", 0x00000000, 0xFF000000, 0xFF000000, false);
				alphamaskOverlay.bitmapData = bmd;
			}else {
				alphamaskOverlay.bitmapData = null;
			}
		}
		
		/* INTERFACE no.doomsday.games.tools.pathtool.IResizable */
		
		public function resize():void 
		{
			_viewDirty = true;
		}
		
		public function nextBackground():void 
		{
			bgColors.unshift(bgColors.pop());
			bgColor = bgColors[0];
			redraw();
		}
		
	}

}