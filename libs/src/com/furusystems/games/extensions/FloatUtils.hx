package com.furusystems.games.extensions;

/**
 * ...
 * @author Andreas Rønning
 */
class FloatUtils
{

	public static function toPrecision(f:Float, numDecimals:Int):Float {
		f *= Math.pow(10, numDecimals);
		return Math.round(f) / Math.pow(10, numDecimals);
	}
	
}