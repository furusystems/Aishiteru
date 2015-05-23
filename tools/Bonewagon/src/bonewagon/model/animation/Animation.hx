package bonewagon.model.animation;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
import bonewagon.model.skeleton.Skeleton;
import flash.utils.ByteArray;
using Lambda;
/**
 * ...
 * @author Andreas Rønning
 */
class Animation 
{
	public var name:String = "Animation";
	public var targets:Array<AnimationTarget> = new Array<AnimationTarget>();
	public var scripts:Array<ScriptKey> = new Array<ScriptKey>();
	public var weight:Float = 0;
	
	public function new() 
	{
	}
	
	public function getPose(time, interpolate:Bool = false):Array<SRT> {
		trace("Getting pose, " + Bone.uidPool);
		var out = [];
		if (targets.length == 0) return new Array<SRT>();
		
		//search for the closest sample. If interpolate is true, generate a new one
		for (t in targets) 
		{
			if (t.srts.length == 0) continue;
			
			var outSample = t.srts[0];
			var found = false;
			if (t.srts[t.srts.length - 1].time < time) {
				out[t.boneID] = t.srts[t.srts.length - 1].clone();
			}
			for (s in t.srts) 
			{
				if (s.time == time) {
					out[t.boneID] = s.clone();
					found = true;
				}else if (s.time > time) {
					//we're in the future, do we interpolate?
					if (interpolate) {
						var st = (time-outSample.time) / (s.time-outSample.time);
						var r = SRT.interpolate(outSample, s, st);
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
		
		out = out.filter(function(item)  return item != null );
		
		trace("Pose: " + out);
		var v = new Array<SRT>();
		while (out.length > 0) {
			v.push(out.shift());
		}
		return v;
	}
	
	public function apply(time, interpolate:Bool = false) {
		if (targets.length == 0) return;
		//search for the closest sample. If interpolate is true, generate a new one
		var j = targets.length;
		while(j-- > 0) 
		{
			var t = targets[j];
			var bone = SharedModel.skeleton.allBones[t.boneID];
			if (t.srts.length == 0) continue;
			var outSample:SRT = t.srts[0];
			
			for (s in t.srts) 
			{
				if (s.time == time) {
					s.apply();
					break;
				}else if (s.time > time) {
					//we're in the future, do we interpolate?
					if (interpolate) {
						var st = (time-outSample.time) / (s.time-outSample.time);
						var r:SRT = SRT.interpolate(outSample, s, st);
						r.apply();
						break;
					}else {
						outSample.apply();
						break;
					}
				}else {
					s.apply();
				}
				outSample = s;
			}
		}
	}
	public function getDuration() {
		var out:Float = 0;
		for (t in targets) 
		{
			var d = t.getDuration();
			if (out < d) {
				out = d;
			}
		}
		return out;
	}
	public function export(out:ByteArray) 
	{
		scripts.sort(sortScriptsByTime);
		
		var duration = getDuration();
		
		out.writeUTF(name);
		out.writeFloat(duration);
		
		var numFrames:Int = cast Math.max(1, Math.ceil(duration * SharedModel.SAMPLERATE));
		out.writeUnsignedInt(numFrames);
		out.writeShort(scripts.length);
		for (i in 0...numFrames) 
		{
			var t = i / (numFrames - 1) * duration;
			if (Math.isNaN(t)) t = 0;
			apply(t, true);
			var exportStates = SharedModel.skeleton.getExportStates();
			for (ob in exportStates) 
			{
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
		
		for (s in scripts) 
		{
			out.writeFloat(s.time);
			out.writeUTF(s.script);
			//ob.scripts.push(scripts[i].serialize());
		}	
		
		SharedModel.basePose.apply(0, false); //return to default pose
	}
	
	public function serialize(export:Bool = false):Dynamic {
		var ob:Dynamic = { };
		ob.name = name;
		var duration = getDuration();
		ob.duration = duration;
		if (export) {
			ob.frames = [];
			ob.scripts = [];
			trace("Anim duration: " + duration);
			scripts.sort(sortScriptsByTime);
			for (s in scripts) 
			{
				ob.scripts.push(s.serialize());
			}
			var numFrames:Int = cast Math.max(1, Math.ceil(duration * SharedModel.SAMPLERATE));
			trace("Frames to export: " + numFrames);
			for (i in 0...numFrames) 
			{
				var t = i / (numFrames - 1) * duration;
				if (Math.isNaN(t)) t = 0;
				apply(t, true);
				trace("Exporting frame at time: " + t);
				ob.frames.push( { time:t, samples:SharedModel.skeleton.getExportStates() } );
			}
			SharedModel.basePose.apply(0, false); //return to default pose
		}else {				
			ob.targets = [];
			ob.scripts = [];
			for (t in targets) 
			{
				ob.targets.push(t.serialize());
			}
			for (s in scripts) 
			{
				ob.scripts.push(s.serialize());
			}
		}
		return ob;
	}
	
	function sortScriptsByTime(a:ScriptKey, b:ScriptKey):Int 
	{
		if (a.time < b.time) return -1;
		if (a.time > b.time) return 1;
		return 0;
	}
	public static function fromOb(ob:Dynamic):Animation {
		var out:Animation = new Animation();
		out.name = ob.name;
		trace("New animation: " + out.name);
		for(i in 0...ob.targets.length)
		{
			var t = ob.targets[i];
			trace("Creating target: " + t.boneID);
			out.targets.push(AnimationTarget.fromObject(t));
		}
		if (ob.hasOwnProperty("scripts")) {
			for(i in 0...ob.scripts) {
				var s = ob.scripts[i];
				out.scripts.push(ScriptKey.fromOb(s));
			}
		}
		return out;
	}
	
	public function sortTargets() 
	{
		for (t in targets) 
		{
			t.sortSamples();
		}
	}
	
	public function getTargetWithID(id:Int):AnimationTarget
	{
		for (t in targets) 
		{
			if (t.boneID == id) return t;
		}
		var at = new AnimationTarget();
		at.boneID = id;
		targets.push(at);
		return at;
	}
	
	public function validate() 
	{
		var dirty:Bool = false;
		var i = 0;
		while(i++ < targets.length)
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
	public function add(base:Array<SRT>, timeSeconds) 
	{
		var pose:Array<SRT> = getPose(timeSeconds, true);
		var i = pose.length;
		while (i-- > 0) 
		{
			if (pose[i] == null) continue;
			pose[i].apply();
		}
	}
	
	public function listKeys():Array<SRT> 
	{
		var out:Array<SRT> = new Array<SRT>();
		for(t in targets) {
			out = out.concat(t.srts);
		}
		out.sort(sortKeys);
		return out;
	}
	
	
	function sortKeys(a:SRT, b:SRT):Int {
		if (a.time < b.time) return -1;
		if (a.time > b.time) return 1;
		return 0;
	}
	
	public function getMinTime()
	{
		var time = Math.POSITIVE_INFINITY;
		for (t in targets) 
		{
			if (t.srts.length == 0) continue;
			if (t.getFirst().time < time) time = t.getFirst().time;
		}
		return time;
	}
	public function getMaxTime() {
		var time = Math.NEGATIVE_INFINITY;
		for (t in targets) 
		{
			if (t.srts.length == 0) continue;
			if (t.getLast().time > time) time = t.getLast().time;
		}
		return time;
	}
	
}