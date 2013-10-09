package com.furusystems.games.editors.tools.timeline 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ChannelName extends Sprite
	{
		
		public var nameField:TextField = new TextField();
		public function ChannelName() 
		{
			nameField.defaultTextFormat = new TextFormat("_sans", 8, 0xFFFFFF);
			nameField.selectable = false;
			nameField.height = 20;
			nameField.width = 60;
			nameField.text = "THIS IS BULLSHIT";
			addChild(nameField);
		}
		
	}

}