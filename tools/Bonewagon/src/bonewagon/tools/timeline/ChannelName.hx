package bonewagon.tools.timeline;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormat;
/**
 * ...
 * @author Andreas Rønning
 */
class ChannelName extends Sprite
{
	
	public var nameField:TextField = new TextField();
	public function new() 
	{
		super();
		nameField.defaultTextFormat = new TextFormat("_sans", 8, 0xFFFFFF);
		nameField.selectable = false;
		nameField.height = 20;
		nameField.width = 60;
		nameField.text = "LOREM IPSUM";
		addChild(nameField);
	}
	
}