package no.doomsday.games.tools.pathtool.data 
{
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public interface ISerializable 
	{
		function serialize():XML;
		function deserialize(xml:XML):void;
	}
	
}