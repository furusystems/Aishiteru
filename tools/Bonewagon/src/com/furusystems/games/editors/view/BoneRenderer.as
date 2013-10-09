package com.furusystems.games.editors.view 
{
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import com.furusystems.games.editors.model.skeleton.Skeleton;
	import com.furusystems.games.editors.utils.Transformations;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class BoneRenderer extends Sprite
	{	
		public var tool:Manipulator = new Manipulator();
		public var labels:Sprite = new Sprite();
		private var hit:Bone = null;
		private var clickPosition:Point;
		private var deltaPosition:Point;
		private var s:Skeleton;
		private var format:TextFormat = new TextFormat("_sans", 10);
		public var drawLabels:Boolean = true;
		public var drawBones:Boolean = true;
		private var mouseButton:int = -1;
		private var mouseDown:Boolean = false;
		private var creatingNewBone:Boolean;
		private var lastDraw:int = -1;
		public function BoneRenderer() 
		{
			super();
			alpha = 0.9;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			SharedModel.onChanged.add(onModelChange);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMouseDown);
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addChild(labels);
			addChild(tool);
		}
		
		private function onMouseDown(e:MouseEvent):void 
		{
			if (mouseDown) return;
			creatingNewBone = false;
			switch(e.type) {
				case MouseEvent.MOUSE_DOWN:
					mouseButton = 0;
					break;
				case MouseEvent.RIGHT_MOUSE_DOWN:
					mouseButton = 1;
					tool.setMode(Manipulator.TRANSLATE);
					break;
				case MouseEvent.MIDDLE_MOUSE_DOWN:
					mouseButton = 2;
					break;
			}
			//search for clicked object
			clickPosition = SharedModel.worldMatrixInverse.deltaTransformPoint(new Point(mouseX-SharedModel.cameraPos.x, mouseY-SharedModel.cameraPos.y));
			deltaPosition = SharedModel.worldMatrixInverse.deltaTransformPoint(new Point(e.stageX, e.stageY));
			
			var hits:Array = s.hitTest(clickPosition);
			if (hits.length == 0) return;
			var clickedCurrent:Boolean = false;
			for (var i:int = 0; i < hits.length; i++) 
			{
				if (hits[i] == SharedModel.skeleton.selectedBone) {
					clickedCurrent = true;
					break;
				}
			}
			if (clickedCurrent) {
				hit = SharedModel.skeleton.selectedBone;
			}else {
				hit = hits.pop(); //assume the latest is the highest
			}
			
			switch(mouseButton) {
				case 1:
					//create a new bone
					SharedModel.skeleton.selectedBone = hit = hit.addBone("");
					creatingNewBone = true;
					break;
				case 2:
					SharedModel.skeleton.selectedBone = hit;
					SharedModel.onChanged.dispatch(SharedModel.SELECTION, null);
					return;
				default:
					SharedModel.skeleton.selectedBone = hit;
					
			}
			SharedModel.onChanged.dispatch(SharedModel.SELECTION, null);
			mouseDown = true;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMouseUp);
			
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			switch(e.keyCode) {
				case Keyboard.Q:
					tool.setMode(Manipulator.ROTATE);
					break;
				case Keyboard.W:
					tool.setMode(Manipulator.SCALE);
					break;
				case Keyboard.E:
					tool.setMode(Manipulator.TRANSLATE);
					break;
				case Keyboard.M:
					mirrorCurrent();
					break;
				case Keyboard.BACKSPACE:
					deleteCurrent();
					break;
			}
		}
		
		private function mirrorCurrent():void 
		{
			if (SharedModel.selection == null || SharedModel.selection.parent == null) return; //don't allow the root to be duplicated
			var copy:Bone = SharedModel.selection.copy(true);
			copy.mirror(Bone.X_AXIS);
			SharedModel.selection.parent.addChild(copy);
			SharedModel.onChanged.dispatch(SharedModel.STRUCTURE, null);
		}
		
		private function deleteCurrent():void 
		{
			if (SharedModel.selection == null) return;
			var b:Bone = SharedModel.selection;
			if (b.parent == null) return;
			var p:Bone = b.parent;
			b.parent.removeChild(b);
			b.dispose();
			SharedModel.selection = p;
			SharedModel.onChanged.dispatch(SharedModel.STRUCTURE | SharedModel.SELECTION, null);
		}
		
		private function onMouseUp(e:MouseEvent):void 
		{
			if (creatingNewBone) {
				SharedModel.onChanged.dispatch(SharedModel.STRUCTURE, null);
			}
			mouseDown = false;
			mouseButton = -1;
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseUp);
		}
		
		private function onMouseMove(e:MouseEvent):void 
		{
			var stagePoint:Point = SharedModel.worldMatrixInverse.deltaTransformPoint(new Point(e.stageX, e.stageY));
			var dx:Number, dy:Number;
			var p:Point;
			switch(tool.mode) {
				case Manipulator.ROTATE:
					var angle:Number = 0;
					dy = stagePoint.y - deltaPosition.y; 
					hit.rotation += dy/100;
					break;
				case Manipulator.SCALE:
					dx = stagePoint.x - deltaPosition.x;
					dy = stagePoint.y - deltaPosition.y;
					if (e.ctrlKey) {
						dx = 0;
					}else if (e.shiftKey) {
						dy = 0;
					}
					var pt:Point = new Point(dx, dy);
					//var pt:Point = new Point(Math.cos(hit.rotation)*dx, Math.sin(hit.rotation)*dy);
					//var mat:Matrix = hit.getGlobalMatrix();
					//var pt:Point = mat.deltaTransformPoint(new Point(dx, dy));
					hit.scale.x += pt.x / 1000;
					hit.scale.y += pt.y / 1000;
					deltaPosition.x = stagePoint.x;
					deltaPosition.y = stagePoint.y;
					break;
				case Manipulator.TRANSLATE:
					
					var snapping:Boolean = e.shiftKey;
					dx = stagePoint.x - deltaPosition.x;
					dy = stagePoint.y - deltaPosition.y;
					if(hit.parent!=null){
						p = Transformations.transformPoint(new Point(dx, dy), hit.parent.getGlobalMatrix());
						hit.position.x += p.x;
						hit.position.y += p.y;
					}else {
						hit.position.x += dx;
						hit.position.y += dy;
					}
					break;
			}
			
			deltaPosition.x = stagePoint.x;
			deltaPosition.y = stagePoint.y;
			trace("Changing: " + SharedModel.selection.name+", "+SharedModel.selection.boneID);
			SharedModel.onChanged.dispatch(SharedModel.BONES, SharedModel.selection.boneID);
		}
		
		private function onModelChange(flags:int, data:Object):void 
		{
			if (flags & SharedModel.ANIMATION) render(SharedModel.skeleton);
		}
		public function render(s:Skeleton):void {
			if (lastDraw == SharedModel.currentFrame) return;
			lastDraw = SharedModel.currentFrame;
			this.s = s;
			graphics.clear();
			labels.removeChildren();
			if(drawBones) drawBone(s, SharedModel.worldMatrix);
		}
		
		public function nudgeLeft():void 
		{
			if (SharedModel.selection == null) return;
			switch(tool.mode) {
				case Manipulator.ROTATE:
					SharedModel.selection.rotation -= .01;
					break;
				case Manipulator.SCALE:
					SharedModel.selection.scale.x -= .01;
					break;
				case Manipulator.TRANSLATE:
					SharedModel.selection.position.x -= 1;
					break;
			}
			SharedModel.onChanged.dispatch(SharedModel.BONES, SharedModel.selection.boneID);
		}
		
		public function nudgeRight():void 
		{
			if (SharedModel.selection == null) return;
			switch(tool.mode) {
				case Manipulator.ROTATE:
					SharedModel.selection.rotation += .01;
					break;
				case Manipulator.SCALE:
					SharedModel.selection.scale.x += .01;
					break;
				case Manipulator.TRANSLATE:
					SharedModel.selection.position.x += 1;
					break;
			}
			SharedModel.onChanged.dispatch(SharedModel.BONES, SharedModel.selection.boneID);
		}
		
		public function nudgeUp():void 
		{
			if (SharedModel.selection == null) return;
			switch(tool.mode) {
				case Manipulator.ROTATE:
					SharedModel.selection.rotation += Math.PI/2;
					break;
				case Manipulator.SCALE:
					SharedModel.selection.scale.y += .01;
					break;
				case Manipulator.TRANSLATE:
					SharedModel.selection.position.y -= 1;
					break;
			}
			SharedModel.onChanged.dispatch(SharedModel.BONES, SharedModel.selection.boneID);
		}
		
		public function nudgeDown():void 
		{
			if (SharedModel.selection == null) return;
			switch(tool.mode) {
				case Manipulator.ROTATE:
					SharedModel.selection.rotation -= Math.PI/2;
					break;
				case Manipulator.SCALE:
					SharedModel.selection.scale.y -= .01;
					break;
				case Manipulator.TRANSLATE:
					SharedModel.selection.position.y += 1;
					break;
			}
			SharedModel.onChanged.dispatch(SharedModel.BONES, SharedModel.selection.boneID);
		}
		private function drawBone(b:Bone, parent:Matrix = null):void {
			var m:Matrix = b.getLocalMatrix();
			if (parent != null) {
				m.concat(parent);
				if(b.parent!=null){
					var p:Matrix = parent;
					graphics.lineStyle(0, b.color);
					graphics.moveTo(m.tx, m.ty);
					graphics.lineTo(p.tx, p.ty);
					graphics.lineStyle();
				}
			}
			if(drawLabels){
				var tf:TextField = new TextField();
				tf.autoSize = TextFieldAutoSize.LEFT;
				tf.defaultTextFormat = format;
				tf.textColor = 0xFFFFFF;
				tf.text = b.name;
				tf.background = true;
				tf.backgroundColor = 0x111111;
				tf.mouseEnabled = false;
				tf.alpha = 0.8;
				tf.x = m.tx+5;
				tf.y = m.ty+5;
				labels.addChild(tf);
			}
			
			if (SharedModel.skeleton.selectedBone == b) {
				graphics.lineStyle(2, 0xFFFFFF);
			}
			//var scaleNorm:Number = (b.scale.x + b.scale.y) / 2;
			graphics.beginFill(b.color);
			//var w:Number = b.scale.x * 20;
			//var h:Number = b.scale.y * 20;
			//graphics.drawEllipse(m.tx - w / 2, m.ty - h / 2, w, h);
			graphics.drawCircle(m.tx, m.ty, 10);
			graphics.endFill();
			
			graphics.lineStyle(0, 0xFF0000, 0.5);
			graphics.moveTo(m.tx, m.ty);
			var lp:Point = new Point(20, 0);
			lp = m.transformPoint(lp);
			graphics.lineTo(lp.x, lp.y);
			
			graphics.lineStyle(0, 0x00FF00, 0.5);
			graphics.moveTo(m.tx, m.ty);
			lp = new Point(0, 20);
			lp = m.transformPoint(lp);
			graphics.lineTo(lp.x, lp.y);

			for (var i:int = 0; i < b.children.length; i++) 
			{
				drawBone(b.children[i], m);
			}
		}
		
	}

}