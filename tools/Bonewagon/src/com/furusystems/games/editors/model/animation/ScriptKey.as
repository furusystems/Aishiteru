package com.furusystems.games.editors.model.animation 
{
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ScriptKey 
	{
		public var script:String = "";
		public var time:Number = 0;
		public var selected:Boolean = false;
		public function ScriptKey() 
		{
			
		}
		public function serialize():Object {
			return { script:script, time:time };
		}
		public static function fromOb(ob:Object):ScriptKey {
			var s:ScriptKey = new ScriptKey();
			s.time = ob.time;
			s.script = ob.script;
			return s;
		}
		
	}

}