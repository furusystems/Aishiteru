package com.furusystems.games.rendering;
import flash.display.Sprite;
import openfl.display.Tilesheet;

/**
 * ...
 * @author Andreas Rønning
 */

class TileSurface extends Sprite
{

	public var flags:Int;
	public var smoothing:Bool;
	public var info:Array<Float>;
	public var tilesheet:Tilesheet;
	private var drawn:Bool;
	public function new(tilesheet:Tilesheet, ?info:Array<Float>, flags:Int = 0, ?smoothing:Bool = false) 
	{
		super();
		this.tilesheet = tilesheet;
		this.info = info;
		this.flags = flags;
		this.smoothing = smoothing;
		if (info != null)
		{
			update(info, flags, smoothing);
		}
	}
	public function update(info:Array<Float>, ?flags:Int, ?smoothing:Bool, ?clear:Bool = true):Void
	{
		if (flags == null) flags = this.flags;
		if (smoothing == null) smoothing = this.smoothing;
		if (clear)  graphics.clear();
		tilesheet.drawTiles(graphics, info, smoothing, flags);
	}

	public function hide():Void
	{
		this.alpha = 0.0;
	}

	public function show():Void
	{
		this.alpha = 1.0;
	}

	public function clear():Void
	{
		graphics.clear();
	}
	
}