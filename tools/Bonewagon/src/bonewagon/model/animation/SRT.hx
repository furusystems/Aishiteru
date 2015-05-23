package bonewagon.model.animation;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
import bonewagon.model.skeleton.Skeleton;
import tween.Delta.TweenFunc;
import tween.easing.Linear;
import tween.easing.Quad;
/**
 * ...
 * @author Andreas Rønning
 */
class SRT 
{
	public var scaleX:Float = 1;
	public var scaleY:Float = 1;
	public var rotation:Float = 0;
	public var x:Float = 0;
	public var y:Float = 0;
	public var z:Float = 0;
	//public var boneID:Int = -1;
	public var sequenceFrame:Int = 0;
	public var sequenceName:String = "n/a";
	public static var uidPool:Int = 0;
	public var uid:Int = -1;
	public var selected:Bool = false;
	public var time:Float = -1;
	public var owner:AnimationTarget = null;
	public static var easeTypes:Array<String> = ["linear", "in", "out", "inout"];
	public var easing:Int = 0;
	
	public function new() {
		uid = uidPool++;
	}
	public static function interpolate(a:SRT, b:SRT, t = 0.5):SRT {
		if (!a.notSameAs(b)) return a.clone();
		var out:SRT = new SRT();
		out.time = a.time + (b.time-a.time) * t;
		out.owner = a.owner;
		out.sequenceName = a.sequenceName;
		out.sequenceFrame = a.sequenceFrame;
		var tf:TweenFunc = switch(a.easing) {
			case 1:
				Quad.easeIn;
			case 2:
				Quad.easeOut;
			case 3:
				Quad.easeInOut;
			default:
				Linear.none;
		}
		
		out.x = tf(a.x, (b.x - a.x), t);
		out.y = tf(a.y, (b.y - a.y), t);
		out.scaleX = tf(a.scaleX, (b.scaleX - a.scaleX), t);
		out.scaleY = tf(a.scaleY, (b.scaleY - a.scaleY), t);
		out.rotation = tf(a.rotation, (b.rotation - a.rotation), t);
		
		return out;
	}
	
	public function cycleEasing() {
		easing++;
		if (easing >= easeTypes.length) {
			easing = 0;
		}
	}
	
	public function notSameAs(b:SRT):Bool 
	{
		return 	x != b.x ||	y != b.y ||	scaleX != b.scaleX || scaleY != b.scaleY ||	rotation != b.rotation || sequenceFrame != b.sequenceFrame || sequenceName != b.sequenceName;
	}
	
	public static function fromObject(owner:AnimationTarget, ob:Dynamic):SRT {
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
	public function serialize(export:Bool = false):Dynamic 
	{
		var out:Dynamic = { };
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
	
	public function apply() 
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
	
	public function add(other:SRT, weight) 
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
	
	public function copyFrom(srt:SRT) 
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