package com.furusystems.games.editors.model.skeleton 
{
	import com.furusystems.games.editors.model.animation.Animation;
	import com.furusystems.games.editors.model.animation.SRT;
	import com.furusystems.games.editors.model.SharedModel;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Skeleton extends Bone
	{
		public var selectedBone:Bone = null;
		public var boneCount:int = 1;
		public var allBones:Vector.<Bone>;
		public function Skeleton() 
		{
			allBones = new Vector.<Bone>(256, true);
			super("root");
			allBones[boneID] = this;
		}
		
		
		public function buildDummyData():void 
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
			SharedModel.onChanged.dispatch(SharedModel.STRUCTURE | SharedModel.BONES, boneID);
		}
		override public function deserialize(ob:Object):void 
		{
			trace("Deserializing skeleton");
			clear();
			super.deserialize(ob);
			uidPool = Math.max(uidPool, listBones().length);
			trace("Final uidPool: " + uidPool);
		}
		
		public function getWorldStates():Array 
		{
			var out:Array = [];
			var list:Vector.<Bone> = listBones();
			for (var i:int = 0; i < list.length; i++) 
			{
				out.push(list[i].getWorldFrame());
			}
			return out;
		}
		
		public function getExportStates():Array {
			var out:Array = [];
			var list:Vector.<Bone> = listBones();
			for (var i:int = 0; i < list.length; i++) 
			{
				out.push(list[i].getFrame());
			}
			return out;
		}
		
		public function export(out:ByteArray):void 
		{
			out.writeUTF(JSON.stringify(serialize()));
		}
		
		
		private function clear():void 
		{
			trace("Clearing skeleton");
			children = new Vector.<Bone>();
			boneCount = 1;
			Bone.uidPool = 1;
			allBones = new Vector.<Bone>(256, true);
			allBones[boneID] = this;
			trace("Root bone ID: " + boneID);
			selectedBone = null;
		}
		
		
	}

}