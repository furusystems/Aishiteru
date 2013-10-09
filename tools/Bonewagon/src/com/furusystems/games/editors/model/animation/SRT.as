package com.furusystems.games.editors.model.animation 
{
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import com.furusystems.games.editors.model.skeleton.Skeleton;
	import com.greensock.easing.Cubic;
	import com.greensock.easing.Ease;
	import com.greensock.easing.Quad;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class SRT 
	{
		public var scaleX:Number = 1;
		public var scaleY:Number = 1;
		public var rotation:Number = 0;
		public var x:Number = 0;
		public var y:Number = 0;
		public var z:int = 0;
		//public var boneID:int = -1;
		public var sequenceFrame:int = 0;
		public var sequenceName:String = "n/a";
		public static var uidPool:int = 0;
		public var uid:int = -1;
		public var selected:Boolean = false;
		public var time:Number = -1;
		public var owner:AnimationTarget = null;
		public static var easeTypes:Array = ["linear", "in", "out", "inout"];
		public var easing:int = 0;
		public function SRT() {
			uid = uidPool++;
		}
		public static function interpolate(a:SRT, b:SRT, t:Number = 0.5):SRT {
			if (!a.notSameAs(b)) return a.clone();
			var out:SRT = new SRT();
			out.time = a.time + (b.time-a.time) * t;
			out.owner = a.owner;
			out.sequenceName = a.sequenceName;
			out.sequenceFrame = a.sequenceFrame;
			switch(a.easing) {
				case 0:
					//linear
					out.x = a.x + (b.x - a.x) * t;
					out.y = a.y + (b.y - a.y) * t;
					out.scaleX = a.scaleX + (b.scaleX - a.scaleX) * t;
					out.scaleY = a.scaleY + (b.scaleY - a.scaleY) * t;
					out.rotation = a.rotation + (b.rotation - a.rotation) * t;
					break;
				case 1:
					
					out.x = Quad.easeIn(t, a.x, b.x - a.x, 1);
					out.y = Quad.easeIn(t, a.y, b.y - a.y, 1);
					out.scaleX = Quad.easeIn(t, a.scaleX, b.scaleX - a.scaleX, 1);
					out.scaleY = Quad.easeIn(t, a.scaleY, b.scaleY - a.scaleY, 1);
					out.rotation = Quad.easeIn(t, a.rotation, b.rotation - a.rotation, 1);
					//in
					break;
				case 2:
					out.x = Quad.easeOut(t, a.x, b.x - a.x, 1);
					out.y = Quad.easeOut(t, a.y, b.y - a.y, 1);
					out.scaleX = Quad.easeOut(t, a.scaleX, b.scaleX - a.scaleX, 1);
					out.scaleY = Quad.easeOut(t, a.scaleY, b.scaleY - a.scaleY, 1);
					out.rotation = Quad.easeOut(t, a.rotation, b.rotation - a.rotation, 1);
					//out
					break;
				case 3:
					//inout
					out.x = Quad.easeInOut(t, a.x, b.x - a.x, 1);
					out.y = Quad.easeInOut(t, a.y, b.y - a.y, 1);
					out.scaleX = Quad.easeInOut(t, a.scaleX, b.scaleX - a.scaleX, 1);
					out.scaleY = Quad.easeInOut(t, a.scaleY, b.scaleY - a.scaleY, 1);
					out.rotation = Quad.easeInOut(t, a.rotation, b.rotation - a.rotation, 1);
					break;
					
			}
			return out;
		}
		
		public function cycleEasing():void {
			easing++;
			if (easing >= easeTypes.length) {
				easing = 0;
			}
		}
		
		public function notSameAs(b:SRT):Boolean 
		{
			return 	x != b.x ||	y != b.y ||	scaleX != b.scaleX || scaleY != b.scaleY ||	rotation != b.rotation || sequenceFrame != b.sequenceFrame || sequenceName != b.sequenceName;
		}
		
		public static function fromObject(owner:AnimationTarget, ob:Object):SRT {
			var out:SRT = new SRT();
			out.x = ob.x;
			out.y = ob.y;
			out.owner = owner;
			out.rotation = ob.rotation;
			out.scaleX = ob.scaleX;
			out.scaleY = ob.scaleY;
			out.sequenceName = ob.sequenceName;
			out.sequenceFrame = ob.sequenceFrame;
			out.time = ob.time;
			if(ob.hasOwnProperty("easing")) out.easing = ob.easing;
			//out.boneID = ob.boneID;
			return out;
		}
		public function serialize(export:Boolean = false):Object 
		{
			var out:Object = { };
				out.time = time;
				out.scaleX = scaleX;
				out.scaleY = scaleY;
				out.rotation = rotation;
				out.sequenceName = sequenceName;
				out.sequenceFrame = sequenceFrame;
				out.x = x;
				out.y = y;
				out.z = z;
				//out.boneID = boneID;
				out.easing = easing;
			return out;
		}
		
		public function clone():SRT 
		{
			var srt:SRT = new SRT();
			srt.owner = owner;
			srt.easing = easing;
			srt.rotation = rotation;
			srt.scaleX = scaleX;
			srt.scaleY = scaleY;
			srt.sequenceFrame = sequenceFrame;
			srt.sequenceName = sequenceName;
			srt.x = x;
			srt.y = y;
			srt.time = time;
			return srt;
		}
		
		public function apply():void 
		{
			var bone:Bone = SharedModel.skeleton.allBones[owner.boneID];
			if (bone == null) return;
			bone.position.x = x;
			bone.position.y = y;
			bone.rotation = rotation;
			bone.scale.x = scaleX;
			bone.scale.y = scaleY;
			bone.gtsSequence = sequenceName;
			bone.gtsSequenceFrame = sequenceFrame;
		}
		
		public function add(other:SRT, weight:Number):void 
		{
			var bone:Bone = SharedModel.skeleton.allBones[owner.boneID];
			if (bone == null) return;
			bone.position.x += (x - other.x) * weight;
			bone.position.y += (y - other.y) * weight;
			bone.rotation += (rotation - other.rotation) * weight;
			bone.scale.x += (scaleX - other.scaleX) * weight;
			bone.scale.y += (scaleY - other.scaleY) * weight;
			bone.gtsSequence = weight > 0.5?sequenceName:other.sequenceName;
			bone.gtsSequenceFrame = weight > 0.5?sequenceFrame:other.sequenceFrame;
		}
		
		public function copyFrom(srt:SRT):void 
		{
			owner = srt.owner;
			easing = srt.easing;
			rotation = srt.rotation;
			scaleX = srt.scaleX;
			scaleY = srt.scaleY;
			sequenceFrame = srt.sequenceFrame;
			sequenceName = srt.sequenceName;
			x = srt.x;
			y = srt.y;
			//time = srt.time;
		}
		
	}

}