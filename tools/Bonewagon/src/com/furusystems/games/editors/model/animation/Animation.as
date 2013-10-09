package com.furusystems.games.editors.model.animation 
{
	import com.furusystems.dconsole2.core.commands.IntrospectionCommand;
	import com.furusystems.dconsole2.DConsole;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import com.furusystems.games.editors.model.skeleton.Skeleton;
	import com.furusystems.logging.slf4as.ILogger;
	import com.furusystems.logging.slf4as.Logging;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Animation 
	{
		public var name:String = "Animation";
		public var targets:Vector.<AnimationTarget> = new Vector.<AnimationTarget>();
		public var scripts:Vector.<ScriptKey> = new Vector.<ScriptKey>();
		public var weight:Number = 0;
		public static const L:ILogger = Logging.getLogger(Animation);
		public function Animation() 
		{
		}
		
		public function getPose(time:Number, interpolate:Boolean = false):Vector.<SRT> {
			trace("Getting pose, " + Bone.uidPool);
			var out:Array = [];
			if (targets.length == 0) return new Vector.<SRT>();
			
			//search for the closest sample. If interpolate is true, generate a new one
			targetLoop: for (var j:int = 0; j < targets.length; j++) 
			{
				var t:AnimationTarget = targets[j];
				if (t.srts.length == 0) continue;
				
				var outSample:SRT = t.srts[0];
				var found:Boolean = false;
				if (t.srts[t.srts.length - 1].time < time) {
					out[t.boneID] = t.srts[t.srts.length - 1].clone();
				}
				for (var i:int = 0; i < t.srts.length; i++) 
				{
					var s:SRT = t.srts[i];
					if (s.time == time) {
						out[t.boneID] = s.clone();
						found = true;
					}else if (s.time > time) {
						//we're in the future, do we interpolate?
						if (interpolate) {
							var st:Number = (time-outSample.time) / (s.time-outSample.time);
							var r:SRT = SRT.interpolate(outSample, s, st);
							out[t.boneID] = r;
							found = true;
						}else {
							out[t.boneID] = outSample.clone();
							found = true;
						}
					}
					outSample = s;
					if (found) break;
				}
			}
			out = out.filter(function(item:SRT, index:int, array:Array):Boolean { return array[index] != null; } );
			trace("Pose: " + out);
			var v:Vector.<SRT> = new Vector.<SRT>();
			while (out.length > 0) {
				v.push(out.shift());
			}
			return v;
		}
		
		public function apply(time:Number, interpolate:Boolean = false):void {
			if (targets.length == 0) return;
			//search for the closest sample. If interpolate is true, generate a new one
			targetLoop: for (var j:int = targets.length; j--; ) 
			{
				var t:AnimationTarget = targets[j];
				var bone:Bone = SharedModel.skeleton.allBones[t.boneID];
				if (t.srts.length == 0) continue;
				var outSample:SRT = t.srts[0];
				
				for (var i:int = 0; i < t.srts.length; i++) 
				{
					var s:SRT = t.srts[i];
					if (s.time == time) {
						s.apply();
						continue targetLoop;
					}else if (s.time > time) {
						//we're in the future, do we interpolate?
						if (interpolate) {
							var st:Number = (time-outSample.time) / (s.time-outSample.time);
							var r:SRT = SRT.interpolate(outSample, s, st);
							r.apply();
							continue targetLoop;
						}else {
							outSample.apply();
							continue targetLoop;
						}
					}else {
						s.apply();
					}
					outSample = s;
				}
			}
		}
		public function get duration():Number {
			var out:Number = 0;
			for (var i:int = 0; i < targets.length; i++) 
			{
				var d:Number = targets[i].duration;
				if (out < d) {
					out = d;
				}
			}
			return out;
		}
		public function export(out:ByteArray):void 
		{
			scripts.sort(sortScriptsByTime);
			
			out.writeUTF(name);
			out.writeFloat(duration);
			
			var numFrames:int = Math.max(1, Math.ceil(duration * SharedModel.SAMPLERATE));
			out.writeUnsignedInt(numFrames);
			out.writeShort(scripts.length);
			var i:int;
			for (i = 0; i < numFrames; i++) 
			{
				var t:Number = i / (numFrames - 1) * duration;
				if (isNaN(t)) t = 0;
				apply(t, true);
				var exportStates:Array = SharedModel.skeleton.getExportStates();
				for (var j:int = 0; j < exportStates.length; j++) 
				{
					var ob:Object = exportStates[j];
					out.writeShort(ob.boneID);
					out.writeFloat(ob.z);
					out.writeUTF(ob.sequenceName);
					out.writeShort(ob.sequenceFrame);
					out.writeFloat(ob.srt[0]);
					out.writeFloat(ob.srt[1]);
					out.writeFloat(ob.srt[2]);
					out.writeFloat(ob.srt[3]);
					out.writeFloat(ob.srt[4]);
				}
			}
			
			for (i = 0; i < scripts.length; i++) 
			{
				out.writeFloat(scripts[i].time);
				out.writeUTF(scripts[i].script);
				//ob.scripts.push(scripts[i].serialize());
			}	
			
			SharedModel.basePose.apply(0, false); //return to default pose
		}
		
		public function serialize(export:Boolean = false):Object {
			var ob:Object = { };
			ob.name = name;
			ob.duration = duration;
			var i:int;
			if (export) {
				ob.frames = [];
				ob.scripts = [];
				L.info("Anim duration: " + duration);
				scripts.sort(sortScriptsByTime);
				for (i = 0; i < scripts.length; i++) 
				{
					ob.scripts.push(scripts[i].serialize());
				}
				var numFrames:int = Math.max(1, Math.ceil(duration * SharedModel.SAMPLERATE));
				L.info("Frames to export: " + numFrames);
				for (i = 0; i < numFrames; i++) 
				{
					var t:Number = i / (numFrames - 1) * duration;
					if (isNaN(t)) t = 0;
					apply(t, true);
					L.info("Exporting frame at time: " + t);
					ob.frames.push( { time:t, samples:SharedModel.skeleton.getExportStates() } );
				}
				SharedModel.basePose.apply(0, false); //return to default pose
			}else {				
				ob.targets = [];
				ob.scripts = [];
				for (i = 0; i < targets.length; i++) 
				{
					ob.targets.push(targets[i].serialize());
				}
				for (i = 0; i < scripts.length; i++) 
				{
					ob.scripts.push(scripts[i].serialize());
				}
			}
			return ob;
		}
		
		private function sortScriptsByTime(a:ScriptKey, b:ScriptKey):int 
		{
			if (a.time < b.time) return -1;
			if (a.time > b.time) return 1;
			return 0;
		}
		public static function fromOb(ob:Object):Animation {
			var out:Animation = new Animation();
			out.name = ob.name;
			trace("New animation: " + out.name);
			for (var i:int = 0; i < ob.targets.length; i++) 
			{
				trace("Creating target: " + ob.targets[i].boneID);
				out.targets.push(AnimationTarget.fromObject(ob.targets[i]));
			}
			if(ob.hasOwnProperty("scripts")){
				for (var j:int = 0; j < ob.scripts.length; j++) 
				{
					out.scripts.push(ScriptKey.fromOb(ob.scripts[j]));
				}
			}
			return out;
		}
		
		public function sortTargets():void 
		{
			for (var i:int = 0; i < targets.length; i++) 
			{
				targets[i].sortSamples();
			}
		}
		
		public function getTargetWithID(id:int):AnimationTarget
		{
			for (var i:int = 0; i < targets.length; i++) 
			{
				if (targets[i].boneID == id) return targets[i];
			}
			var at:AnimationTarget = new AnimationTarget();
			at.boneID = id;
			targets.push(at);
			return at;
		}
		
		public function validate():void 
		{
			var dirty:Boolean = false;
			for (var i:int = 0; i < targets.length; i++) 
			{
				var t:AnimationTarget = targets[i];
				if (SharedModel.skeleton.allBones[t.boneID] == null) {
					targets.splice(i, 1);
					i--;
					dirty = true;
				}
			}
		}
		
		
		/**
		 * Add this animation to the base pose by its blend weight
		 * @param	timeSeconds
		 */
		public function add(base:Vector.<SRT>, timeSeconds:Number):void 
		{
			var pose:Vector.<SRT> = getPose(timeSeconds, true);
			for (var i:int = pose.length; i--; ) 
			{
				if (pose[i] == null) continue;
				pose[i].apply();
			}
		}
		
		public function listKeys():Vector.<SRT> 
		{
			var out:Vector.<SRT> = new Vector.<SRT>();
			for each(var t:AnimationTarget in targets) {
				out = out.concat(t.srts);
			}
			out.sort(sortKeys);
			return out;
		}
		
		
		private function sortKeys(a:SRT, b:SRT):int {
			if (a.time < b.time) return -1;
			if (a.time > b.time) return 1;
			return 0;
		}
		
		public function get minTime():Number
		{
			var t:Number = Number.POSITIVE_INFINITY;
			for (var i:int = 0; i < targets.length; i++) 
			{
				if (targets[i].srts.length == 0) continue;
				if (targets[i].first.time < t) t = targets[i].first.time;
			}
			return t;
		}
		public function get maxTime():Number {
			var t:Number = Number.NEGATIVE_INFINITY;
			for (var i:int = 0; i < targets.length; i++) 
			{
				if (targets[i].srts.length == 0) continue;
				if (targets[i].last.time > t) t = targets[i].last.time;
			}
			return t;
		}
		
	}

}