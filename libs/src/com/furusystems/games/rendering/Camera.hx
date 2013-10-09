package com.furusystems.games.rendering;
import com.furusystems.games.vos.UpdateInfo;

/**
 * ...
 * @author Andreas Rønning
 */

class Camera
{
	public var x:Float;
	public var y:Float;
	public var offsetX:Float;
	public var offsetY:Float;
	public var derivedX:Float;
	public var derivedY:Float;
	public var invalid:Bool;
	public var zoom:Float;
	
	public var focalLength:Float;
	public var FOV:Float;
	
	private var _prevX:Float;
	private var _prevY:Float;
	
	private var _rumbleTime:Float;
	private var _rumbleDuration:Float;
	private var _rumbleForce:Float;
	private var _rumbling:Bool;
	public function new() 
	{
		invalid = true;
		zoom = 1;
		focalLength = 0;
		FOV = 90;
	}
	public function validate():Void {
		invalid = (_prevX != derivedX || _prevY != derivedY);
		_prevX = derivedX;
		_prevY = derivedY;
	}
	public function zero():Void {
		x = y = _prevX = _prevY = derivedX = derivedY = offsetX = offsetY = 0;
	}
	public function initialize(x:Float, y:Float):Void {
		zero();
		this.x = _prevX = derivedX = x;
		this.y = _prevY = derivedY = y;
	}
	
	public function step(info:UpdateInfo):Void {
		if (_rumbling) {
			_rumbleTime += info.realDelta;
			var m:Float = 1 - (_rumbleTime / _rumbleDuration);
			offsetX = Math.random() * _rumbleForce * m;
			offsetY = Math.random() * _rumbleForce * m;
			if (_rumbleTime >= _rumbleDuration) _rumbling = false;
		}else {
			offsetX = offsetY = 0;
		}
		derivedX = x + offsetX;
		derivedY = y + offsetY;
		//trace("Camera step: " + derivedX + ", " + derivedY);
	}
	public function rumble(force:Float, durationSeconds:Float = 1):Void {
		_rumbleDuration = durationSeconds;
		_rumbleTime = 0;
		_rumbleForce = force;
		_rumbling = true;
	}
	
	
}