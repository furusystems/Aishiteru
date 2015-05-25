package bonewagon.view;
import flash.display.BlendMode;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
/**
 * ...
 * @author Andreas Rønning
 */

 enum ManipulatorMode {
	 TRANSLATE;
	 ROTATE;
	 SCALE;
 }
 
class Manipulator extends Sprite
{
	var modes = [ManipulatorMode.TRANSLATE, ManipulatorMode.ROTATE, ManipulatorMode.SCALE];
	public var mode = ManipulatorMode.TRANSLATE;
	public function new() 
	{
		super();
		blendMode = BlendMode.INVERT;
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		setMode(mode);
	}
	
	function onAddedToStage(e:Event) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}
	
	function onMouseMove(e:MouseEvent) 
	{
		x = parent.mouseX - 8;
		y = parent.mouseY - 8;
	}
	public function cycleMode() {
		modes.push(modes.shift());
		setMode(modes[0]);
	}
	
	public function setMode(mode:ManipulatorMode) 
	{
		this.mode = mode;
		graphics.clear();
		graphics.lineStyle(0, 0, 1);
		switch(mode) {
			case TRANSLATE:
				graphics.moveTo( -5, 0);
				graphics.lineTo( 6, 0);
				graphics.moveTo( 0, -5);
				graphics.lineTo( 0, 6);
			case ROTATE:
				graphics.drawCircle(0, 0, 5);
			case SCALE:
				graphics.drawRect( -5, -5, 10, 10);
		}
	}
	
}