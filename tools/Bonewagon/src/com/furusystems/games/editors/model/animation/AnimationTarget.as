package com.furusystems.games.editors.model.animation 
{
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class AnimationTarget 
	{
		public var boneID:int = -1;
		public var srts:Vector.<SRT> = new Vector.<SRT>();
		public var bone:Bone = null;
		public function AnimationTarget() 
		{
			
		}
		
		public function getBone():Bone {
			if (bone != null) return bone;
			return bone = SharedModel.skeleton.allBones[boneID];
		}
		public function addSample(time:Number, bone:Bone):void {
			var srt:SRT = bone.getSRT(time);
			srt.owner = this;
			srts.push(srt);
			srts.sort(ss);
		}
		
		public function sortSamples():void 
		{
			srts.sort(ss);
		}
		private static function ss(a:SRT, b:SRT):int {
			if (a.time < b.time) return -1;
			if (a.time > b.time) return 1;
			return 0;
		}
		
		public function get duration():Number {
			if (srts.length == 0) return 0;
			return srts[srts.length - 1].time;
		}
		public function serialize():Object {
			var out:Object = { };
			trace("Serializing animtarget. " + boneID);
			out.boneID = boneID;
			out.srts = [];
			for (var i:int = 0; i < srts.length; i++) 
			{
				out.srts.push(srts[i].serialize());
			}
			return out;
		}
		public static function fromObject(ob:Object):AnimationTarget {
			var out:AnimationTarget = new AnimationTarget();
			out.boneID = ob.boneID;
			trace("Reading animtarget. " + out.boneID+", "+out.getBone().name);

			for (var i:int = 0; i < ob.srts.length; i++) 
			{
				out.srts.push(SRT.fromObject(out, ob.srts[i]));
			}
			return out;
		}
		
		public function addSampleRaw(srt:SRT, atTime:Number, checkExisting:Boolean = true):void 
		{
			trace("Adding sample at time: " + atTime);
			srt.time = atTime;
			if (checkExisting) {
				for each(var existingsrt:SRT in srts) {
					if (existingsrt.time == atTime) {
						existingsrt.copyFrom(srt);
						existingsrt.owner = this;
						trace("Updating existing");
						return;
					}
				}
			}
			trace("Creating new");
			srt.owner = this;
			srts.push(srt);
			sortSamples();
		}
		public function get first():SRT {
			if (srts.length == 0) return null;
			return srts[0];
		}
		public function get last():SRT {
			if (srts.length == 0) return null;
			return srts[srts.length - 1];
		}
		
	}

}