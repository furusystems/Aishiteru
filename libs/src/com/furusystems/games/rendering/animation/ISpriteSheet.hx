package com.furusystems.games.rendering.animation;
import com.furusystems.utils.SizedHash;
import flash.display.BitmapData;
import openfl.display.Tilesheet;

/**
 * ...
 * @author Andreas Rønning
 */

interface ISpriteSheet 
{

	public var texture:BitmapData;
	
	public var sequences:SizedHash<ISpriteSequence>; 
	
	public var tilesheet:Tilesheet;
	
	public function getSequenceByName(name:String):ISpriteSequence;
}