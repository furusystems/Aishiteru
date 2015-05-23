package bonewagon.tools;
import bonewagon.Main;
import bonewagon.model.animation.Animation;
import bonewagon.model.animation.AnimationTarget;
import bonewagon.model.animation.ScriptKey;
import bonewagon.model.animation.SRT;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
import bonewagon.tools.timeline.Channel;
import bonewagon.tools.timeline.ScriptChannel;
import bonewagon.tools.timeline.TimeRuler;
import bonewagon.view.DrawItem;
import com.furusystems.fl.gui.Button;
import com.furusystems.fl.gui.compound.Stepper;
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

using extensions.FloatUtils;
/**
 * ...
 * @author Andreas Rønning
 */
class Timeline extends Sprite
{
	var render:Shape;
	var overlays:Shape;
	var timeRuler:TimeRuler;
	var clickPoint:Point;
	var mousePoint:Point;
	var mouseDelta:Point;
	
	public var nw:NativeWindow;
	
	public var viewMatrix:Matrix = new Matrix();
	
	public var mouseButton:Int = -1;
	public var mouseDown:Bool = false;
	
	public var selectedKey:SRT = null;
	public var selectedScript:ScriptKey = null;
	
	public var playhead:Shape = new Shape();
	
	public var rangeSeconds:Point = new Point(0, 10);
	public var focusTime:Float = 0;
	public var zoomValue:Float = 1;
	public var voidSize:Float = 0.025;
	
	var _timeSeconds:Float = 0;
	var _playing:Bool = false;
	var playButton:Button;
	var channelViews:Array<Channel> = new Array<Channel>();
	var res:Float = 1000; //snap to 1000ths
	
	var channelViewContainer:Sprite = new Sprite();
	var resolutionStepper:Stepper;
	
	public function new(main:Main) 
	{
		super();
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
		playButton = new Button("Play");
		playButton.addEventListener(MouseEvent.MOUSE_DOWN, onPlayButton);
		resolutionStepper = new Stepper();
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
	
	function onResolutionChange(e:Event) 
	{
		res = resolutionStepper.value;
		redraw();
	}
	
	function onPlayButton(e:MouseEvent) 
	{
		playing = !playing;
	}
	
	
	function onModelChanged(flags:Int, data:Dynamic) 
	{
		if (flags & SharedModel.LOAD != 0||  flags & SharedModel.ANIMATION_LIST != 0) {
			reinit();
			return;
		}
		if (flags & SharedModel.ANIMATION_WEIGHT != 0) {
			drive();
		}
		if (SharedModel.playback.currentAnimation == null) return;
		var newTargetCreated:Bool = false;
		if (flags & SharedModel.BONES != 0) {
			trace("Bone changed: " + data);
			playing = false;
			var a:Animation = SharedModel.playback.currentAnimation;
			var isBasePose:Bool = a == SharedModel.basePose;
			var existingTarget:AnimationTarget = null;
			//is there a target for the current bone?
			var i = a.targets.length;
			while(i-- > 0 ) 
			{
				if (a.targets[i].boneID == data) {
					existingTarget = a.targets[i];
					break;
				}
			}
			if (existingTarget == null) {
				//no target for bone, creating new
				existingTarget = new AnimationTarget();
				existingTarget.boneID = Std.int(data);
				a.targets.push(existingTarget);
				newTargetCreated = true;
				trace("creating new target"+existingTarget.getBone().name);
			}else {
				trace("exisitng target: " + existingTarget.getBone().name);
				trace(SharedModel.skeleton.allBones);
			}
			var b:Bone = SharedModel.skeleton.allBones[existingTarget.boneID];
			//is there an existing srt at the current time?
			var updated:Bool = false;
			var ts = isBasePose?0:timeSeconds;
			for (srt in existingTarget.srts) 
			{
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
		if (flags & SharedModel.META != 0) {
			updateNames();
		}
		if (flags & SharedModel.STRUCTURE != 0 || newTargetCreated) {
			rebuildTargets();
		}
		redraw();
	}
	
	function updateNames() 
	{
		for (c in channelViews) 
		{
			c.cname.nameField.text = SharedModel.skeleton.allBones[c.target.boneID].name;
		}
	}
	
	public function updateTargets() {
		for (c in channelViews) 
		{
			c.drawTarget(rangeSeconds.x,rangeSeconds.y);
		}
	}
	
	function rebuildTargets() 
	{
		while (channelViews.length > 0) channelViews.pop().dispose();
		if (SharedModel.playback.currentAnimation == null) return;
		SharedModel.playback.currentAnimation.validate(); //ensure no targets exist for nonexistent bones
		var v:Channel = new ScriptChannel(this);
		v.cname.nameField.text = "Scripts";
		v.setSize(stage.stageWidth);
		cast(v, ScriptChannel).populate(SharedModel.playback.currentAnimation);
		channelViews.push(v);
		channelViewContainer.addChild(v).y = 0;
		
		var i = 0;
		for (t in SharedModel.playback.currentAnimation.targets) 
		{
			v = new Channel();
			v.target = t;
			v.cname.nameField.text = v.target.getBone().name;
			v.setSize(stage.stageWidth);
			channelViews.push(v);
			channelViewContainer.addChild(v).y = (i++) * 20;
		}
	}
	
	function reinit() 
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
	
	function onMouseMove2(e:MouseEvent) 
	{
		timeRuler.mouse.x = stage.mouseX;
		timeRuler.mouse.text = mouseToSeconds().toPrecision(3) + "";
		timeRuler.mouse.y = stage.stageHeight - 20;
	}
	
	function onMouseWheel(e:MouseEvent) 
	{
		if(stage.mouseX > 60){
			var delta = e.delta / 10;
			var ratio = (stage.mouseX-60) / (stage.stageWidth-60);
			rangeSeconds.x += delta * ratio;
			rangeSeconds.y -= delta * (1-ratio);
			rangeSeconds.y = Math.max(rangeSeconds.y, rangeSeconds.y);
		}else {				
			var rect:Rectangle = channelViewContainer.scrollRect;
			rect.y -= e.delta*10;
			var cm = (channelViews.length-1) * 20;
			var margin = cm - (stage.stageHeight - 60);
			rect.y = Math.max(0, Math.min(margin, rect.y));
			channelViewContainer.scrollRect = rect;
		}
		redraw();
	}
	
	public function populate(anim:Animation) 
	{
		redraw();
	}
	function onMouseDown(e:MouseEvent) 
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
			case MouseEvent.RIGHT_MOUSE_DOWN:
				mouseButton = 1;
		}
		mouseDown = true;
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, onMouseUp);
		stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}
	
	function onKeyDown(e:KeyboardEvent) 
	{
		switch(e.keyCode) {
			case Keyboard.BACKSPACE:
				if (SharedModel.playback.selectedKey == null) return;
				deleteKey(SharedModel.playback.selectedKey);
				SharedModel.playback.selectedKey = null;
				drive();
				redraw();
			case Keyboard.SPACE:
				playing = !playing;
			case Keyboard.F:
				frameKeys();
			case Keyboard.C:
				if (e.ctrlKey) {
					copyState();
				}
			case Keyboard.V:
				if (e.ctrlKey) {
					pasteState();
				}
			case Keyboard.RIGHT:
				insertVoid(e.shiftKey);
			case Keyboard.LEFT:
				removeVoid(e.shiftKey);
		}
	}
	
	var copyBuffer:Array<SRT> = null;
	public var main:Main;
	var copyTime:Float = -1;
	
	function copyState() 
	{
		if (SharedModel.playback.currentAnimation == null) return;
		copyTime = timeSeconds;
		copyBuffer = SharedModel.playback.currentAnimation.getPose(timeSeconds, true);
	}
	
	function pasteState() 
	{
		if (copyBuffer == null) return; 
		for (b in copyBuffer) 
		{
			var srt:SRT = b.clone();
			srt.owner.addSampleRaw(srt, timeSeconds);
		}
		redraw();
	}
	
	function frameKeys() 
	{
		rangeSeconds.x = SharedModel.playback.currentAnimation.getMinTime();
		rangeSeconds.y = SharedModel.playback.currentAnimation.getMaxTime();
		redraw();
	}
	
	function insertVoid(fine:Bool) {
		for(key in keysAfterCurrentTime()) {
			key.time += !fine ? voidSize : voidSize * 0.25;
		}
		drive();
	}
	function removeVoid(fine:Bool) {
		for (key in keysAfterCurrentTime()) {
			key.time -= !fine ? voidSize : voidSize * 0.25;
		}
		drive();
	}
	function keysAfterCurrentTime():Array<SRT> {
		var keys:Array<SRT> = SharedModel.playback.currentAnimation.listKeys();
		return keys.filter(keyTimeFilter);
	}
	function keyTimeFilter(item:SRT):Bool {
		return (item.time >= timeSeconds);
	}
	
	public function deleteKey(key:SRT) 
	{
		key.owner.srts.splice(key.owner.srts.indexOf(key, 0), 1);
		key.owner.sortSamples();
		if (key.owner.srts.length == 0) {
			var v:Array<AnimationTarget> = SharedModel.playback.currentAnimation.targets;
			v.splice(v.indexOf(key.owner), 1);
			rebuildTargets();
		}
		redraw();
	}
	
	function onMouseLeave(e:Event) 
	{
		onMouseUp();
	}
	
	function onMouseMove(e:MouseEvent) 
	{
		mouseDelta.x = stage.mouseX - mousePoint.x;
		mouseDelta.y = stage.mouseY - mousePoint.y;
		mousePoint.x = stage.mouseX;
		mousePoint.y = stage.mouseY;
		switch(mouseButton) {
			case 1:
				var ratio = 1/stage.stageWidth * (rangeSeconds.y - rangeSeconds.x);
				rangeSeconds.x -= mouseDelta.x *ratio;
				rangeSeconds.y -= mouseDelta.x * ratio;
				redraw();
			case 0:
				var t = mouseToSeconds();
				if (SharedModel.playback.selectedKey != null) {
					if (e.shiftKey && channelViews.length!=0) {
						var y:Int = Math.floor((channelViewContainer.mouseY + channelViewContainer.scrollRect.y) / 20);
						y = cast Math.max(0, Math.min(y, channelViews.length - 1));
						
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
		}
	}
	
	function doSelect(makeCopy:Bool = false, cycleEase:Bool = false) 
	{
		if (SharedModel.playback.selectedKey != null) {
			SharedModel.playback.selectedKey.selected = false;
		}
		SharedModel.playback.selectedKey = null;
		deselectScript();
		
		if (stage.mouseY <= 20) return;
		var t = mouseToSeconds();
		if (SharedModel.playback.currentAnimation == null) {
			SharedModel.playback.selectedKey = null;
			playing = false;
			timeSeconds = t;
			redraw();
			return;
		}
		if (channelViews.length == 0) return;
		var thresh = 0.01;
		var diff;
		var dist;
		if (stage.mouseY < 40) {
			trace("script area");
			var closestKey:ScriptKey = null;
			for (key in SharedModel.playback.currentAnimation.scripts) 
			{
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
		
		var y:Int = Math.floor((channelViewContainer.mouseY + channelViewContainer.scrollRect.y) / 20);
		y = cast Math.max(0, Math.min(y, channelViews.length - 1));
		var target:AnimationTarget = channelViews[y].target;
		var closest:SRT = null;
		for (s in target.srts) 
		{
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
	public function getNearest(target:AnimationTarget, t:Float, thresh = 0.05):SRT {
		
		if (target.srts.length == 0) return null;
		var closest:SRT = null;
		for (s in target.srts) 
		{
			if (s.time<rangeSeconds.x||s.time>rangeSeconds.y) continue;
			var diff = s.time-t;
			var dist = Math.sqrt(diff * diff);
			if (dist < thresh) {
				closest = s;
			}
			
		}
		return closest;
	}
	
	public function mouseToSeconds() 
	{
		var m = Math.max(0, stage.mouseX - 60);
		var m2 = stage.stageWidth - 60;
		var r = rangeSeconds.x + (m / m2) * (rangeSeconds.y - rangeSeconds.x);
		var f = 1 / res;
		r = Math.round(r / f) * f;
		return r;
	}
	
	
	function onMouseUp(e:MouseEvent = null) 
	{
		mouseDown = false;
		mouseButton = -1;
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
		stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
	}
	
	function onClosing(e:Event) 
	{
		NativeApplication.nativeApplication.exit(0);
	}
	
	function onStageResize(e:Event = null) 
	{
		redraw();
		for (c in channelViews) 
		{
			c.setSize(stage.stageWidth);
		}
	}
	
	function redraw() 
	{
		channelViewContainer.y = 20;
		if (channelViewContainer.scrollRect == null) {
			channelViewContainer.scrollRect = new Rectangle();
		}
		var rect:Rectangle = channelViewContainer.scrollRect;
		rect.width = stage.stageWidth;
		rect.height = stage.stageHeight - 40;
		channelViewContainer.scrollRect = rect;
		timeSeconds = Math.max(rangeSeconds.x, Math.min(rangeSeconds.y, timeSeconds));
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
			var xp = 60+(timeSeconds - rangeSeconds.x) / (rangeSeconds.y - rangeSeconds.x) * (stage.stageWidth-60);
			overlays.graphics.moveTo(xp, 0);
			overlays.graphics.lineTo(xp, stage.stageHeight);
			overlays.graphics.lineStyle();
		}
		if (rangeSeconds.x < 0 && rangeSeconds.y > 0) {
			overlays.graphics.lineStyle(0, 0xFF0000,0.3);
			var xp2 = 60+(0 - rangeSeconds.x) / (rangeSeconds.y - rangeSeconds.x) * (stage.stageWidth-60);
			overlays.graphics.moveTo(xp2, 0);
			overlays.graphics.lineTo(xp2, stage.stageHeight);
		}
		if (SharedModel.playback.currentAnimation == null) return;
		updateTargets();
	}
	public function drive() {
		//if (SharedModel.playback.currentAnimation == null) return;
		SharedModel.playback.applyAnimations(timeSeconds);
		//SharedModel.onChanged.dispatch(SharedModel.ANIMATION);
	}
	
	public function createScript() 
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
	
	public function deselectScript() 
	{
		selectedScript = null;
		main.scriptEditor.hide();
		for(sc in SharedModel.playback.currentAnimation.scripts) 
		{
			sc.selected = false;
		}
	}
	
	public var timeSeconds(get, set):Float;
	
	public function get_timeSeconds() 
	{
		return _timeSeconds;
	}
	
	public function set_timeSeconds(value:Float) 
	{
		_timeSeconds = value;
		drive();
		return _timeSeconds;
	}
	
	public var playing(get, set):Bool;
	
	public function get_playing():Bool 
	{
		return _playing;
	}
	
	public function set_playing(value:Bool) 
	{
		_playing = value;
		if (_playing) {
			stage.addEventListener(Event.ENTER_FRAME, animate);
		}else {
			stage.removeEventListener(Event.ENTER_FRAME, animate);
		}
		return _playing;
	}
	
	function animate(e:Event) 
	{
		var t = timeSeconds + 1 / 60;
		if (t > rangeSeconds.y) {
			t -= rangeSeconds.y - rangeSeconds.x;
		}
		timeSeconds = t;
		redraw();
	}
	
}