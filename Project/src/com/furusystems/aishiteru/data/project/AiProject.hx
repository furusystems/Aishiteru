package com.furusystems.aishiteru.data.project;
import com.furusystems.aishiteru.data.asset.AiAsset;
import com.furusystems.aishiteru.data.exporter.AiExporter;
import com.furusystems.aishiteru.data.ISerializable.ISerializable;
import com.furusystems.aishiteru.data.source.AiSource;
import haxe.Json;

/**
 * ...
 * @author Andreas Rønning
 */
class AiProject implements ISerializable<String>
{
	
	
	public function new() 
	{
		
	}
	
	/* INTERFACE com.furusystems.aishiteru.data.ISerializable.ISerializable<T> */
	
	public function serialize():String 
	{
		return Json.stringify({});
	}
	
	public function deserialize(data:String):Void 
	{
		var ob:Dynamic = Json.parse(data);
	}
	
}