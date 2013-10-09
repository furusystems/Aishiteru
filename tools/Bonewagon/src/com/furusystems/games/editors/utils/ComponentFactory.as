package com.furusystems.games.editors.utils 
{
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import flash.display.DisplayObjectContainer;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ComponentFactory 
	{
		
		public static function labelledInputText(label:String, container:DisplayObjectContainer):InputText {
			var hbox:HBox = new HBox(container);
			var l:Label = new Label(hbox, 0, 0, label);
			var t:InputText = new InputText(hbox, 0, 0, "", null);
			t.textField.height = 18;
			return t;
		}
		public static function labelledStepper(label:String, container:DisplayObjectContainer):NumericStepper {
			var hbox:HBox = new HBox(container);
			new Label(hbox, 0, 0, label);
			return new NumericStepper(hbox);
		}
		
	}

}