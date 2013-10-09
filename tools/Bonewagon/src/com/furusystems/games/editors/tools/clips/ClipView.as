package com.furusystems.games.editors.tools.clips 
{
	import com.bit101.components.HBox;
	import com.bit101.components.HSlider;
	import com.bit101.components.InputText;
	import com.bit101.components.PushButton;
	import com.bit101.components.VBox;
	import com.furusystems.games.editors.model.animation.Animation;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.tools.AnimationPalette;
	import com.furusystems.games.editors.utils.ComponentFactory;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ClipView extends Sprite
	{
		private var _selected:Boolean;
		private var nameField:InputText;
		private var controls:VBox;
		private var w:Number;
		private var selectButton:PushButton;
		private var deleteButton:PushButton;
		private var owner:AnimationPalette;
		public var isBasePose:Boolean;
		public var anim:Animation;
		
		public function ClipView(owner:AnimationPalette, anim:Animation, isBasePose:Boolean = false) 
		{
			super();
			this.owner = owner;
			this.isBasePose = isBasePose;
			this.anim = anim;
			w = 20;
			_selected = false;
			controls = new VBox(this);
			controls.spacing = 0;
			nameField = ComponentFactory.labelledInputText("Name", controls);
			nameField.textField.mouseEnabled = !isBasePose;
			nameField.text = isBasePose?"BasePose":anim.name;
			nameField.addEventListener(Event.CHANGE, onNameChange);
			
			var buttons:HBox = new HBox(controls);
			selectButton = new PushButton(buttons, 0, 0, "Select");
			selectButton.addEventListener(MouseEvent.CLICK, onSelect);
			
			if(!isBasePose){
				deleteButton = new PushButton(buttons, 0, 0, "Delete");
				deleteButton.doubleClickEnabled = true;
				deleteButton.addEventListener(MouseEvent.DOUBLE_CLICK, onDelete,false,0,true);
			}
			
		}
		
		private function onNameChange(e:Event):void 
		{
			anim.name = nameField.text;
		}
		
		
		private function onDelete(e:MouseEvent):void 
		{
			if (isBasePose) return;
			var idx:int = SharedModel.animations.indexOf(anim);
			owner.clipViews.splice(owner.clipViews.indexOf(this), 1);
			SharedModel.animations.splice(idx, 1);
			if (SharedModel.playback.currentAnimation == anim) {
				SharedModel.playback.currentAnimation = null;
				if (SharedModel.animations.length == 0) {
					SharedModel.playback.currentAnimation = SharedModel.basePose;
				}else {
					SharedModel.playback.currentAnimation = SharedModel.animations[Math.min(SharedModel.animations.length-1, idx)];
				}
			}
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION_LIST | SharedModel.ANIMATION, null);
		}
		
		private function onSelect(e:MouseEvent):void 
		{
			SharedModel.playback.currentAnimation = anim;
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION_LIST | SharedModel.ANIMATION, anim);
		}
		public function setSize(w:Number):void {
			this.w = w;
			graphics.beginFill(_selected?0xffffff:0xbbbbbb);
			graphics.drawRect(0, 0, w, 44);
			graphics.endFill();
			scrollRect = new Rectangle(0, 0, w, 44);
		}
		
		public function get selected():Boolean 
		{
			return _selected;
		}
		
		public function set selected(value:Boolean):void 
		{
			if (_selected != value && value && !isBasePose) {
				anim.weight = 1;
			}
			_selected = value;
			setSize(w);
		}
		
	}

}