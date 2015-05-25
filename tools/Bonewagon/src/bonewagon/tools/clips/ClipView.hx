package bonewagon.tools.clips;
import bonewagon.model.animation.Animation;
import bonewagon.model.SharedModel;
import bonewagon.tools.AnimationPalette;
import bonewagon.utils.ComponentFactory;
import com.furusystems.fl.gui.Button;
import com.furusystems.fl.gui.Label;
import com.furusystems.fl.gui.layouts.HBox;
import com.furusystems.fl.gui.layouts.VBox;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
/**
 * ...
 * @author Andreas Rønning
 */
class ClipView extends Sprite
{
	var _selected:Bool;
	var w:Float;
	var nameField:Label;
	var controls:VBox;
	var selectButton:Button;
	var deleteButton:Button;
	var owner:AnimationPalette;
	public var isBasePose:Bool;
	public var anim:Animation;
	
	public function new(owner:AnimationPalette, anim:Animation, isBasePose:Bool = false) 
	{
		super();
		this.owner = owner;
		this.isBasePose = isBasePose;
		this.anim = anim;
		w = 20;
		_selected = false;
		
		controls = new VBox();
		addChild(controls);
		controls.spacing = 0;
		nameField = ComponentFactory.labelledLabel("Name", controls);
		nameField.mouseEnabled = !isBasePose;
		nameField.text = isBasePose?"BasePose":anim.name;
		nameField.addEventListener(Event.CHANGE, onNameChange);
		
		var buttons = controls.add(new HBox());
		selectButton = buttons.add(new Button("Select"));
		selectButton.addEventListener(MouseEvent.CLICK, onSelect);
		
		if(!isBasePose){
			deleteButton = buttons.add(new Button("Delete"));
			deleteButton.doubleClickEnabled = true;
			deleteButton.addEventListener(MouseEvent.DOUBLE_CLICK, onDelete,false,0,true);
		}
		
	}
	
	function onNameChange(e:Event) 
	{
		//anim.name = nameField.text;
	}
	
	
	function onDelete(e:MouseEvent) 
	{
		if (isBasePose) return;
		var idx:Int = SharedModel.animations.indexOf(anim);
		owner.clipViews.splice(owner.clipViews.indexOf(this), 1);
		SharedModel.animations.splice(idx, 1);
		if (SharedModel.playback.currentAnimation == anim) {
			SharedModel.playback.currentAnimation = null;
			if (SharedModel.animations.length == 0) {
				SharedModel.playback.currentAnimation = SharedModel.basePose;
			}else {
				SharedModel.playback.currentAnimation = SharedModel.animations[cast Math.min(SharedModel.animations.length-1, idx)];
			}
		}
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION_LIST | SharedModel.ANIMATION, null);
	}
	
	function onSelect(e:MouseEvent) 
	{
		SharedModel.playback.currentAnimation = anim;
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION_LIST | SharedModel.ANIMATION, ChangedData.next(anim));
	}
	public function setSize(w) {
		this.w = w;
		graphics.beginFill(_selected?0xffffff:0xbbbbbb);
		graphics.drawRect(0, 0, w, 44);
		graphics.endFill();
		scrollRect = new Rectangle(0, 0, w, 44);
	}
	
	public var selected(get, set):Bool;
	
	public function get_selected():Bool 
	{
		return _selected;
	}
	
	public function set_selected(value:Bool):Bool 
	{
		if (_selected != value && value && !isBasePose) {
			anim.weight = 1;
		}
		_selected = value;
		setSize(w);
		return _selected;
	}
	
}