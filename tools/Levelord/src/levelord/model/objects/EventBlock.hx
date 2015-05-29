package levelord.model.objects;
import levelord.model.objects.EventBlock.TimeSpan;

/**
 * ...
 * @author Andreas Rønning
 */

class TimeSpan {
	public var start(default, set):Float;
	public var end(default, set):Float;
	public var duration(get, null):Float;
	
	inline function get_duration():Float {
		return end - start;
	}
	inline function set_start(f:Float):Float {
		return start = Math.min(f, end);
	}
	inline function set_end(f:Float):Float {
		return end = Math.max(f, start);
	}
	
}

class EventBlock
{
	static var uidPool:Int = 0;
	
	public var uid(get, never):Int;
	public var label:String = "";
	public var timespan:TimeSpan;
	public var splines:Array<WorldSpline>;
	public var scripts:Array<ScriptKey>;
	
	var _uid:Int;
	inline function get_uid():Int {
		return _uid;
	}
	public function new() 
	{
		scripts = [];
		splines = [];
		_uid = uidPool++;
		name = genName();
	}
	public function genName() {
		label = "Block_" + _uid;
	}
	
}