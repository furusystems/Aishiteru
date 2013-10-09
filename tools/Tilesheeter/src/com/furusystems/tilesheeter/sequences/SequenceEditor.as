package com.furusystems.tilesheeter.sequences 
{
	import com.furusystems.tilesheeter.SharedData;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class SequenceEditor extends Sprite
	{
		private var sd:SharedData;
		private var scaleHandle:Sprite;
		private var sX:Number = 1;
		private var sY:Number = 1;
		private var tileRender:Shape = new Shape();
		private var previewRender:Shape = new Shape();
		private var mouseOffsetX:Number;
		private var mouseOffsetY:Number;
		private var tempRect:Rectangle;
		public function SequenceEditor(sd:SharedData) 
		{
			this.sd = sd;
			visible = false;
			sd.changed.add(onModelChanged);
			sd.modeChanged.add(onModeChanged);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addChild(tileRender);
			addChild(previewRender);
		}
		
		private function onModelChanged():void 
		{
			if (!visible) return;
			drawTiles();
		}
		
		private function drawTiles():void 
		{
			tileRender.graphics.clear();
			var color:uint;
			for each(var s:Sequence in sd.sequences) {
				if (s == sd.currentSequence) {
					color = 0;
				}else {
					color = s.color;
				}
				for each(var t:Tile in s.tiles) {
					tileRender.graphics.lineStyle(0, color);
					tileRender.graphics.drawRect(t.x, t.y, t.width, t.height);
					tileRender.graphics.lineStyle();
					if (t == sd.currentTile) {
						tileRender.graphics.beginFill(0xFF0000, 0.6);
						tileRender.graphics.drawCircle(t.x+t.center.x, t.y+t.center.y, 2);
						tileRender.graphics.endFill();
					}
				}
			}
		}
		
		private function onModeChanged():void 
		{
			visible = sd.interactionMode == "sequence";
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		}
		
		private function onMouseDown(e:MouseEvent):void 
		{
			if (sd.interactionMode != "sequence") return;
			if (stage.mouseX < 200) return;
			if (!parent.parent.getRect(stage).containsPoint(new Point(stage.mouseX, stage.mouseY))) return;
			if (sd.sequences.length == 0) return;
			var mp:Point = new Point(mouseX, mouseY);
			var t:Tile;
			sd.currentTile = null;
			for each(var s:Sequence in sd.sequences) {
				for each(t in s.tiles) {
					if (t.containsPoint(mp)) {
						sd.setCurrentTile(t);
						break;
					}
				}
			}
			if (sd.currentTile != null) {
				t = sd.currentTile;
				mouseOffsetX = parent.mouseX - t.x;
				mouseOffsetY = parent.mouseY - t.y;
				stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			}else {
				beginRect(mouseX,mouseY);
			}
		}
		
		private function beginRect(mouseX:Number, mouseY:Number):void 
		{
			
			tempRect = new Rectangle(mouseX, mouseY);
			if (sd.gridEnabled) {
				var cellWidth:Number = sd.textureBounds.width / sd.gridColumns;
				var cellHeight:Number = sd.textureBounds.height / sd.gridRows;
				tempRect.x = Math.round(tempRect.x / cellWidth) * cellWidth;
				tempRect.y = Math.round(tempRect.y / cellHeight) * cellHeight;
			}
			stage.addEventListener(MouseEvent.MOUSE_MOVE, editRect);
			stage.addEventListener(MouseEvent.MOUSE_UP, saveRect);
			drawPreview();
		}
		
		private function saveRect(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, editRect);
			stage.removeEventListener(MouseEvent.MOUSE_UP, saveRect);
			
			if (tempRect.width < 0) {
				tempRect.x -= -tempRect.width;
				tempRect.width = -tempRect.width;
			}
			if (tempRect.height < 0) {
				tempRect.y -= -tempRect.height;
				tempRect.height = -tempRect.height;
			}
			previewRender.graphics.clear();
			if (e.shiftKey) {
				try{
					detectBlobs(tempRect);
				}catch (e:Error) {
					
				}
			}else{
				if (tempRect.width <= 5 && tempRect.height <= 5) return;
				sd.currentSequence.addTile(tempRect);
				sd.setCurrentTile(sd.currentSequence.tiles[sd.currentSequence.tiles.length - 1]);
			}
		}
		
		private function detectBlobs(area:Rectangle):void 
		{
			var offsetX:Number = area.x;
			var offsetY:Number = area.y;
			var tx:BitmapData = new BitmapData(area.width, area.height, true, 0xFF0000FF);
			var startTime:int = getTimer();
			tx.lock();
			trace("beginning blob detection");
			tx.threshold(sd.getTexture(), area, new Point(), ">", 0x00000000, 0xFF000000, 0xFF000000, false);
			
			var finished:Boolean = false;
			var blobs:Vector.<Rectangle> = new Vector.<Rectangle>();
			while (!finished) {
				if (getTimer() - startTime > 2000) {
					throw new Error("Algorithm failed");
				}
				var black:Rectangle = tx.getColorBoundsRect(0x00FFFFFF, 0, true);
				if (black.width == 0 && black.height == 0) {
					trace("Done");
					break;
				}
				var y:int = black.y;
				while (y < black.y+black.height) {
					if (getTimer() - startTime > 2000) {
						throw new Error("Algorithm failed");
					}
					if (tx.getPixel32(black.x + 1, y) == 0xFF000000) {
						tx.floodFill(black.x + 1, y, 0xFFFF0000);
						blobs.push(tx.getColorBoundsRect(0xFFFFFFFF, 0xFFFF0000, true));
						tx.floodFill(black.x + 1, y, 0xFF0000FF);
						break;
					}
					y++;
				}
			}
			tx.unlock();
			blobs.sort(sortBlobs); 
			for (var i:int = 0; i < blobs.length; i++) 
			{
				blobs[i].x += offsetX;
				blobs[i].y += offsetY;
				sd.currentSequence.addTile(blobs[i]);
			}
			sd.setCurrentTile(sd.currentSequence.tiles[sd.currentSequence.tiles.length - 1]);
			//addChild(new Bitmap(tx));
			
		}
		private function sortBlobs(a:Rectangle, b:Rectangle):int {
			if (a.x < b.x) return -1;
			if (a.x > b.x) return 1;
			else return 0;
		}
		
		private function editRect(e:MouseEvent):void 
		{
			tempRect.width = mouseX - tempRect.x;
			tempRect.height = mouseY - tempRect.y;
			if (sd.gridEnabled) {
				var cellWidth:Number = sd.textureBounds.width / sd.gridColumns;
				var cellHeight:Number = sd.textureBounds.height / sd.gridRows;
				tempRect.width = Math.round(tempRect.width / cellWidth) * cellWidth;
				tempRect.height = Math.round(tempRect.height / cellHeight) * cellHeight;
			}
			drawPreview();
		}
		
		private function drawPreview():void 
		{
			previewRender.graphics.clear();
			previewRender.graphics.lineStyle(0, 0,0.5);
			previewRender.graphics.drawRect(tempRect.x, tempRect.y, tempRect.width, tempRect.height);
		}
		
		private function onMouseUp(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		private function onMouseMove(e:MouseEvent):void 
		{
			sd.currentTile.x = parent.mouseX - mouseOffsetX;
			sd.currentTile.y = parent.mouseY - mouseOffsetY;
			if (sd.gridEnabled) {
				var cellWidth:Number = sd.textureBounds.width / sd.gridColumns;
				var cellHeight:Number = sd.textureBounds.height / sd.gridRows;
				sd.currentTile.x = Math.round(sd.currentTile.x / cellWidth) * cellWidth;
				sd.currentTile.y = Math.round(sd.currentTile.y / cellHeight) * cellHeight;
			}
			drawTiles();
		}
		
	}

}