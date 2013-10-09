package com.furusystems.games.editors
{
	import com.bit101.components.PushButton;
	import com.furusystems.dconsole2.DConsole;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.tools.AnimationPalette;
	import com.furusystems.games.editors.tools.ScriptEditor;
	import com.furusystems.games.editors.tools.Timeline;
	import com.furusystems.games.editors.tools.ToolBar;
	import com.furusystems.games.editors.view.BoneRenderer;
	import com.furusystems.games.editors.view.TileRenderer;
	import com.furusystems.logging.slf4as.ILogger;
	import com.furusystems.logging.slf4as.Logging;
	import flash.desktop.NativeApplication;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Main extends Sprite 
	{
		private var boneRenderer:BoneRenderer;
		private var tileRenderer:TileRenderer;
		private var animationPalette:AnimationPalette;
		public var scriptEditor:ScriptEditor;
		public var toolBar:ToolBar;
		public var timeLine:Timeline;
		public var drawLabels:Boolean = true;
		private static const L:ILogger = Logging.getLogger(Main);
		private var zeroZoomButton:PushButton;
		private var clickPos:Point;
		public var background:Sprite = new Sprite();
		public var backgroundColors:Array = [0x333333, 0xFFFFFF, 0, 0x00FF00];
		public function Main():void 
		{
			stage.nativeWindow.addEventListener(Event.CLOSING, onWindowClosing);
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			scriptEditor = new ScriptEditor(this);
			toolBar = new ToolBar();
			timeLine = new Timeline(this);
			animationPalette = new AnimationPalette();
			toolBar.nw.x = toolBar.nw.y = 10;
			stage.nativeWindow.x = 330;
			stage.nativeWindow.y = 10;
			timeLine.nw.x = 330;
			timeLine.nw.y = stage.nativeWindow.y + stage.nativeWindow.height + 3;
			animationPalette.nw.x = stage.nativeWindow.x + stage.nativeWindow.width;
			animationPalette.nw.y = stage.nativeWindow.y;
			stage.color = backgroundColors[0];
			
			addChild(background);
			tileRenderer = new TileRenderer();
			addChild(tileRenderer);
			boneRenderer = new BoneRenderer();
			addChild(boneRenderer);
			stage.addEventListener(Event.RESIZE, onStageResize);
			
			
			addChild(DConsole.view);
			
			onStageResize();
			
			zeroZoomButton = new PushButton(this, 0, 0, "Zero zoom");
			zeroZoomButton.addEventListener(MouseEvent.CLICK, zeroZoom);
			
			SharedModel.clear();
			SharedModel.onChanged.add(onModelChanged);
			
			if (CONFIG::debug) timeLine.populate(SharedModel.playback.currentAnimation);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			background.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDown);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
		}
		
		private function onModelChanged(flags:int, data:Object):void 
		{
			if (flags & SharedModel.CAMERA) {
				redrawOrigo();
			}
		}
		
		
		private function onMouseDown(e:MouseEvent):void 
		{
			clickPos = new Point(stage.mouseX, stage.mouseY);
			stage.addEventListener(Event.MOUSE_LEAVE, onMouseUp);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseUp(e:Event):void 
		{
			stage.removeEventListener(Event.MOUSE_LEAVE, onMouseUp);
			stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		}
		
		private function onMouseMove(e:MouseEvent):void 
		{
			var deltaX:Number = stage.mouseX - clickPos.x;
			var deltaY:Number = stage.mouseY - clickPos.y;
			SharedModel.cameraPos.x += deltaX;
			SharedModel.cameraPos.y += deltaY;
			SharedModel.updateWorld();
			clickPos.x = stage.mouseX;
			clickPos.y = stage.mouseY;
		}
		
		private function onEnterFrame(e:Event):void 
		{
			SharedModel.currentFrame++;
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
		}
		
		private function zeroZoom(e:MouseEvent):void 
		{
			SharedModel.zoom = 1;
			SharedModel.cameraPos.x = 0;
			SharedModel.cameraPos.y = 0;
			SharedModel.updateWorld();
		}
		
		private function setAnimation(name:String):void 
		{
			for (var i:int = 0; i < SharedModel.animations.length; i++) 
			{
				if (SharedModel.animations[i].name.toLowerCase() == name.toLowerCase()) {
					SharedModel.playback.currentAnimation = SharedModel.animations[i];
					return;
				}
			}
			SharedModel.playback.currentAnimation = null;
		}
		
		
		private function onMouseWheel(e:MouseEvent):void 
		{
			var delta:Number = e.delta;
			SharedModel.zoom += delta * 0.02;
			SharedModel.zoom = Math.max(0.01, SharedModel.zoom);
			SharedModel.updateWorld();
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			if (stage.focus == null) {
				switch(e.keyCode) {
					case Keyboard.SPACE:
						boneRenderer.drawBones = !boneRenderer.drawBones;
						SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
						break;
					case Keyboard.LEFT:
						boneRenderer.nudgeLeft();
						break;
					case Keyboard.RIGHT:
						boneRenderer.nudgeRight();
						break;
					case Keyboard.UP:
						boneRenderer.nudgeUp();
						break;
					case Keyboard.DOWN:
						boneRenderer.nudgeDown();
						break;
					case Keyboard.L:
						boneRenderer.drawLabels = !boneRenderer.drawLabels;
						SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
						break;
					case Keyboard.B:
						cycleBackground();
						break;
					case Keyboard.NUMBER_0:
						zeroTransforms();
						break;
				}
			}
		}
		
		private function cycleBackground():void 
		{
			backgroundColors.push(backgroundColors.shift());
			redrawOrigo();
		}
		
		private function zeroTransforms():void 
		{
			if (SharedModel.selection == null) return;
			SharedModel.selection.rotation = 0;
			SharedModel.selection.scale.x = 1;
			SharedModel.selection.scale.y = 1;
			SharedModel.onChanged.dispatch(SharedModel.BONES, SharedModel.selection.boneID);
		}
		
		private function toggleLabels():void 
		{
			drawLabels = !drawLabels;
		}
		
		private function onStageResize(e:Event = null):void 
		{
			boneRenderer.x = tileRenderer.x = stage.stageWidth / 2;
			boneRenderer.y = tileRenderer.y = stage.stageHeight / 2;
			redrawOrigo();
		}
		
		private function redrawOrigo():void 
		{
			var ox:Number = SharedModel.cameraPos.x;
			var oy:Number = SharedModel.cameraPos.y;
			var graphics:Graphics = background.graphics;
			graphics.clear();
			graphics.beginFill(backgroundColors[0]);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
			graphics.lineStyle(0, 0x222222);
			graphics.moveTo(stage.stageWidth / 2+ox, 0);
			graphics.lineTo(stage.stageWidth / 2+ox, stage.stageHeight);
			
			graphics.moveTo(0, stage.stageHeight/2+oy);
			graphics.lineTo(stage.stageWidth, stage.stageHeight / 2+oy);
		}
		
		private function onWindowClosing(e:Event):void 
		{
			NativeApplication.nativeApplication.exit(0);
		}
		
	}
	
}