package bonewagon;
import bonewagon.model.SharedModel;
import bonewagon.tools.AnimationPalette;
import bonewagon.tools.ScriptEditor;
import bonewagon.tools.Timeline;
import bonewagon.tools.ToolBar;
import bonewagon.view.BoneRenderer;
import bonewagon.view.TileRenderer;
import com.furusystems.fl.gui.Button;
import flash.desktop.NativeApplication;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.ui.Keyboard;

using Lambda;
using extensions.ArrayUtils;

/**
 * ...
 * @author Andreas Rønning
 */
class Main extends Sprite 
{
	var boneRenderer:BoneRenderer;
	var tileRenderer:TileRenderer;
	var animationPalette:AnimationPalette;
	var zeroZoomButton:Button;
	var clickPos:Point;
	
	public var scriptEditor:ScriptEditor;
	public var toolBar:ToolBar;
	public var timeLine:Timeline;
	public var drawLabels:Bool = true;
	public var background:Sprite = new Sprite();
	
	static var backgroundColors:Array<Int> = [0x333333, 0xFFFFFF, 0, 0x00FF00];
	
	public function Main() 
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
		
		onStageResize();
		
		zeroZoomButton = new Button("Zero zoom");
		addChild(zeroZoomButton);
		zeroZoomButton.addEventListener(MouseEvent.CLICK, zeroZoom);
		
		SharedModel.clear();
		SharedModel.onChanged.add(onModelChanged);
		
		#if debug
		timeLine.populate(SharedModel.playback.currentAnimation);
		#end
		
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		background.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDown);
		stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		
	}
	
	function onModelChanged(flags:Int, data:Dynamic) 
	{
		if (flags & SharedModel.CAMERA != 0) {
			redrawOrigo();
		}
	}
	
	
	function onMouseDown(e:MouseEvent) 
	{
		clickPos = new Point(stage.mouseX, stage.mouseY);
		stage.addEventListener(Event.MOUSE_LEAVE, onMouseUp);
		stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}
	
	function onMouseUp(e:Event) 
	{
		stage.removeEventListener(Event.MOUSE_LEAVE, onMouseUp);
		stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}
	
	function onMouseMove(e:MouseEvent) 
	{
		var deltaX = stage.mouseX - clickPos.x;
		var deltaY = stage.mouseY - clickPos.y;
		SharedModel.cameraPos.x += deltaX;
		SharedModel.cameraPos.y += deltaY;
		SharedModel.updateWorld();
		clickPos.x = stage.mouseX;
		clickPos.y = stage.mouseY;
	}
	
	function onEnterFrame(e:Event) 
	{
		SharedModel.currentFrame++;
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
	}
	
	function zeroZoom(e:MouseEvent) 
	{
		SharedModel.zoom = 1;
		SharedModel.cameraPos.x = 0;
		SharedModel.cameraPos.y = 0;
		SharedModel.updateWorld();
	}
	
	function setAnimation(name:String) 
	{
		SharedModel.playback.currentAnimation = SharedModel.animations.single(function(f) return f.name.toLowerCase() == name.toLowerCase());
	}
	
	
	function onMouseWheel(e:MouseEvent) 
	{
		var delta = e.delta;
		SharedModel.zoom += delta * 0.02;
		SharedModel.zoom = Math.max(0.01, SharedModel.zoom);
		SharedModel.updateWorld();
	}
	
	function onKeyDown(e:KeyboardEvent) 
	{
		if (stage.focus == null) {
			switch(e.keyCode) {
				case Keyboard.SPACE:
					boneRenderer.drawBones = !boneRenderer.drawBones;
					SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
				case Keyboard.LEFT:
					boneRenderer.nudgeLeft();
				case Keyboard.RIGHT:
					boneRenderer.nudgeRight();
				case Keyboard.UP:
					boneRenderer.nudgeUp();
				case Keyboard.DOWN:
					boneRenderer.nudgeDown();
				case Keyboard.L:
					boneRenderer.drawLabels = !boneRenderer.drawLabels;
					SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
				case Keyboard.B:
					cycleBackground();
				case Keyboard.NUMBER_0:
					zeroTransforms();
			}
		}
	}
	
	function cycleBackground() 
	{
		backgroundColors.push(backgroundColors.shift());
		redrawOrigo();
	}
	
	function zeroTransforms() 
	{
		if (SharedModel.selection == null) return;
		SharedModel.selection.rotation = 0;
		SharedModel.selection.scale.x = 1;
		SharedModel.selection.scale.y = 1;
		SharedModel.onChanged.dispatch(SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	
	function toggleLabels() 
	{
		drawLabels = !drawLabels;
	}
	
	function onStageResize(e:Event = null) 
	{
		boneRenderer.x = tileRenderer.x = stage.stageWidth / 2;
		boneRenderer.y = tileRenderer.y = stage.stageHeight / 2;
		redrawOrigo();
	}
	
	function redrawOrigo() 
	{
		var ox = SharedModel.cameraPos.x;
		var oy = SharedModel.cameraPos.y;
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
	
	function onWindowClosing(e:Event) 
	{
		NativeApplication.nativeApplication.exit(0);
	}
	
}