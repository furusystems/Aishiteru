package bonewagon.utils;
import com.furusystems.fl.gui.Label;
import com.furusystems.fl.gui.layouts.HBox;
import flash.display.DisplayObjectContainer;
import flash.display.Sprite;
/**
 * ...
 * @author Andreas Rønning
 */
class ComponentFactory 
{
	
	public static function labelledLabel(label:String, container:DisplayObjectContainer, editable:Bool = false):Label {
		var hbox = new HBox();
		container.addChild(hbox);
		var l:Label = new Label(label);
		hbox.add(l);
		var t:Label = new Label("", 80, 20, false, editable, editable, editable);
		t.height = 20;
		hbox.add(t);
		return t;
	}
	public static function labelledStepper(label:String, container:DisplayObjectContainer):Sprite {
		var hbox = new HBox();
		container.addChild(hbox);
		new Label(label);
		var stepper = new Sprite();
		hbox.addChild(stepper);
		return stepper;
	}
	
}