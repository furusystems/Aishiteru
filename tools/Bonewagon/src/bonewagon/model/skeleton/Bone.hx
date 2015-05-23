package bonewagon.model.skeleton;
import bonewagon.model.animation.SRT;
import bonewagon.model.SharedModel;
import flash.geom.Matrix;
import flash.geom.Point;
/**
 * ...
 * @author Andreas Rønning
 */

enum Axis {
	X;
	Y;
}
 
class Bone 
{
	public static var uidPool:Int = 0;
	
	public var name:String;
	public var children:Array<Bone> = new Array<Bone>();
	public var localTransform:Matrix = new Matrix();
	public var parent:Bone = null;
	
	public var position:Point = new Point();
	public var globalPosition:Point = new Point();
	public var scale:Point = new Point(1,1);
	public var globalScale:Point = new Point(1,1);
	public var rotation:Float = 0;
	public var globalRotation:Float = 0;
	
	public var localOffset:Point = new Point();
	
	public var gtsSequence:String = "n/a";
	public var gtsSequenceFrame:Int = 0;
	
	public var color:Int = cast (Math.random() * 0xFFFFFF);
	public var z:Float = 0;
	
	public var boneID:Int = -1;
	
	public function new(name:String = "", init:Bool = true) 
	{
		if(init){
			boneID = uidPool++; //some globally unique ID generation?
			if (name == "") {
				name = "Bone" + (boneID);
			}
			trace("New bone: " + boneID);
			this.name = name;
		}
	}
	
	public function getDepth():Int {
		var out:Int = 1;
		for (c in children) 
		{
			out += c.getDepth();
		}
		return out;
	}
	
	public function copy(deep:Bool = true):Bone {
		var b:Bone = new Bone(this.name + "_copy");
		b.copyFrom(this);
		if(deep){
			for (c in children) 
			{
				b.addChild(c.copy(deep));
			}
		}
		return b;
	}
	public function listBones():Array<Bone> {
		var out = new Array<Bone>();
		out.push(this);
		for (c in children) 
		{
			out = out.concat(c.listBones());
		}
		return out;
	}
	public function getRoot():Skeleton {
		if (parent != null) return parent.getRoot();
		return cast this;
	}
	public function copyFrom(other:Bone) {
		z = other.z;
		gtsSequence = other.gtsSequence;
		gtsSequenceFrame = other.gtsSequenceFrame;
		localOffset.copyFrom(other.localOffset);
		rotation = other.rotation;
		position.copyFrom(other.position);
		scale.copyFrom(other.scale);
	}
	public function getSRT(time, list:Array<SRT> = null):SRT {
		var srt = new SRT();
		srt.rotation = rotation;
		srt.scaleX = scale.x;
		srt.scaleY = scale.y;
		srt.x = position.x;
		srt.y = position.y;
		srt.time = time;
		srt.sequenceFrame = gtsSequenceFrame;
		srt.sequenceName = gtsSequence;
		if(list!=null){
			list.push(srt);
			var i = children.length;
			while(i-- > 0) 
			{
				children[i].getSRT(time, list);
			}
		}
		return srt;
	}

	
	public function getBoneByName(name:String):Bone
	{
		if (this.name == name) return this;
		var b:Bone = null;
		var i = children.length;
		while(i-- > 0 ) 
		{
			b = children[i].getBoneByName(name);
		}
		return b;
	}
	public function addBone(name:String, x = 0, y = 0):Bone {
		var nb = new Bone(name);
		nb.position.x = x;
		nb.position.y = y;
		nb.gtsSequence = gtsSequence; //i suppose inheriting upwards make sense?
		nb.inheritOffset();
		return addChild(nb);
	}
	
	public function inheritOffset() 
	{
		/*if (gtsSequence == "n/a") {
			localOffset.x = localOffset.y = 0;
			return;
		}
		var seq:Sequence = SharedModel.gts.getSequenceByName(gtsSequence);
		var pn:Point = seq.tiles[0].center.clone();
		localOffset.x = seq.tiles[0].width * .5;
		localOffset.y = seq.tiles[0].height * .5;
		localOffset.x -= pn.x;
		localOffset.y -= pn.y;*/
	}
	
	public function addChild(b:Bone):Bone {
		if (b.parent == this) {
			return b;
		}
		if (b.parent != null) {
			b.parent.removeChild(b);
		}
		b.parent = this;
		children.push(b);
		SharedModel.skeleton.allBones[b.boneID] = b;
		SharedModel.skeleton.boneCount++;
		return b;
	}
	public function removeChild(b:Bone):Bone {
		if (b.parent != this) {
			return b;
		}
		b.parent = null;
		children.splice(children.indexOf(b), 1);
		SharedModel.skeleton.allBones[b.boneID] = null;
		SharedModel.skeleton.boneCount--;
		return b;
	}
	public function getLocalMatrix():Matrix {
		localTransform.identity();
		localTransform.rotate(rotation);
		localTransform.scale(scale.x, scale.y);
		localTransform.translate(position.x, position.y);
		return localTransform;
	}
	public function getGlobalMatrix():Matrix {
		var m:Matrix = getLocalMatrix();
		if (parent != null) {
			m.concat(parent.getGlobalMatrix());
		}
		return m;
	}
	
	public function toList():Dynamic {
		var list = [];
		for (c in children) {
			list.push(c.toList());
		}
		return { label:name, items:list, bone:this };
	}
	public function hitTest(pt:Point, hits:Array<Bone> = null):Array<Bone> {
		if (hits == null) {
			hits = new Array<Bone>();
		}
		var global:Matrix = getGlobalMatrix();
		var dx = global.tx - pt.x;
		var dy = global.ty - pt.y;
		if (Math.sqrt(dx * dx + dy * dy) < 10) {
			hits.push(this);
		}
		for (c in children) 
		{
			c.hitTest(pt, hits);
		}
		return hits;
	}
	public function serialize():Dynamic {
		var out:Dynamic = { };
		out.name = name;
		out.position = { x:position.x, y:position.y };
		out.z = z;
		out.boneID = boneID;
		out.gtsSequenceFrame = gtsSequenceFrame;
		out.rotation = rotation;
		out.scale = { x:scale.x, y:scale.y };
		out.localOffset = { x:localOffset.x, y:localOffset.y };
		out.gtsSequence = gtsSequence;
		out.children = [];
		for (c in children) 
		{
			out.children.push(c.serialize());
		}
		return out;
	}
	public function deserialize(ob:Dynamic) {
		name = ob.name;
		position.x = ob.position.x;
		position.y = ob.position.y;
		z = ob.z;
		rotation = ob.rotation;
		scale.x = ob.scale.x;
		scale.y = ob.scale.y;
		if (ob.hasOwnProperty("localOffset")) {
			localOffset.x = ob.localOffset.x;
			localOffset.y = ob.localOffset.y;
		}else{
			localOffset.x = 0;
			localOffset.y = 0;
		}
		gtsSequence = ob.gtsSequence;
		gtsSequenceFrame = ob.gtsSequenceFrame;
		
		boneID = ob.boneID;
		trace(name+": " + boneID);
		uidPool = cast Math.max(boneID, uidPool);
		SharedModel.skeleton.allBones[boneID] = this;
		
		children = new Array<Bone>();
		for (i in 0...ob.children.length) 
		{
			var c = ob.children[i];
			var b = new Bone("", false);
			b.deserialize(c);
			addChild(b);
		}
	}
	
	public function clearGTS() 
	{
		gtsSequenceFrame = 0;
		gtsSequence = "n/a";
		SharedModel.onChanged.dispatch(SharedModel.BONES | SharedModel.META, ChangedData.next(boneID));
	}
	
	public function dispose() {
		SharedModel.skeleton.allBones[boneID] = null;
		for (c in children) 
		{
			c.dispose();
		}
	}
	
	public function mirror(axis:Axis) 
	{
		switch(axis) {
			case X:
				position.x *= -1;
				scale.x *= -1;
			case Y:
				position.y *= -1;
				scale.y *= -1;
				
		}
	}
	public function toString():String {
		return "Bone: " + boneID + ":" + name;
	}
	
	public function getWorldFrame():Dynamic {
		var out:Dynamic = { };
		var global:Matrix = getGlobalMatrix();
		var srt:Array<Dynamic> = out.srt = [];
		
		var scale:Point = new Point(1, 1);
		scale = global.deltaTransformPoint(scale);
		var rotation:Point = new Point(1, 0);
		rotation = global.deltaTransformPoint(rotation);
		var angle = Math.atan2(rotation.y, rotation.x);
		
		srt.push(scale.x);
		srt.push(scale.y);
		srt.push(angle);
		srt.push(global.tx);
		srt.push(global.ty);
		
		//matrix.push(global.a, global.b, global.c, global.d, global.tx, global.ty);
		out.boneID = boneID;
		out.sequenceName = gtsSequence;
		out.sequenceFrame = gtsSequenceFrame;
		out.z = z;
		return out;
	}
	
	public function getFrame():Dynamic {
		var out:Dynamic = { };
		out.srt = [position.x, position.y, rotation, scale.x, scale.y];
		out.boneID = boneID;
		out.sequenceName = gtsSequence;
		out.sequenceFrame = gtsSequenceFrame;
		out.z = z;
		return out;
	}
	
	public function worldSRT():SRT 
	{
		var global:Matrix = getGlobalMatrix();
		var srt:SRT = new SRT();
		srt.x = global.tx;
		srt.y = global.ty;
		srt.z = z;
		//srt.boneID = boneID;
		srt.sequenceFrame = gtsSequenceFrame;
		srt.sequenceName = gtsSequence;
		
		var p:Point = new Point(1, 0);
		p = global.deltaTransformPoint(p);
		srt.rotation = Math.atan2(p.y, p.x);
		
		p.x = p.y = 1;
		p = global.deltaTransformPoint(p);
		
		//TODO: Support non-uniform scaling
		srt.scaleX = 1;
		srt.scaleY = 1;
		return srt;
	}
	
	public function buildDef():Dynamic 
	{
		var out:Dynamic = { };
		out.id = boneID;
		out.children = [];
		for(c in children) {
			out.children.push(c.buildDef());
		}
		return out;
	}
	
}