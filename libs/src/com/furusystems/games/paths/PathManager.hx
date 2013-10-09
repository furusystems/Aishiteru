package com.furusystems.games.paths;
import openfl.Assets;

/**
 * ...
 * @author johndatadavies@gmail.com
 */


class PathManager 
{
	private static var items:Map<String, Path> = new Map<String, Path>();
	
	public static function get(pathPath:String):Path
	{
		if (items.exists(pathPath)) return items.get(pathPath);
		var p:Path = Path.deserialize(Assets.getText(pathPath));
		p.center();
		items.set(pathPath, p);
		return p;
	}
	
	public static function clear():Void
	{
		items = new Map<String, Path>();
	}
	
	public static function getFlipped(pathPath:String):Path
	{
		if (items.exists(pathPath + "_flipped"))
		{
			// already been flipped and stored, return it
			return items.get(pathPath + "_flipped");
		}
		else if (items.exists(pathPath))
		{
			// unflipped version already stored, flip it, store it and return it
			var p:Path = items.get(pathPath);
			p = p.flipVertical(true);
			items.set(pathPath + "_flipped", p);
			return p;
		} else {
			// unflipped version not even stored, get it, flip it, store it and return it
			var p:Path = get(pathPath);
			p = p.flipVertical(true);
			items.set(pathPath + "_flipped", p);
			return p;
		}
	}
	
}