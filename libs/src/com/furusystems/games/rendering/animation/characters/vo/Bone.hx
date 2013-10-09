package com.furusystems.games.rendering.animation.characters.vo;
import flash.geom.Point;

/**
 * ...
 * @author Andreas Rønning
 */
class Bone
{
	public var boneID:Int;
	public var localOffset:Point;
	public var children:Array<Bone>;
	public var name:String;
	public function new(ob:Dynamic) 
	{
		this.boneID = ob.boneID;
		this.children = [];
		this.name = ob.name;
		localOffset = new Point(ob.localOffset.x, ob.localOffset.y);
		for (i in 0...ob.children.length){
			children.push(new Bone(ob.children[i]));
		}
	}
	
	public function getBoneByName(name:String):Bone 
	{
		if (this.name == name) return this;
		for (b in children) 
		{
			var n = b.getBoneByName(name);
			if (n != null) return n;
		}
		return null;
	}
	
}