package com.furusystems.games.editors.tools 
{
	import com.bit101.components.HBox;
	import com.bit101.components.PushButton;
	import com.bit101.components.VBox;
	import com.furusystems.games.editors.model.animation.Animation;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.tools.clips.ClipView;
	import com.furusystems.logging.slf4as.ILogger;
	import com.furusystems.logging.slf4as.Logging;
	import flash.desktop.NativeApplication;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class AnimationPalette extends Sprite
	{
		private var listContainer:VBox;
		private var addButton:PushButton;
		public var nw:NativeWindow;
		
		public var clipViews:Vector.<ClipView>;
		
		public static const L:ILogger = Logging.getLogger(AnimationPalette);
		public function AnimationPalette() 
		{
			var options:NativeWindowInitOptions = new NativeWindowInitOptions();
			nw = new NativeWindow(options);
			nw.title = "Clips";
			nw.width = 320;
			nw.height = 800;
			nw.activate();
			nw.stage.addChild(this);
			nw.addEventListener(Event.CLOSING, onClosing);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			stage.color = 0x222222;
			
			var allControls:VBox = new VBox(this);
			allControls.spacing = 1;
			var mainControls:HBox = new HBox(allControls);
			addButton = new PushButton(mainControls, 0, 0, "Create");
			addButton.addEventListener(MouseEvent.CLICK, createNewClip);
			
			listContainer = new VBox(allControls);
			listContainer.spacing = 1;
			SharedModel.onChanged.add(onModelChanged);
		}
		
		
		private function createNewClip(e:MouseEvent):void 
		{
			var a:Animation = Animation.fromOb(SharedModel.basePose.serialize());
			SharedModel.playback.currentAnimation = a;
			SharedModel.animations.push(a);
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION | SharedModel.ANIMATION_LIST, a);
		}
		
		private function onModelChanged(flags:int, data:Object):void 
		{
			if (flags & SharedModel.ANIMATION_LIST || flags & SharedModel.LOAD) {
				rebuildList();
			}
		}
		
		private function rebuildList():void 
		{
			clipViews = new Vector.<ClipView>();
			listContainer.removeChildren();
			var c:ClipView = new ClipView(this, SharedModel.basePose,true);
			c.selected = SharedModel.basePose == SharedModel.playback.currentAnimation;
			c.setSize(stage.stageWidth);
			listContainer.addChild(c);
			for (var i:int = 0; i < SharedModel.animations.length; i++) 
			{
				c = new ClipView(this, SharedModel.animations[i]);
				c.setSize(stage.stageWidth);
				listContainer.addChild(c);
				c.selected = SharedModel.animations[i] == SharedModel.playback.currentAnimation;
				clipViews.push(c);
			}
		}
		
		private function onClosing(e:Event):void 
		{
			NativeApplication.nativeApplication.exit(0);
		}
		
		private function onStageResize(e:Event = null):void 
		{
		}
		
	}

}