package bonewagon.model.animation;
/**
 * ...
 * @author Andreas Rønning
 */
class ScriptKey 
{
	public var script:String = "";
	public var time:Float = 0;
	public var selected:Bool = false;
	public function new() 
	{
		
	}
	public function serialize():Dynamic {
		return { script:script, time:time };
	}
	public static function fromOb(ob:Dynamic):ScriptKey {
		var s:ScriptKey = new ScriptKey();
		s.time = ob.time;
		s.script = ob.script;
		return s;
	}
	
}