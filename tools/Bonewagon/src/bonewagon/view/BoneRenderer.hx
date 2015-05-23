package bonewagon.view;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
import bonewagon.model.skeleton.Skeleton;
import bonewagon.view.Manipulator.ManipulatorMode;
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

using extensions.Transformations;
/**
 * ...
 * @author Andreas Rønning
 */
class BoneRenderer extends Sprite
{	
	public var tool:Manipulator = new Manipulator();
	public var labels:Sprite = new Sprite();
	var hit:Bone = null;
	var clickPosition:Point;
	var deltaPosition:Point;
	var s:Skeleton;
	var format:TextFormat = new TextFormat("_sans", 10);
	public var drawLabels:Bool = true;
	public var drawBones:Bool = true;
	var mouseButton:Int = -1;
	var mouseDown:Bool = false;
	var creatingNewBone:Bool;
	var lastDraw:Int = -1;
	public function new() 
	{
		super();
		alpha = 0.9;
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		SharedModel.onChanged.add(onModelChange);
		addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseDown);
		addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMouseDown);
	}
	
	function onAddedToStage(e:Event) 
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		addChild(labels);
		addChild(tool);
	}
	
	function onMouseDown(e:MouseEvent) 
	{
		if (mouseDown) return;
		creatingNewBone = false;
		switch(e.type) {
			case MouseEvent.MOUSE_DOWN:
				mouseButton = 0;
			case MouseEvent.RIGHT_MOUSE_DOWN:
				mouseButton = 1;
				tool.setMode(ManipulatorMode.TRANSLATE);
			case MouseEvent.MIDDLE_MOUSE_DOWN:
				mouseButton = 2;
		}
		//search for clicked object
		clickPosition = SharedModel.worldMatrixInverse.deltaTransformPoint(new Point(mouseX-SharedModel.cameraPos.x, mouseY-SharedModel.cameraPos.y));
		deltaPosition = SharedModel.worldMatrixInverse.deltaTransformPoint(new Point(e.stageX, e.stageY));
		
		var hits = s.hitTest(clickPosition);
		if (hits.length == 0) return;
		var clickedCurrent:Bool = false;
		for (h in hits) 
		{
			if (h == SharedModel.skeleton.selectedBone) {
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
			case 2:
				SharedModel.skeleton.selectedBone = hit;
				SharedModel.onChanged.dispatch(SharedModel.SELECTION, null);
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
	
	function onKeyDown(e:KeyboardEvent) 
	{
		switch(e.keyCode) {
			case Keyboard.Q:
				tool.setMode(ManipulatorMode.ROTATE);
			case Keyboard.W:
				tool.setMode(ManipulatorMode.SCALE);
			case Keyboard.E:
				tool.setMode(ManipulatorMode.TRANSLATE);
			case Keyboard.M:
				mirrorCurrent();
			case Keyboard.BACKSPACE:
				deleteCurrent();
		}
	}
	
	function mirrorCurrent() 
	{
		if (SharedModel.selection == null || SharedModel.selection.parent == null) return; //don't allow the root to be duplicated
		var copy:Bone = SharedModel.selection.copy(true);
		copy.mirror(Axis.X);
		SharedModel.selection.parent.addChild(copy);
		SharedModel.onChanged.dispatch(SharedModel.STRUCTURE, null);
	}
	
	function deleteCurrent() 
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
	
	function onMouseUp(e:MouseEvent) 
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
	
	function onMouseMove(e:MouseEvent) 
	{
		var stagePoint:Point = SharedModel.worldMatrixInverse.deltaTransformPoint(new Point(e.stageX, e.stageY));
		var dx, dy;
		var p:Point;
		switch(tool.mode) {
			case ManipulatorMode.ROTATE:
				var angle = 0;
				dy = stagePoint.y - deltaPosition.y; 
				hit.rotation += dy/100;
			case ManipulatorMode.SCALE:
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
			case ManipulatorMode.TRANSLATE:
				
				var snapping:Bool = e.shiftKey;
				dx = stagePoint.x - deltaPosition.x;
				dy = stagePoint.y - deltaPosition.y;
				if(hit.parent!=null){
					p = new Point(dx, dy).transform(hit.parent.getGlobalMatrix());
					hit.position.x += p.x;
					hit.position.y += p.y;
				}else {
					hit.position.x += dx;
					hit.position.y += dy;
				}
		}
		
		deltaPosition.x = stagePoint.x;
		deltaPosition.y = stagePoint.y;
		trace("Changing: " + SharedModel.selection.name+", "+SharedModel.selection.boneID);
		SharedModel.onChanged.dispatch(SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	
	function onModelChange(flags:Int, data:Dynamic) 
	{
		if (flags & SharedModel.ANIMATION != 0) render(SharedModel.skeleton);
	}
	public function render(s:Skeleton) {
		if (lastDraw == SharedModel.currentFrame) return;
		lastDraw = SharedModel.currentFrame;
		this.s = s;
		graphics.clear();
		labels.removeChildren();
		if(drawBones) drawBone(s, SharedModel.worldMatrix);
	}
	
	public function nudgeLeft() 
	{
		if (SharedModel.selection == null) return;
		switch(tool.mode) {
			case ManipulatorMode.ROTATE:
				SharedModel.selection.rotation -= .01;
			case ManipulatorMode.SCALE:
				SharedModel.selection.scale.x -= .01;
			case ManipulatorMode.TRANSLATE:
				SharedModel.selection.position.x -= 1;
		}
		SharedModel.onChanged.dispatch(SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	
	public function nudgeRight() 
	{
		if (SharedModel.selection == null) return;
		switch(tool.mode) {
			case ManipulatorMode.ROTATE:
				SharedModel.selection.rotation += .01;
			case ManipulatorMode.SCALE:
				SharedModel.selection.scale.x += .01;
			case ManipulatorMode.TRANSLATE:
				SharedModel.selection.position.x += 1;
		}
		SharedModel.onChanged.dispatch(SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	
	public function nudgeUp() 
	{
		if (SharedModel.selection == null) return;
		switch(tool.mode) {
			case ManipulatorMode.ROTATE:
				SharedModel.selection.rotation += Math.PI/2;
			case ManipulatorMode.SCALE:
				SharedModel.selection.scale.y += .01;
			case ManipulatorMode.TRANSLATE:
				SharedModel.selection.position.y -= 1;
		}
		SharedModel.onChanged.dispatch(SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	
	public function nudgeDown() 
	{
		if (SharedModel.selection == null) return;
		switch(tool.mode) {
			case ManipulatorMode.ROTATE:
				SharedModel.selection.rotation -= Math.PI/2;
			case ManipulatorMode.SCALE:
				SharedModel.selection.scale.y -= .01;
			case ManipulatorMode.TRANSLATE:
				SharedModel.selection.position.y += 1;
		}
		SharedModel.onChanged.dispatch(SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	function drawBone(b:Bone, parent:Matrix = null) {
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
		//var scaleNorm = (b.scale.x + b.scale.y) / 2;
		graphics.beginFill(b.color);
		//var w = b.scale.x * 20;
		//var h = b.scale.y * 20;
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

		for (c in b.children) 
		{
			drawBone(c, m);
		}
	}
	
}