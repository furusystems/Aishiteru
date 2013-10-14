package com.furusystems.aishiteru.data.importer;
import com.furusystems.aishiteru.data.source.AiSource;
import com.furusystems.aishiteru.IDisposable;

/**
 * ...
 * @author Andreas Rønning
 */
class AiImporter implements IDisposable
{
	public var source:Null<AiSource>;
	public function new(source:AiSource) 
	{
		this.source = source;
		
	}
	
	/* INTERFACE com.furusystems.aishiteru.IDisposable */
	
	public function dispose():Void 
	{
		source = null;
	}
	
}