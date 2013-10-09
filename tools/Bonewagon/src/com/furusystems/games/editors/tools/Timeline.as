package com.furusystems.games.editors.tools 
{
	import com.bit101.components.HBox;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.furusystems.games.editors.Main;
	import com.furusystems.games.editors.model.animation.Animation;
	import com.furusystems.games.editors.model.animation.AnimationTarget;
	import com.furusystems.games.editors.model.animation.ScriptKey;
	import com.furusystems.games.editors.model.animation.SRT;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import com.furusystems.games.editors.tools.timeline.Channel;
	import com.furusystems.games.editors.tools.timeline.ScriptChannel;
	import com.furusystems.games.editors.tools.timeline.TimeRuler;
	import com.furusystems.games.editors.view.DrawItem;
	import com.furusystems.logging.slf4as.ILogger;
	import com.furusystems.logging.slf4as.Logging;
	import flash.desktop.NativeApplication;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Timeline extends Sprite
	{
		private var render:Shape;
		private var overlays:Shape;
		private var timeRuler:TimeRuler;
		private var clickPoint:Point;
		private var mousePoint:Point;
		private var mouseDelta:Point;
		public var nw:NativeWindow;
		
		public static const L:ILogger = Logging.getLogger(Timeline);
		
		public var viewMatrix:Matrix = new Matrix();
		
		public var mouseButton:int = -1;
		public var mouseDown:Boolean = false;
		
		public var selectedKey:SRT = null;
		public var selectedScript:ScriptKey = null;
		
		public var playhead:Shape = new Shape();
		
		public var rangeSeconds:Point = new Point(0, 10);
		private var _timeSeconds:Number = 0;
		public var focusTime:Number = 0;
		public var zoomValue:Number = 1;
		public var voidSize:Number = 0.025;
		private var _playing:Boolean = false;
		private var playButton:PushButton;
		private var channelViews:Vector.<Channel> = new Vector.<Channel>();
		private var res:Number = 1000; //snap to 1000ths
		
		private var channelViewContainer:Sprite = new Sprite();
		private var resolutionStepper:NumericStepper;
		
		public function Timeline(main:Main) 
		{
			this.main = main;
			var options:NativeWindowInitOptions = new NativeWindowInitOptions();
			nw = new NativeWindow(options);
			nw.title = "Timeline";
			nw.width = 800;
			nw.height = 200;
			nw.activate();
			nw.stage.addChild(this);
			nw.addEventListener(Event.CLOSING, onClosing);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			stage.color = 0x333333;
			render = new Shape();
			overlays = new Shape();
			
			
			timeRuler = new TimeRuler();
			addChild(render);
			addChild(channelViewContainer).scrollRect = new Rectangle();
			addChild(timeRuler);
			addChild(playhead);
			addChild(overlays);
			playButton = new PushButton(this, 0, 0, "Play");
			playButton.addEventListener(MouseEvent.MOUSE_DOWN, onPlayButton);
			resolutionStepper = new NumericStepper(this, 0, 0);
			resolutionStepper.value = res;
			resolutionStepper.addEventListener(Event.CHANGE, onResolutionChange);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove2);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			playButton.x = stage.stageWidth - playButton.width;
			playButton.y = stage.stageHeight - playButton.height;
			
			SharedModel.onChanged.add(onModelChanged);
		}
		
		private function onResolutionChange(e:Event):void 
		{
			res = resolutionStepper.value;
			redraw();
		}
		
		private function onPlayButton(e:MouseEvent):void 
		{
			playing = !playing;
		}
		
		
		private function onModelChanged(flags:int, data:Object):void 
		{
			if (flags & SharedModel.LOAD ||  flags & SharedModel.ANIMATION_LIST) {
				reinit();
				return;
			}
			if (flags & SharedModel.ANIMATION_WEIGHT) {
				drive();
			}
			if (SharedModel.playback.currentAnimation == null) return;
			var newTargetCreated:Boolean = false;
			if (flags & SharedModel.BONES) {
				trace("Bone changed: " + data);
				playing = false;
				var a:Animation = SharedModel.playback.currentAnimation;
				var isBasePose:Boolean = a == SharedModel.basePose;
				var existingTarget:AnimationTarget = null;
				//is there a target for the current bone?
				for (var i:int = a.targets.length; i--; ) 
				{
					if (a.targets[i].boneID == data) {
						existingTarget = a.targets[i];
						break;
					}
				}
				if (existingTarget == null) {
					//no target for bone, creating new
					existingTarget = new AnimationTarget();
					existingTarget.boneID = int(data);
					a.targets.push(existingTarget);
					newTargetCreated = true;
					trace("creating new target"+existingTarget.getBone().name);
				}else {
					trace("exisitng target: " + existingTarget.getBone().name);
					trace(SharedModel.skeleton.allBones);
				}
				var b:Bone = SharedModel.skeleton.allBones[existingTarget.boneID];
				//is there an existing srt at the current time?
				var updated:Boolean = false;
				var ts:Number = isBasePose?0:timeSeconds;
				for (var j:int = 0; j < existingTarget.srts.length; j++) 
				{
					var srt:SRT = existingTarget.srts[j];
					if (srt.time == ts) {
						//update existing
						srt = b.getSRT(ts);
						srt.owner = existingTarget;
						existingTarget.srts[j] = srt;
						updated = true;
						break;
					}
				}
				if(!updated) existingTarget.addSample(ts, b);
			}
			if (flags & SharedModel.META) {
				updateNames();
			}
			if (flags & SharedModel.STRUCTURE || newTargetCreated) {
				rebuildTargets();
			}
			redraw();
		}
		
		private function updateNames():void 
		{
			for (var i:int = 0; i < channelViews.length; i++) 
			{
				var cn:Channel = channelViews[i];
				cn.cname.nameField.text = SharedModel.skeleton.allBones[cn.target.boneID].name;
			}
		}
		
		public function updateTargets():void {
			for (var j:int = 0; j < channelViews.length; j++) 
			{
				var c:Channel = channelViews[j];
				c.drawTarget(rangeSeconds.x,rangeSeconds.y);
			}
		}
		
		private function rebuildTargets():void 
		{
			while (channelViews.length > 0) channelViews.pop().dispose();
			if (SharedModel.playback.currentAnimation == null) return;
			SharedModel.playback.currentAnimation.validate(); //ensure no targets exist for nonexistent bones
			var v:Channel = new ScriptChannel(this);
			v.cname.nameField.text = "Scripts";
			v.setSize(stage.stageWidth);
			ScriptChannel(v).populate(SharedModel.playback.currentAnimation);
			channelViews.push(v);
			channelViewContainer.addChild(v).y = 0;
			
			for (var i:int = 0; i < SharedModel.playback.currentAnimation.targets.length; i++) 
			{
				v = new Channel();
				v.target = SharedModel.playback.currentAnimation.targets[i];
				v.cname.nameField.text = v.target.getBone().name;
				v.setSize(stage.stageWidth);
				channelViews.push(v);
				channelViewContainer.addChild(v).y = (i+1) * 20;
			}
		}
		
		private function reinit():void 
		{
			deselectScript();
			selectedKey = null;
			_timeSeconds = 0;
			rangeSeconds.x = 0;
			rangeSeconds.y = 2;
			rebuildTargets();
			redraw();
			drive();
		}
		
		private function onMouseMove2(e:MouseEvent):void 
		{
			timeRuler.mouse.x = stage.mouseX;
			timeRuler.mouse.text = mouseToSeconds().toPrecision(3) + "";
			timeRuler.mouse.y = stage.stageHeight - 20;
		}
		
		private function onMouseWheel(e:MouseEvent):void 
		{
			if(stage.mouseX>60){
				var delta:Number = e.delta / 10;
				var ratio:Number = (stage.mouseX-60) / (stage.stageWidth-60);
				rangeSeconds.x += delta * ratio;
				rangeSeconds.y -= delta * (1-ratio);
				rangeSeconds.y = Math.max(rangeSeconds.y, rangeSeconds.y);
			}else {				
				var rect:Rectangle = channelViewContainer.scrollRect;
				rect.y -= e.delta*10;
				var cm:Number = (channelViews.length-1) * 20;
				var margin:Number = cm - (stage.stageHeight - 60);
				rect.y = Math.max(0, Math.min(margin, rect.y));
				channelViewContainer.scrollRect = rect;
			}
			redraw();
		}
		
		public function populate(anim:Animation):void 
		{
			redraw();
		}
		private function onMouseDown(e:MouseEvent):void 
		{
			if (mouseDown) return;
			clickPoint = new Point(stage.mouseX, stage.mouseY);
			mousePoint = clickPoint.clone();
			mouseDelta = new Point();
			switch(e.type) {
				case MouseEvent.MIDDLE_MOUSE_DOWN:
					mouseButton = 2;
					doSelect();
					if (SharedModel.playback.selectedKey != null) {
						timeSeconds = SharedModel.playback.selectedKey.time;
						redraw();
					}
					return;
				case MouseEvent.MOUSE_DOWN:
					mouseButton = 0;
					doSelect(e.ctrlKey, e.shiftKey);
					break;
				case MouseEvent.RIGHT_MOUSE_DOWN:
					mouseButton = 1;
					break;
			}
			mouseDown = true;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, onMouseUp);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			switch(e.keyCode) {
				case Keyboard.BACKSPACE:
					if (SharedModel.playback.selectedKey == null) return;
					deleteKey(SharedModel.playback.selectedKey);
					SharedModel.playback.selectedKey = null;
					drive();
					redraw();
					break;
				case Keyboard.SPACE:
					playing = !playing;
					break;
				case Keyboard.F:
					frameKeys();
					break;
				case Keyboard.C:
					if (e.ctrlKey) {
						copyState();
					}
					break;
				case Keyboard.V:
					if (e.ctrlKey) {
						pasteState();
					}
					break;
				case Keyboard.RIGHT:
						insertVoid(e.shiftKey);
					break;
				case Keyboard.LEFT:
						removeVoid(e.shiftKey);
					break;
			}
		}
		
		private var copyBuffer:Vector.<SRT> = null;
		public var main:Main;
		private var copyTime:Number = -1;
		
		private function copyState():void 
		{
			if (SharedModel.playback.currentAnimation == null) return;
			copyTime = timeSeconds;
			copyBuffer = SharedModel.playback.currentAnimation.getPose(timeSeconds, true);
		}
		
		private function pasteState():void 
		{
			if (copyBuffer == null) return; 
			for (var i:int = 0; i < copyBuffer.length; i++) 
			{
				var srt:SRT = copyBuffer[i].clone();
				srt.owner.addSampleRaw(srt, timeSeconds);
			}
			redraw();
		}
		
		private function frameKeys():void 
		{
			rangeSeconds.x = SharedModel.playback.currentAnimation.minTime;
			rangeSeconds.y = SharedModel.playback.currentAnimation.maxTime;
			redraw();
		}
		
		private function insertVoid(fine:Boolean):void {
			for each(var key:SRT in keysAfterCurrentTime()) {
				key.time += !fine?voidSize:voidSize*0.25;
			}
			drive();
		}
		private function removeVoid(fine:Boolean):void {
			for each(var key:SRT in keysAfterCurrentTime()) {
				key.time -= !fine?voidSize:voidSize*0.25;
			}
			drive();
		}
		private function keysAfterCurrentTime():Vector.<SRT> {
			var keys:Vector.<SRT> = SharedModel.playback.currentAnimation.listKeys();
			return keys.filter(keyTimeFilter);
		}
		private function keyTimeFilter(item:SRT, index:int, vector:Vector.<SRT>):Boolean {
			return (item.time >= timeSeconds);
		}
		
		public function deleteKey(key:SRT):void 
		{
			key.owner.srts.splice(key.owner.srts.indexOf(key, 0), 1);
			key.owner.sortSamples();
			if (key.owner.srts.length == 0) {
				var v:Vector.<AnimationTarget> = SharedModel.playback.currentAnimation.targets;
				v.splice(v.indexOf(key.owner), 1);
				rebuildTargets();
			}
			redraw();
		}
		
		private function onMouseLeave(e:Event):void 
		{
			onMouseUp();
		}
		
		private function onMouseMove(e:MouseEvent):void 
		{
			mouseDelta.x = stage.mouseX - mousePoint.x;
			mouseDelta.y = stage.mouseY - mousePoint.y;
			mousePoint.x = stage.mouseX;
			mousePoint.y = stage.mouseY;
			switch(mouseButton) {
				case 1:
					var ratio:Number = 1/stage.stageWidth * (rangeSeconds.y - rangeSeconds.x);
					rangeSeconds.x -= mouseDelta.x *ratio;
					rangeSeconds.y -= mouseDelta.x * ratio;
					redraw();
					break;
				case 0:
					var t:Number = mouseToSeconds();
					if (SharedModel.playback.selectedKey != null) {
						if (e.shiftKey && channelViews.length!=0) {
							var y:int = Math.floor((channelViewContainer.mouseY + channelViewContainer.scrollRect.y) / 20);
							y = Math.max(0, Math.min(y, channelViews.length - 1));
							
							//find nearest
							var nearest:SRT = getNearest(channelViews[y].target, t);
							if (nearest != null) {
								t = nearest.time;
							}
						}
						SharedModel.playback.selectedKey.time = t;
						SharedModel.playback.selectedKey.owner.sortSamples();
						drive();
					}else if (selectedScript != null) {
						selectedScript.time = t;
					}else {
						timeSeconds = mouseToSeconds();
						playing = false;
					}
					redraw();
					break;
			}
		}
		
		private function doSelect(makeCopy:Boolean = false, cycleEase:Boolean = false):void 
		{
			if (SharedModel.playback.selectedKey != null) {
				SharedModel.playback.selectedKey.selected = false;
			}
			SharedModel.playback.selectedKey = null;
			deselectScript();
			
			if (stage.mouseY <= 20) return;
			var t:Number = mouseToSeconds();
			if (SharedModel.playback.currentAnimation == null) {
				SharedModel.playback.selectedKey = null;
				playing = false;
				timeSeconds = t;
				redraw();
				return;
			}
			if (channelViews.length == 0) return;
			var i:int;
			var thresh:Number = 0.01;
			var diff:Number;
			var dist:Number;
			if (stage.mouseY < 40) {
				trace("script area");
				var closestKey:ScriptKey = null;
				for (i = 0; i < SharedModel.playback.currentAnimation.scripts.length; i++) 
				{
					var key:ScriptKey= SharedModel.playback.currentAnimation.scripts[i];
					if (key.time<rangeSeconds.x||key.time>rangeSeconds.y) continue;
					diff = key.time-t;
					dist = Math.sqrt(diff * diff);
					if (dist < thresh) {
						closestKey = key;
					}
				}
				if (closestKey != null) {
					closestKey.selected = true;
					main.scriptEditor.populate(closestKey);
					selectedScript = closestKey;
				}
				return;
			}
			
			var y:int = Math.floor((channelViewContainer.mouseY + channelViewContainer.scrollRect.y) / 20);
			y = Math.max(0, Math.min(y, channelViews.length - 1));
			var target:AnimationTarget = channelViews[y].target;
			var closest:SRT = null;
			for (i = 0; i < target.srts.length; i++) 
			{
				var s:SRT = target.srts[i];
				if (s.time<rangeSeconds.x||s.time>rangeSeconds.y) continue;
				diff = s.time-t;
				dist = Math.sqrt(diff * diff);
				if (dist < thresh) {
					closest = s;
				}
				
			}
			if (closest != null) {
				SharedModel.playback.selectedKey = closest;
			}else {
				SharedModel.playback.selectedKey = null;
			}
			if (SharedModel.playback.selectedKey != null && makeCopy) {
				SharedModel.playback.selectedKey = SharedModel.playback.selectedKey.clone();
				target.addSampleRaw(SharedModel.playback.selectedKey, SharedModel.playback.selectedKey.time);
			}
			if (SharedModel.playback.selectedKey != null && cycleEase) {
				SharedModel.playback.selectedKey.cycleEasing();
			}
			redraw();
		}
		public function getNearest(target:AnimationTarget, t:Number, thresh:Number = 0.05):SRT {
			
			if (target.srts.length == 0) return null;
			var closest:SRT = null;
			for (var i:int = 0; i < target.srts.length; i++) 
			{
				var s:SRT = target.srts[i];
				if (s.time<rangeSeconds.x||s.time>rangeSeconds.y) continue;
				var diff:Number = s.time-t;
				var dist:Number = Math.sqrt(diff * diff);
				if (dist < thresh) {
					closest = s;
				}
				
			}
			return closest;
		}
		
		public function mouseToSeconds():Number 
		{
			var m:Number = Math.max(0, stage.mouseX - 60);
			var m2:Number = stage.stageWidth - 60;
			var r:Number = rangeSeconds.x + (m / m2) * (rangeSeconds.y - rangeSeconds.x);
			var f:Number = 1 / res;
			r = Math.round(r / f) * f;
			return r;
		}
		
		
		private function onMouseUp(e:MouseEvent = null):void 
		{
			mouseDown = false;
			mouseButton = -1;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		private function onClosing(e:Event):void 
		{
			NativeApplication.nativeApplication.exit(0);
		}
		
		private function onStageResize(e:Event = null):void 
		{
			redraw();
			for (var i:int = 0; i < channelViews.length; i++) 
			{
				channelViews[i].setSize(stage.stageWidth);
			}
		}
		
		private function redraw():void 
		{
			channelViewContainer.y = 20;
			if (channelViewContainer.scrollRect == null) {
				channelViewContainer.scrollRect = new Rectangle();
			}
			var rect:Rectangle = channelViewContainer.scrollRect;
			rect.width = stage.stageWidth;
			rect.height = stage.stageHeight - 40;
			channelViewContainer.scrollRect = rect;
			//timeSeconds = Math.max(rangeSeconds.x, Math.min(rangeSeconds.y, timeSeconds));
			playButton.x = stage.stageWidth - playButton.width;
			playButton.y = stage.stageHeight - playButton.height;
			resolutionStepper.y = stage.stageHeight - resolutionStepper.height;
			timeRuler.min.text = rangeSeconds.x.toPrecision(3) + "";
			timeRuler.max.text = rangeSeconds.y.toPrecision(3) + "";
			timeRuler.current.text = timeSeconds.toPrecision(3) + "";
			timeRuler.redraw();
			render.graphics.clear();
			render.graphics.moveTo(60, 0);
			render.graphics.lineStyle(0, 0);
			render.graphics.lineTo(60, stage.stageHeight - 20);
			render.graphics.moveTo(0, stage.stageHeight - 20);
			render.graphics.lineTo(stage.stageWidth, stage.stageHeight - 20);
			render.graphics.moveTo(0, 20);
			render.graphics.lineTo(stage.stageWidth, 20);
			render.graphics.lineStyle();
			
			overlays.graphics.clear();
			if (timeSeconds >= rangeSeconds.x && timeSeconds <= rangeSeconds.y) {
				overlays.graphics.lineStyle(3, 0x808080, 0.5);
				var xp:Number = 60+(timeSeconds - rangeSeconds.x) / (rangeSeconds.y - rangeSeconds.x) * (stage.stageWidth-60);
				overlays.graphics.moveTo(xp, 0);
				overlays.graphics.lineTo(xp, stage.stageHeight);
				overlays.graphics.lineStyle();
			}
			if (rangeSeconds.x < 0 && rangeSeconds.y > 0) {
				overlays.graphics.lineStyle(0, 0xFF0000,0.3);
				var xp2:Number = 60+(0 - rangeSeconds.x) / (rangeSeconds.y - rangeSeconds.x) * (stage.stageWidth-60);
				overlays.graphics.moveTo(xp2, 0);
				overlays.graphics.lineTo(xp2, stage.stageHeight);
			}
			if (SharedModel.playback.currentAnimation == null) return;
			updateTargets();
		}
		public function drive():void {
			//if (SharedModel.playback.currentAnimation == null) return;
			SharedModel.playback.applyAnimations(timeSeconds);
			//SharedModel.onChanged.dispatch(SharedModel.ANIMATION);
		}
		
		public function createScript():void 
		{
			deselectScript();
			if (SharedModel.playback.currentAnimation == null) return;
			if (SharedModel.playback.currentAnimation == SharedModel.basePose) return;
			var s:ScriptKey = new ScriptKey();
			s.time = mouseToSeconds();
			s.selected = true;
			SharedModel.playback.currentAnimation.scripts.push(s);
			main.scriptEditor.populate(s);
			selectedScript = s;
		}
		
		public function deselectScript():void 
		{
			selectedScript = null;
			main.scriptEditor.hide();
			for each(var sc:ScriptKey in SharedModel.playback.currentAnimation.scripts) 
			{
				sc.selected = false;
			}
		}
		
		public function get timeSeconds():Number 
		{
			return _timeSeconds;
		}
		
		public function set timeSeconds(value:Number):void 
		{
			_timeSeconds = value;
			drive();
		}
		
		public function get playing():Boolean 
		{
			return _playing;
		}
		
		public function set playing(value:Boolean):void 
		{
			_playing = value;
			if (_playing) {
				stage.addEventListener(Event.ENTER_FRAME, animate);
			}else {
				stage.removeEventListener(Event.ENTER_FRAME, animate);
			}
		}
		
		private function animate(e:Event):void 
		{
			var t:Number = timeSeconds + 1 / 60;
			if (t > rangeSeconds.y) {
				t -= rangeSeconds.y - rangeSeconds.x;
			}
			timeSeconds = t;
			redraw();
		}
		
	}

}