package com.furusystems.games.rendering.animation.characters;
import com.furusystems.games.rendering.animation.characters.vo.Sample;
import flash.utils.ByteArray;

/**
 * ...
 * @author Andreas Rønning
 */
class Animation
{
	public var source:Dynamic;
	public var frames:Array<Array<Sample>>;
	public var name:String;
	public var duration:Float;
	public var scriptEvents:Array<ScriptEvent>;
	public function new() 
	{
		//this.source = source;
		//duration = source.duration;
		//name = source.name;
		//frames = new Array<Frame>();
		//scriptEvents = new Array<ScriptEvent>();
		//if(source.scripts!=null){
			//for (i in 0...source.scripts.length) {
				//scriptEvents.push(new ScriptEvent(source.scripts[i]));
			//}
		//}
		//trace("Loaded " + scriptEvents.length + " script events");
		//for (i in 0...source.frames.length) {
			//var s = source.frames[i];
			//frames.push(s);
		//}
	}
	public inline function init():Void {
		for (i in scriptEvents) 
		{
			i.hasTriggered = false;
		}
	}
	
	static public function fromBytes(numBones:Int, data:ByteArray):Animation 
	{
		var out:Animation = new Animation();
		out.name = data.readUTF();
		out.duration = data.readFloat();
		var numFrames:Int = data.readUnsignedInt();
		var numScripts:Int = data.readShort();
		out.frames = [];
		for (j in 0...numFrames) {
			var a:Array<Sample> = [];
			for (i in 0...numBones) {
				a.push(new Sample(data));
			}
			out.frames.push(a);
		}
		
		out.scriptEvents = [];
		for (i in 0...numScripts) {
			out.scriptEvents.push(new ScriptEvent(data));
		}
		return out;
	}
	
}