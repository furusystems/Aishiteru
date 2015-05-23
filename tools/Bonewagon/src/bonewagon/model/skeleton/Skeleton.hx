package bonewagon.model.skeleton;
import bonewagon.model.animation.Animation;
import bonewagon.model.animation.SRT;
import bonewagon.model.SharedModel;
import flash.utils.ByteArray;
import haxe.ds.Vector;
import haxe.Json;
/**
 * ...
 * @author Andreas Rønning
 */
class Skeleton extends Bone
{
	public var selectedBone:Bone = null;
	public var boneCount:Int = 1;
	public var allBones:Array<Bone>;
	public function new() 
	{
		allBones = new Array<Bone>();
		for (i in 0...256)
			allBones.push(null);
			
		super("root");
		allBones[boneID] = this;
	}
	
	
	public function buildDummyData() 
	{
		var back:Bone = addBone("back",0,-50);
		var neck:Bone = back.addBone("neck",0, -50);
		var head:Bone = neck.addBone("head",0,-40);
		
		var leftArm:Bone = neck.addBone("leftArm", -50, 0);
		var leftHand:Bone = leftArm.addBone("leftHand", -50,0);
		
		var rightArm:Bone = neck.addBone("rightArm",50,0);
		var rightHand:Bone = rightArm.addBone("rightHand",50,0);
		
		var leftLeg:Bone = addBone("leftLeg",-25,50);
		var leftFoot:Bone = leftLeg.addBone("leftFoot", 0, 50);
		var rightLeg:Bone = addBone("rightLeg", 25,50);
		var rightFoot:Bone = rightLeg.addBone("rightFoot", 0, 50);
		SharedModel.onChanged.dispatch(SharedModel.STRUCTURE | SharedModel.BONES, ChangedData.next(boneID));
	}
	override public function deserialize(ob:Dynamic) 
	{
		trace("Deserializing skeleton");
		clear();
		super.deserialize(ob);
		Bone.uidPool = cast Math.max(Bone.uidPool, listBones().length);
		trace("Final uidPool: " + Bone.uidPool);
	}
	
	public function getWorldStates():Array<Dynamic> 
	{
		var out:Array<Dynamic> = [];
		var list:Array<Bone> = listBones();
		for (b in list) 
		{
			out.push(b.getWorldFrame());
		}
		return out;
	}
	
	public function getExportStates():Array<Dynamic> {
		var out:Array<Dynamic> = [];
		var list:Array<Bone> = listBones();
		for (b in list) 
		{
			out.push(b.getFrame());
		}
		return out;
	}
	
	public function export(out:ByteArray) 
	{
		out.writeUTF(Json.stringify(serialize()));
	}
	
	
	function clear() 
	{
		trace("Clearing skeleton");
		children = new Array<Bone>();
		boneCount = 1;
		Bone.uidPool = 1;
		allBones = new Array<Bone>();
		allBones[boneID] = this;
		trace("Root bone ID: " + boneID);
		selectedBone = null;
	}
	
	
}