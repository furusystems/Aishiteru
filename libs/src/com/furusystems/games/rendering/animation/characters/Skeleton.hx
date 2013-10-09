package com.furusystems.games.rendering.animation.characters;
import com.furusystems.games.rendering.animation.characters.vo.Bone;
import haxe.Json;

/**
 * ...
 * @author Andreas Rønning
 */
class Skeleton extends Bone
{
	public function new(json:String) 
	{
		super(Json.parse(json));
	}	
	
}