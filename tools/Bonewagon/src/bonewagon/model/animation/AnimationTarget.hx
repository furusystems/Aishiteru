package bonewagon.model.animation;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
/**
 * ...
 * @author Andreas Rønning
 */
class AnimationTarget 
{
	public var boneID:Int = -1;
	public var srts:Array<SRT> = new Array<SRT>();
	public var bone:Bone = null;
	public function new() 
	{
		
	}
	
	public function getBone():Bone {
		if (bone != null) return bone;
		return bone = SharedModel.skeleton.allBones[boneID];
	}
	public function addSample(time, bone:Bone) {
		var srt:SRT = bone.getSRT(time);
		srt.owner = this;
		srts.push(srt);
		srts.sort(ss);
	}
	
	public function sortSamples() 
	{
		srts.sort(ss);
	}
	static function ss(a:SRT, b:SRT):Int {
		if (a.time < b.time) return -1;
		if (a.time > b.time) return 1;
		return 0;
	}
	
	public function getDuration():Float {
		if (srts.length == 0) return 0;
		return srts[srts.length - 1].time;
	}
	public function serialize():Dynamic {
		var out:Dynamic = { };
		trace("Serializing animtarget. " + boneID);
		out.boneID = boneID;
		out.srts = [];
		for (s in srts) 
		{
			out.srts.push(s.serialize());
		}
		return out;
	}
	public static function fromObject(ob:Dynamic):AnimationTarget {
		var out:AnimationTarget = new AnimationTarget();
		out.boneID = ob.boneID;
		trace("Reading animtarget. " + out.boneID+", "+out.getBone().name);

		for(i in 0...ob.srts.length)
		{
			var s = ob.srts[i];
			out.srts.push(SRT.fromObject(out, s));
		}
		return out;
	}
	
	public function addSampleRaw(srt:SRT, atTime:Float, checkExisting:Bool = true) 
	{
		trace("Adding sample at time: " + atTime);
		srt.time = atTime;
		if (checkExisting) {
			for(existingsrt in srts) {
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
	public function getFirst():SRT {
		if (srts.length == 0) return null;
		return srts[0];
	}
	public function getLast():SRT {
		if (srts.length == 0) return null;
		return srts[srts.length - 1];
	}
	
}