package com.furusystems.games.editors.model.skeleton 
{
	import com.furusystems.games.editors.model.animation.SRT;
	import com.furusystems.games.editors.model.gts.GTSMap;
	import com.furusystems.games.editors.model.gts.GTSSheet;
	import com.furusystems.games.editors.model.gts.Sequence;
	import com.furusystems.games.editors.model.SharedModel;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Bone 
	{
		public static var uidPool:int = 0;
		
		public var name:String;
		public var children:Vector.<Bone> = new Vector.<Bone>();
		public var localTransform:Matrix = new Matrix();
		public var parent:Bone = null;
		
		public var position:Point = new Point();
		public var globalPosition:Point = new Point();
		public var scale:Point = new Point(1,1);
		public var globalScale:Point = new Point(1,1);
		public var rotation:Number = 0;
		public var globalRotation:Number = 0;
		
		public var localOffset:Point = new Point();
		
		public var gtsSequence:String = "n/a";
		public var gtsSequenceFrame:int = 0;
		
		public var color:uint = Math.random() * 0xFFFFFF;
		public var z:Number = 0;
		
		public var boneID:int = -1;
		
		static public const X_AXIS:String = "x";
		static public const Y_AXIS:String = "y";
		
		public function Bone(name:String = "", init:Boolean = true) 
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
		
		public function getDepth():int {
			var out:int = 1;
			for (var i:int = 0; i < children.length; i++) 
			{
				out += children[i].getDepth();
			}
			return out;
		}
		
		public function copy(deep:Boolean = true):Bone {
			var b:Bone = new Bone(this.name + "_copy");
			b.copyFrom(this);
			if(deep){
				for (var i:int = 0; i < children.length; i++) 
				{
					b.addChild(children[i].copy(deep));
				}
			}
			return b;
		}
		public function listBones():Vector.<Bone> {
			var out:Vector.<Bone> = new Vector.<Bone>();
			out.push(this);
			for (var i:int = 0; i < children.length; i++) 
			{
				out = out.concat(children[i].listBones());
			}
			return out;
		}
		public function getRoot():Skeleton {
			if (parent != null) return parent.getRoot();
			return this as Skeleton;
		}
		public function copyFrom(other:Bone):void {
			z = other.z;
			gtsSequence = other.gtsSequence;
			gtsSequenceFrame = other.gtsSequenceFrame;
			localOffset.copyFrom(other.localOffset);
			rotation = other.rotation;
			position.copyFrom(other.position);
			scale.copyFrom(other.scale);
		}
		public function getSRT(time:Number, list:Vector.<SRT> = null):SRT {
			var srt:SRT = new SRT();
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
				for (var i:int = children.length; i--; ) 
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
			for (var i:int = children.length; i--; ) 
			{
				b = children[i].getBoneByName(name);
			}
			return b;
		}
		public function addBone(name:String, x:Number = 0, y:Number = 0):Bone {
			var nb:Bone = new Bone(name);
			nb.position.x = x;
			nb.position.y = y;
			nb.gtsSequence = gtsSequence; //i suppose inheriting upwards make sense?
			nb.inheritOffset();
			return addChild(nb);
		}
		
		public function inheritOffset():void 
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
		
		public function toList():Object {
			var list:Array = [];
			for (var i:int = 0; i < children.length; i++) {
				list.push(children[i].toList());
			}
			return { label:name, items:list, bone:this };
		}
		public function hitTest(pt:Point, hits:Array = null):Array {
			if (hits == null) {
				hits = new Array();
			}
			var global:Matrix = getGlobalMatrix();
			var dx:Number = global.tx - pt.x;
			var dy:Number = global.ty - pt.y;
			if (Math.sqrt(dx * dx + dy * dy) < 10) {
				hits.push(this);
			}
			for (var i:int = 0; i < children.length; i++) 
			{
				children[i].hitTest(pt, hits);
			}
			return hits;
		}
		public function serialize():Object {
			var out:Object = new Object();
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
			for (var i:int = 0; i < children.length; i++) 
			{
				out.children.push(children[i].serialize());
			}
			return out;
		}
		public function deserialize(ob:Object):void {
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
			uidPool = Math.max(boneID, uidPool);
			SharedModel.skeleton.allBones[boneID] = this;
			
			children = new Vector.<Bone>();
			for (var i:int = 0; i < ob.children.length; i++) 
			{
				var b:Bone = new Bone("", false);
				b.deserialize(ob.children[i]);
				addChild(b);
			}
		}
		
		public function clearGTS():void 
		{
			gtsSequenceFrame = 0;
			gtsSequence = "n/a";
			SharedModel.onChanged.dispatch(SharedModel.BONES | SharedModel.META, boneID);
		}
		
		public function dispose():void {
			SharedModel.skeleton.allBones[boneID] = null;
			for (var i:int = 0; i < children.length; i++) 
			{
				children[i].dispose();
			}
		}
		
		public function mirror(axis:String):void 
		{
			switch(axis) {
				case X_AXIS:
					position.x *= -1;
					scale.x *= -1;
					break;
				case Y_AXIS:
					position.y *= -1;
					scale.y *= -1;
					break;
					
			}
		}
		public function toString():String {
			return "Bone: " + boneID + ":" + name;
		}
		
		public function getWorldFrame():Object {
			var out:Object = { };
			var global:Matrix = getGlobalMatrix();
			var srt:Array = out.srt = [];
			
			var scale:Point = new Point(1, 1);
			scale = global.deltaTransformPoint(scale);
			var rotation:Point = new Point(1, 0);
			rotation = global.deltaTransformPoint(rotation);
			var angle:Number = Math.atan2(rotation.y, rotation.x);
			
			srt.push(scale.x, scale.y, angle, global.tx, global.ty);
			
			
			//matrix.push(global.a, global.b, global.c, global.d, global.tx, global.ty);
			out.boneID = boneID;
			out.sequenceName = gtsSequence;
			out.sequenceFrame = gtsSequenceFrame;
			out.z = z;
			return out;
		}
		
		public function getFrame():Object {
			var out:Object = { };
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
		
		public function buildDef():Object 
		{
			var out:Object = { };
			out.id = boneID;
			out.children = [];
			for each(var c:Bone in children) {
				out.children.push(c.buildDef());
			}
			return out;
		}
		
	}

}