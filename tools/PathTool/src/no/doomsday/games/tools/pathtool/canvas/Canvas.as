package no.doomsday.games.tools.pathtool.canvas 
{
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import no.doomsday.games.tools.pathtool.data.SplinePoint;
	import no.doomsday.games.tools.pathtool.IResizable;
	import no.doomsday.games.tools.pathtool.preview.Preview;
	import no.doomsday.games.tools.pathtool.SharedData;
	import no.doomsday.games.tools.pathtool.timeline.Timeline;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Canvas extends Sprite implements IResizable
	{
		private var gameRectView:Shape;
		private var cursorView:Shape;
		private var splineView:Shape;
		
		private var _model:SharedData;
		private var _viewDirty:Boolean = false;
		private var dragging:Boolean;
		private var currentPoint:SplinePoint;
		private var previousNode:SplinePoint;
		private var pointRadius:Number = 8;
		private var draggingExisting:Boolean;
		private var lastClickedPoint:SplinePoint = null;
		
		public var preview:Shape = new Shape();
		
		
		public function Canvas(model:SharedData) 
		{
			_model = model;
			_model.changed.add(onModelChanged);
			_model.splineLoaded.add(onSplineLoaded);
			gameRectView = new Shape();
			cursorView = new Shape();
			splineView = new Shape();
			addChild(gameRectView);
			addChild(splineView);
			addChild(preview);
			addChild(cursorView);
			addEventListener(Event.ENTER_FRAME, updateView);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		}
		
		private function onSplineLoaded():void 
		{
			forcePrevNode();
		}
		
		private function onMouseDown(e:MouseEvent):void 
		{
			if (!getRect(stage).containsPoint(new Point(stage.mouseX, stage.mouseY))) return;
			this.focusRect = false;
			stage.focus = this;
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragPoint);
			
			_model.addUndoLevel();
			//determine if we're clicking any of the current spline points, if not, create a new one.
			var mousePoint1:Point = getPoint(gameRectView.mouseX/_model.gameBounds.width, gameRectView.mouseY/_model.gameBounds.height);
			var mousePoint2:Point = new Point(gameRectView.mouseX/_model.gameBounds.width, gameRectView.mouseY/_model.gameBounds.height);
			var cP:SplinePoint = null;
			if (_model.currentSpline != null) {
				var p:SplinePoint = _model.currentSpline;
				if (clickedPoint(mousePoint1, p)||clickedPoint(mousePoint2, p)) {
					cP = p;
				}else{
					while (p.hasNext()) 
					{
						p = p.next;
						if (clickedPoint(mousePoint1, p)||clickedPoint(mousePoint2, p)) {
							cP = p;
							break;
						}
					}
				}
			}
			_model.deselectAll();
			if (cP!=null) {
				currentPoint = lastClickedPoint = cP;
				draggingExisting = true;
				cP.selected = true;
			}else {
				currentPoint = lastClickedPoint = new SplinePoint(getPoint(gameRectView.mouseX, gameRectView.mouseY), _model.nextTime());
				draggingExisting = false;
				currentPoint.selected = true;
			}
			
			dragging = true;
			onMouseMove(e);
		}
		
		private function clickedPoint(mp:Point, p:SplinePoint):Boolean {
			var ratio:Number = _model.gameBounds.width / _model.gameBounds.height;
			var ssp:Point = new Point(mp.x * _model.gameBounds.width, mp.y * _model.gameBounds.height);
			var sp:Point = new Point(p.x * _model.gameBounds.width, p.y * _model.gameBounds.height);
			var rect:Rectangle = new Rectangle(sp.x-pointRadius, sp.y-pointRadius, pointRadius * 2, pointRadius * 2);
			return rect.containsPoint(ssp);
		}
		
		private function dragPoint(e:MouseEvent):void 
		{
			currentPoint.updateFromPoint(getPoint(gameRectView.mouseX, gameRectView.mouseY));
			if (draggingExisting) redrawSpline();
			_model.setDirty();
		}
		
		private function onMouseUp(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragPoint);
			dragging = false;
			if (!draggingExisting) addToSpline(currentPoint);
			else redrawSpline();
			draggingExisting = false;
			currentPoint = null; 
			onMouseMove(e);
		}
		
		private function addToSpline(currentPoint:SplinePoint):void 
		{
			if (_model.currentSpline != null) {
				previousNode = previousNode.append(currentPoint);
			}else {
				_model.currentSpline = previousNode = currentPoint;
			}
			redrawSpline();
			_model.setDirty();
		}
		
		private function forcePrevNode():void 
		{
			if(_model.currentSpline!=null)
				previousNode = _model.currentSpline.getHead();
		}
		
		private function redrawSpline():void 
		{
			var g:Graphics = splineView.graphics;
			g.clear();
			//fills
			var p:SplinePoint;
			if (_model.currentSpline != null) {
				g.beginFill(0x00FF00);
				p = _model.currentSpline;
				g.drawCircle(p.x*_model.gameBounds.width+gameRectView.x, p.y*_model.gameBounds.height+gameRectView.y, pointRadius);
				while (p.hasNext()) {
					p = p.next;
					if (p.hasNext()) {
						g.beginFill(0xFFFF00,1);
					}else {
						g.beginFill(0x00FFFF, 1);
					}
					g.drawCircle(p.x*_model.gameBounds.width+gameRectView.x, p.y*_model.gameBounds.height+gameRectView.y, pointRadius);
				}
				g.endFill();
			}
			if (lastClickedPoint != null) {
				g.lineStyle(1, 0);
				p = lastClickedPoint;
				g.drawCircle(p.x*_model.gameBounds.width+gameRectView.x, p.y*_model.gameBounds.height+gameRectView.y, pointRadius);
			}else {
				if(previousNode!=null){
					g.lineStyle(1, 0);
					p = previousNode;
					g.drawCircle(p.x * _model.gameBounds.width + gameRectView.x, p.y * _model.gameBounds.height + gameRectView.y, pointRadius);
				}
			}
			//lines
			if (_model.currentSpline != null) {
				g.lineStyle(0, 0);
				p = _model.currentSpline;
				g.moveTo(p.x*_model.gameBounds.width+gameRectView.x, p.y*_model.gameBounds.height+gameRectView.y);
				while (p.hasNext()) {
					p = p.next;
					g.lineTo(p.x*_model.gameBounds.width+gameRectView.x, p.y*_model.gameBounds.height+gameRectView.y);
				}
			}
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == Keyboard.BACKSPACE && stage.focus == this) {
				if (lastClickedPoint != null&&lastClickedPoint!=previousNode) {
					deletePoint(lastClickedPoint);
				}else {
					deletePrevious();
				}
				lastClickedPoint = null;
				redrawSpline();
			}
		}
		
		private function deletePoint(cp:SplinePoint):void 
		{
			_model.addUndoLevel();
			if (cp == _model.currentSpline&&cp.next) {
				_model.currentSpline = cp.next;
				_model.currentSpline.previous = null;
			}else{
				if (cp.previous) {
					if (cp.next) {
						cp.previous.next = cp.next;
					}
				}
				if (cp.next) {
					if (cp.previous) {
						cp.next.previous = cp.previous;
						cp.previous.next = cp.next;
					}
				}
				cp.next = cp.previous = null;
			}
			lastClickedPoint = null;
			_model.setDirty();
		}
		
		private function deletePrevious():void 
		{
			_model.addUndoLevel();
			if (previousNode == _model.currentSpline) {
				previousNode = _model.currentSpline = null;
			}else{
				previousNode = previousNode.previous;
				previousNode.next = null;
			}
			_model.setDirty();
		}
		
		private function onMouseMove(e:MouseEvent):void 
		{
			cursorView.graphics.clear();
			if (dragging) {
				cursorView.graphics.beginFill(0xFF0000, 0.5);
			}
			if (!getRect(stage).containsPoint(new Point(stage.mouseX, stage.mouseY))) return;
			var mp:Point = getPoint(gameRectView.mouseX, gameRectView.mouseY);
			cursorView.graphics.lineStyle(0, 0);
			cursorView.graphics.drawCircle(mp.x*_model.gameBounds.width+gameRectView.x, mp.y*_model.gameBounds.height+gameRectView.y, pointRadius);
			e.updateAfterEvent();
		}
		
		private function onModelChanged():void 
		{
			_viewDirty = true;
		}
		
		private function updateView(e:Event):void 
		{
			if (_viewDirty) {
				redraw();
				_viewDirty = false;
			}
			preview.graphics.clear();
			if (_model.lastPathGenerated == null) return;
			var pt:Point = _model.lastPathGenerated.getPoint(Timeline.currentTime);
			preview.graphics.beginFill(0x0000FF);
			preview.graphics.drawCircle(pt.x*_model.gameBounds.width, pt.y*_model.gameBounds.height, 5);
			preview.graphics.endFill();
		}
		public function getPoint(x:Number, y:Number):Point {
			var p:Point = new Point(x, y);
			if (_model.gridEnabled) {
				//p.x -= gameRectView.x;
				//p.y -= gameRectView.y;
				var cellWidth:Number = _model.gameBounds.width / _model.gridColumns;
				var cellHeight:Number = _model.gameBounds.height / _model.gridRows;
				p.x = Math.round(p.x / cellWidth) * cellWidth;
				p.y = Math.round(p.y / cellHeight) * cellHeight;
				//p.x += gameRectView.x;
				//p.y += gameRectView.y;
			}
			p.x /= _model.gameBounds.width;
			p.y /= _model.gameBounds.height;
			return p;
		}
		private function redraw():void 
		{
			removeChild(gameRectView);
			
			graphics.clear();
			graphics.beginFill(0x808080);
			graphics.drawRect(0, 0, stage.stageWidth - x, stage.stageHeight);
			graphics.endFill();
			
			gameRectView.graphics.clear();
			gameRectView.graphics.beginFill(0xFFFFFF);
			gameRectView.graphics.drawRect(0, 0, _model.gameBounds.width, _model.gameBounds.height);
			gameRectView.graphics.endFill();
			gameRectView.x = preview.x = int(width / 2 - gameRectView.width / 2);
			gameRectView.y = preview.y = int(height / 2 - gameRectView.height / 2);
			
			if (_model.gridEnabled) {
				var cellWidth:Number = _model.gameBounds.width / _model.gridColumns;
				var cellHeight:Number = _model.gameBounds.height / _model.gridRows;
				var w:int = _model.gameBounds.width / cellWidth;
				var h:int = _model.gameBounds.height / cellHeight;
				gameRectView.graphics.lineStyle(0, 0xbbbbbb);
				var i:int = w;
				while (i--) {
					gameRectView.graphics.moveTo(i*cellWidth, 0);
					gameRectView.graphics.lineTo(i*cellWidth, _model.gameBounds.height);
				}
				i = h;
				while (i--) {
					gameRectView.graphics.moveTo(0, i * cellHeight);
					gameRectView.graphics.lineTo(_model.gameBounds.width, i * cellHeight);
				}
			}
			
			addChildAt(gameRectView, 0);
			redrawSpline();
		}
		
		/* INTERFACE no.doomsday.games.tools.pathtool.IResizable */
		
		public function resize():void 
		{
			_viewDirty = true;
		}
		
	}

}