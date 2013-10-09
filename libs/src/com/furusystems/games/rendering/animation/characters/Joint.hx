package com.furusystems.games.rendering.animation.characters;
import com.furusystems.games.rendering.animation.characters.vo.Bone;
import com.furusystems.games.rendering.animation.characters.vo.Sample;
import flash.geom.Matrix;
import flash.Vector;

/**
 * ...
 * @author Andreas Rønning
 */
class Joint
{
	public var id:Int = -1;
	public var x:Float = 0;
	public var y:Float = 0;
	public var sX:Float = 1;
	public var sY:Float = 1;
	public var rotation:Float = 0;
	public var frame:Int = 0;
	public var sequence:String;
	public var z:Float = 0;
	public var children:Array<Joint>;
	public var parent:Joint = null;
	public var owner:Bone = null;
	
	private var prevSRT:Sample = null;
	
	public var matrix:Matrix;
	
	public function new(bone:Bone) 
	{
		owner = bone;
		this.id = bone.boneID;
		sequence = "n/a";
		children = [];
		matrix = new Matrix();
	}
	public inline function setSRT(input:Sample):Void {
		sX = input.scaleX;
		sY = input.scaleY;
		rotation = input.rotation;
		x = input.x;
		y = input.y;
		prevSRT = input;
	}
	public inline function addSRT(input:Sample, weight:Float):Void {
		//var diffX:Null = 
		//var diffY:Null = 
		//sX = input.scaleX;
		//sY = input.scaleY;
		sX = prevSRT.scaleX + (input.scaleX - prevSRT.scaleX) * weight;
		sY = prevSRT.scaleY + (input.scaleY - prevSRT.scaleY) * weight;
		rotation += input.rotation*weight;
		x += input.x*weight;
		y += input.y*weight;
	}
	public inline function zeroSRT():Void {
		sX = sY = 1;
		rotation = x = y = 0;
	}
	#if haxe3
	public inline function updateMatrices(parent:Matrix):Void {
	#else
	public function updateMatrices(parent:Matrix):Void {
	#end
		matrix.identity();
		matrix.rotate(rotation);
		matrix.scale(sX, sY);
		matrix.translate(x, y);
		
		matrix.concat(parent);
		
		for (j in children) {
			j.updateMatrices(matrix);
		}
		
	}
}