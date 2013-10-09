package com.furusystems.tilesheeter.preview 
{
	import com.furusystems.tilesheeter.sequences.Sequence;
	import com.furusystems.tilesheeter.sequences.Tile;
	import com.furusystems.tilesheeter.SharedData;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Preview extends Sprite
	{
		private var matrix:Matrix;
		public var render:BitmapData = new BitmapData(128, 128, false);
		private var cliprect:Rectangle = new Rectangle();
		public var sd:SharedData;
		private var frameIndex:int;
		private var play:Boolean = false;
		private var display:Bitmap;
		private var overlayX:Shape;
		private var lastTime:int;
		private var time:Number = 0;
		private var hitboxRender:Shape;
		public function Preview(sd:SharedData) 
		{
			this.sd = sd;
			render.fillRect(render.rect, 0x00FF00);
			hitboxRender = new Shape();
			addChild(new Bitmap(render));
			overlayX = new Shape();
			addChild(overlayX);
			addChild(hitboxRender);
			overlayX.x = overlayX.y = hitboxRender.x = hitboxRender.y = 64;
			overlayX.graphics.lineStyle(0, 0);
			overlayX.graphics.moveTo(0, -4);
			overlayX.graphics.lineTo(0, 5);
			overlayX.graphics.moveTo(-4, 0);
			overlayX.graphics.lineTo(5, 0);
			matrix = new Matrix();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			lastTime = getTimer();
			frameIndex = 0;
		}
		
		private function onEnterFrame(e:Event):void 
		{
			if (!stage) return;
			if (sd.currentSequence == null) return;
			if (sd.currentSequence.tiles.length == 0) return;
			
			hitboxRender.graphics.clear();
			hitboxRender.graphics.lineStyle(0, 0xFF0000);
			hitboxRender.graphics.beginFill(0xFF0000, 0.2);
			//hitboxRender.scrollRect = new Rectangle( -32, -32, 64, 64);
			if(sd.currentSequence.hitAreaType!=Sequence.NONE){
				switch(sd.currentSequence.hitAreaType) {
					case Sequence.CIRCLE:
						if (sd.currentSequence.hitcircle != 0) hitboxRender.graphics.drawCircle(0, 0, sd.currentSequence.hitcircle);
						break;
					case Sequence.RECT:
						if (sd.currentSequence.hitbox.size.length != 0) hitboxRender.graphics.drawRect( -sd.currentSequence.hitbox.width / 2, -sd.currentSequence.hitbox.height / 2, sd.currentSequence.hitbox.width, sd.currentSequence.hitbox.height);
						break;
				}
			}
			if (play) {
				var delta:Number = (getTimer() - lastTime) / 1000;
				lastTime = getTimer();
				time += delta;
				
				if (time < 0) return;
				if (time > sd.currentSequence.tiles.length * 1/sd.currentSequence.frameRate || time < 0) { 
						var diff:Number = time-(sd.currentSequence.tiles.length * 1/sd.currentSequence.frameRate);
						time = diff;
				}else{
					frameIndex = Math.floor(time / (1 / sd.currentSequence.frameRate));
				}
				
				if (frameIndex >= sd.currentSequence.tiles.length) {
					frameIndex = 0;
				}
				setFrame(sd.currentSequence.tiles[frameIndex], sd.getTexture());
			}else {
				lastTime = getTimer();
				if (sd.currentTile == null) return;
				setFrame(sd.currentTile, sd.getTexture());
			}
		}
		
		public function togglePlay(e:Event):void {
			play = !play;
		}
		
		public function setFrame(tile:Tile, texture:BitmapData):void {
			render.fillRect(render.rect, 0x00FF00);
			matrix.identity();
			//matrix.translate(-tile.x, -tile.y);
			cliprect = tile.clone();
			
			render.copyPixels(texture, cliprect, new Point(64-tile.center.x,64-tile.center.y));
		}
		
		public function poke():void 
		{
			if (sd.currentSequence.tiles.length == 0) return;
			setFrame(sd.currentSequence.tiles[0], sd.getTexture());
		}
		
	}

}