package com.furusystems.games.rendering.animation.characters;
import com.chromaagency.paperpals.entities.Entity;
import com.furusystems.events.Signal;
import com.furusystems.games.gameobject.GameObject;
import com.furusystems.games.input.TouchPoint;
import com.furusystems.games.rendering.animation.characters.vo.Bone;
import com.furusystems.games.rendering.animation.characters.vo.Sample;
import com.furusystems.games.rendering.animation.gts.GTSManager;
import com.furusystems.games.rendering.animation.gts.GTSSheet;
import com.furusystems.games.rendering.Camera;
import com.furusystems.games.rendering.DrawInstruction;
import com.furusystems.games.rendering.animation.LoopStyle;
import com.furusystems.games.rendering.animation.TransitionStyle;
import com.furusystems.games.vos.RenderInfo;
import com.furusystems.games.vos.UpdateInfo;
import haxe.xml.Fast;
import openfl.Assets;
import flash.display.Graphics;
import flash.Vector;
import flash.geom.Point;
/**
 * ...
 * @author Andreas Rønning
 */
class Character extends Entity implements DrawInstruction
{

	public var gts:GTSSheet;
	public var animation:AnimPackage;
	#if haxe3
	public var joints:Map<Int,Joint>;
	#else
	public var joints:Map<Int, Joint>;
	#end
	var drawStack:Array<DrawItem>;
	
	public var transitionTime:Float = 0;
	public var transitionDuration:Float = 1;
	
	public var currentAnimation:Animation;
	public var currentAnimationFrame:Int = 0;
	var currentLoopStyle:LoopStyle;
	var currentAnimationTime:Float = 0;
	var currentPlayDirection:Int = 1;
	
	public var prevAnimation:Animation;
	public var prevAnimationFrame:Int = 0;
	var prevAnimationTime:Float = 0;
	var prevLoopStyle:LoopStyle;
	var prevPlayDirection:Int = 1;
	
	var uvs:Vector<Float>;
	var indices:Vector<Int>;
	var verts:Vector<Float>;
	var root:Joint;
	
	public var onAnimationStop:Signal<Character>;
	public var onAnimationLoop:Signal<Character>;
	public var onTransitionComplete:Signal<Character>;
	public var onScriptEvent:Signal<ScriptEvent>;
	public var isPlaying:Bool;
	
	
	public function new(gts:GTSSheet, anim:AnimPackage) 
	{
		super(null);
		this.gts = gts;
		this.animation = anim;
		drawStack = [];
		onAnimationStop = null;
		#if haxe3
		joints = new Map<Int,Joint>();
		#else
		joints = new Map<Int, Joint>();
		#end
		
		currentLoopStyle = LoopStyle.once;
		prevLoopStyle = LoopStyle.normal;
		
		transform.inheritTransform = true;
		
		onAnimationLoop = new Signal<Character>();
		onAnimationStop = new Signal<Character>();
		onTransitionComplete = new Signal<Character>();
		onScriptEvent = new Signal<ScriptEvent>();
		
		trace("Generating joints");
		root = genJoint(animation.skeleton);
		trace("Joints ready");
		
		renderinfo.customInstruction = this;
		
		verts = new Vector<Float>();
		indices = new Vector<Int>();
		uvs = new Vector<Float>();
		
		if (animation.animations.length > 0) {
			setAnimation(animation.animations[0], false);
		}
		
		for (d in drawStack) {
			d.update(0,0);
		}
		drawStack.sort(sortDrawStack);
	}
	public function getBoneByName(name:String):Bone {
		#if debug
		var b = animation.skeleton.getBoneByName(name);
		trace(name + ", " + b.name);
		return b;
		#else
		return animation.skeleton.getBoneByName(name);
		#end
	}
	
	function genJoint(bone:Bone):Joint 
	{
		var joint = new Joint(bone);
		joints.set(joint.id, joint);
		drawStack.push(new DrawItem(joint, gts));
		for (b in bone.children) {
			var child = genJoint(b);
			child.parent = joint;
			joint.children.push(child);
		}
		return joint;
	}
	
	function applyAnimation():Void 
	{
		currentAnimationFrame = cast Math.max(0, Math.min(currentAnimation.frames.length-1, Math.floor(currentAnimationTime / currentAnimation.duration * currentAnimation.frames.length)));
		
		if (prevAnimation == null) {
			for (i in currentAnimation.frames[currentAnimationFrame]) {
				applySample(i);
			}
		}else {
			prevAnimationFrame = cast Math.max(0, Math.min(prevAnimation.frames.length-1, Math.floor(prevAnimationTime / prevAnimation.duration * prevAnimation.frames.length)));
			
			if (transitionTime >= transitionDuration) {
				prevAnimation = null;
				onTransitionComplete.dispatch(this);
				applyAnimation();
			}else {
				var weight:Float = transitionTime / transitionDuration;
				for (s in currentAnimation.frames[currentAnimationFrame]) {
					addSample(s, weight, true);
				}
				for (s in prevAnimation.frames[prevAnimationFrame]) {
					addSample(s, 1-weight, false);
				}
			}
		}
		
		
	}
	
	inline function addSample(a:Sample, weight:Float, zero:Bool):Void {
		var j = joints.get(a.boneID);
		if (zero) j.zeroSRT();
		j.addSRT(a, weight);
		j.z = a.z;
		j.frame = a.sequenceFrame;
		j.sequence = a.sequenceName;
	}
	
	inline function applySample(s:Sample):Void {
		var j:Joint = joints.get(s.boneID);
		j.setSRT(s);
		j.z = s.z;
		j.frame = s.sequenceFrame;
		j.sequence = s.sequenceName;
	}
	
	public function updateAnimation(delta:Float) 
	{
		if (!isPlaying) return;
		for (i in currentAnimation.scriptEvents) 
		{
			if(currentPlayDirection==1){
				if (i.time < currentAnimationTime && !i.hasTriggered) {
					i.hasTriggered = true;
					onScriptEvent.dispatch(i);
				}
			}else if (currentPlayDirection == -1) {
				if (i.time > currentAnimationTime && !i.hasTriggered) {
					i.hasTriggered = true;
					onScriptEvent.dispatch(i);
				}
			}
		}
		if(currentAnimation!=null){
			currentAnimationTime += currentPlayDirection * delta;
			if (currentAnimationTime > currentAnimation.duration || currentAnimationTime < 0) {
				currentAnimation.init();
				switch(currentLoopStyle) {
					case LoopStyle.normal:
						currentAnimationTime -= currentAnimationTime;
						trace("loop");
						onAnimationLoop.dispatch(this);
					case LoopStyle.once:
						currentAnimationTime = currentAnimation.duration;
						currentPlayDirection = 0;
						isPlaying = false;
						onAnimationStop.dispatch(this);
					case LoopStyle.pingpong:
						currentPlayDirection = -currentPlayDirection;
						onAnimationLoop.dispatch(this);
				}
				
			}
		}
		if (prevAnimation != null) {
			prevAnimationTime += prevPlayDirection*delta;
			if (prevAnimationTime > prevAnimation.duration || prevAnimationTime < 0) {
				switch(prevLoopStyle) {
					case LoopStyle.normal:
						prevAnimationTime -= prevAnimationTime;
					case LoopStyle.once:
						prevAnimationTime = prevAnimation.duration;
						prevPlayDirection = 0;
					case LoopStyle.pingpong:
						prevPlayDirection = -prevPlayDirection;
				}
			}
			transitionTime += delta;
		}
		applyAnimation();
	}
	
	public function draw(g:Graphics,info:RenderInfo, camera:Camera):Void {
		finish(g);
	}
	
	override public function preRender(info:UpdateInfo):Void 
	{
		#if characters
		applyAnimation();
		transform.updateMatrix();
		root.updateMatrices(transform.matrix);
		for (i in drawStack) {
			i.update(info.camera.derivedX * transform.z + offsetX, info.camera.derivedY * transform.z + offsetY);
		}
		#end
	}
	override public function postUpdate(info:UpdateInfo):Void 
	{
		updateAnimation(info.scaledDelta);
		super.postUpdate(info);
	}
	
	public function drawManual(g:Graphics):Void {
		applyAnimation();
		transform.updateMatrix();
		root.updateMatrices(transform.matrix);
		for (i in drawStack) {
			i.update();
		}
		finish(g);
	}
	
	inline function finish(g:Graphics):Void {
		var indexOffset:Int = 0;
		var indexPos:Int = 0;
		var uvPos:Int = 0;
		for (i in 0...drawStack.length) 
		{
			var item = drawStack[i];
			if(item.joint.sequence!="n/a"){
				indices[indexPos] = indexOffset;
				indices[indexPos + 1] = 1 + indexOffset;
				indices[indexPos + 2] = 2 + indexOffset;
				indices[indexPos + 3] = indexOffset;
				indices[indexPos + 4] = 2 + indexOffset;
				indices[indexPos + 5] = 3 + indexOffset;
				
				uvs[uvPos] = item.uvs[0];
				uvs[uvPos + 1] = item.uvs[1];
				uvs[uvPos + 2] = item.uvs[2];
				uvs[uvPos + 3] = item.uvs[3];
				uvs[uvPos + 4] = item.uvs[4];
				uvs[uvPos + 5] = item.uvs[5];
				uvs[uvPos + 6] = item.uvs[6];
				uvs[uvPos + 7] = item.uvs[7];
				
				verts[uvPos] = item.vertices[0];
				verts[uvPos+1] = item.vertices[1];
				verts[uvPos+2] = item.vertices[2];
				verts[uvPos+3] = item.vertices[3];
				verts[uvPos+4] = item.vertices[4];
				verts[uvPos+5] = item.vertices[5];
				verts[uvPos+6] = item.vertices[6];
				verts[uvPos+7] = item.vertices[7];
				indexOffset += 4;
				indexPos += 6;
				uvPos += 8;
			}
		}
		g.beginBitmapFill(gts.texture, null, false, true);
		g.drawTriangles(verts, indices, uvs);
		g.endFill();
	}
	
	override public function render(info:UpdateInfo):Void 
	{
		#if characters
		if (visible) info.renderList.add(this.renderinfo);
		#end
	}
	
	function sortDrawStack(a:DrawItem, b:DrawItem):Int 
	{
		if (a.zPos < b.zPos) return -1;
		if (a.zPos > b.zPos) return 1;
		return 0;
	}
	
	override public function dispose():Void 
	{
		onAnimationLoop.dispose();
		onAnimationStop.dispose();
		onTransitionComplete.dispose();
		super.dispose();
	}
	
	
	static public function create(mgr:GTSManager, data:Fast):Character 
	{
		var desc:Fast = new Fast(Xml.parse(Assets.getText(data.innerData)));
		var out:Character = mgr.loadCharacter(desc.node.data.node.gts.innerData, desc.node.data.node.animationdata.innerData);
		out.transform.x = Std.parseFloat(data.att.x);
		out.transform.y = Std.parseFloat(data.att.y);
		out.transform.z = Std.parseFloat(data.att.z);
		out.transform.scale = Std.parseFloat(data.att.scale);
		if (data.has.flipx) { out.transform.scaleX = -1; }
		out.name = out.id = data.att.id;
		return out;
	}
	
	/**
	 * Animation API
	 */
	
	
	public function play(fromStart:Bool = true, direction:Int = 1):Void {
		currentPlayDirection = direction;
		if (fromStart) {
			currentAnimation.init();
			currentAnimationTime = 0;
		}
		isPlaying = true;
	}
	public function stop():Void {
		isPlaying = false;
	}
	public function setPlayTime(seconds:Float):Void {
		currentAnimationTime = Math.max(0, Math.min(currentAnimation.duration, seconds));
		for (i in currentAnimation.scriptEvents) 
		{
			i.hasTriggered = i.time < currentAnimationTime;
		}
	}
	 
	 
	public function setAnimationByName(name:String, autoplay:Bool = true, ?loopstyle:LoopStyle, ?transitionStyle:TransitionStyle, transitionDuration:Float = 0):Void
	{
		for (a in animation.animations)
		{
			if (a.name.toLowerCase() == name.toLowerCase()) {
				switchAnimation(a, autoplay, loopstyle, transitionStyle, transitionDuration);
				return;
			}
		}
	}
	
	public function setAnimation(anim:Animation, autoplay:Bool = true, ?loopstyle:LoopStyle):Animation
	{
		if (loopstyle == null) loopstyle = LoopStyle.normal;
		trace("Setting animation: " + anim.name + " (" + loopstyle + ")");
		anim.init();
		currentAnimationTime = prevAnimationTime = 0;
		currentAnimation = anim;
		currentLoopStyle = loopstyle;
		currentPlayDirection = 1;
		if (autoplay) play();
		applyAnimation();
		return currentAnimation;
	}
	
	public function switchAnimation(next:Animation, autoplay:Bool = true, ?loopstyle:LoopStyle, ?transitionStyle:TransitionStyle, transitionDuration:Float = 0):Void {
		trace("Switching animation: " + next.name);
		if (loopstyle == null) loopstyle = LoopStyle.normal;
		if (transitionStyle == null) transitionStyle = TransitionStyle.NONE;
		//if there is no transition time
		transitionDuration = Math.max(0, transitionDuration);
		if (transitionDuration == 0 || transitionStyle==TransitionStyle.NONE) {
			setAnimation(next, autoplay, loopstyle);
			return;
		}
		next.init();
		transitionTime = 0;
		this.transitionDuration = transitionDuration;
		
		//Set the new animation as current, move current to previous, switch clocks and loopstyles
		prevLoopStyle = currentLoopStyle;
		prevPlayDirection = currentPlayDirection;
		prevAnimation = currentAnimation;
		prevAnimationFrame = currentAnimationFrame; 
		prevAnimationTime = currentAnimationTime;
		
		currentLoopStyle = loopstyle;
		currentAnimation = next;
		currentPlayDirection = 1;
		currentAnimationFrame = 0;
		currentAnimationTime = 0;
		if (autoplay) play();
	}
}