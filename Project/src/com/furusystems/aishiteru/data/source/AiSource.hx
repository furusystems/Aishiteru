package com.furusystems.aishiteru.data.source;
import com.furusystems.aishiteru.data.ISerializable.ISerializable;
import com.furusystems.aishiteru.IDisposable;

/**
 * Sources are pointers to a file
 * @author Andreas Rønning
 */
class AiSource implements ISerializable<Dynamic> implements IDisposable
{
	
	public function new() 
	{
		
	}
	
	/* INTERFACE com.furusystems.aishiteru.data.ISerializable.ISerializable<T> */
	
	public function serialize():Dynamic 
	{
		return {};
	}
	
	public function deserialize(data:String):Void 
	{
		
	}
	
	/* INTERFACE com.furusystems.aishiteru.IDisposable */
	
	public function dispose():Void 
	{
		
	}
	
}