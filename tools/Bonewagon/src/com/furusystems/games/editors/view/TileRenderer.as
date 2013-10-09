package com.furusystems.games.editors.view 
{
	import com.furusystems.games.editors.model.gts.Sequence;
	import com.furusystems.games.editors.model.gts.Tile;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class TileRenderer extends Sprite
	{
		
		private var drawStack:Vector.<DrawItem>;
		private var indexOffset:int;
		private var lastDraw:int = -1;
		public function TileRenderer() 
		{
			SharedModel.onChanged.add(onModelChanged);
		}
		
		private function onModelChanged(flags:int, data:Object):void 
		{
			if (flags & SharedModel.ANIMATION) redraw();
		}
		
		private function redraw():void 
		{
			if (lastDraw == SharedModel.currentFrame) return;
			lastDraw = SharedModel.currentFrame;
			indexOffset = 0;
			drawStack = new Vector.<DrawItem>();
			drawBone(SharedModel.skeleton, SharedModel.worldMatrix);
			drawStack.sort(sortZ);
			renderStack();
		}
		
		private function sortZ(a:DrawItem, b:DrawItem):int
		{
			if (a.zPos < b.zPos) return -1;
			if (a.zPos > b.zPos) return 1;
			return 0;
		}
		
		private function renderStack():void 
		{
			if (SharedModel.gts == null) return;
			var verts:Vector.<Number> = new Vector.<Number>();
			var indices:Vector.<int> = new Vector.<int>();
			var uvs:Vector.<Number> = new Vector.<Number>();
			indexOffset = 0;
			for (var i:int = 0; i < drawStack.length; i++) 
			{
				var item:DrawItem = drawStack[i];
				verts = verts.concat(item.vertices);
				indices.push(0 + indexOffset, 1 + indexOffset, 2 + indexOffset, 0 + indexOffset, 2 + indexOffset, 3 + indexOffset);
				uvs = uvs.concat(item.uvs);
				indexOffset += 4;
			}
			graphics.clear();
			graphics.beginBitmapFill(SharedModel.gts.getTexture(), null, false, true);
			graphics.drawTriangles(verts, indices, uvs);
			graphics.endFill();
		}
		
		private function drawBone(b:Bone, parentMatrix:Matrix = null):void 
		{
			var m:Matrix = b.getLocalMatrix();
			if (parentMatrix != null) {
				m.concat(parentMatrix);
			}
			if (SharedModel.gts != null && b.gtsSequence != "n/a") { 
				var local:Matrix = m.clone();
				var t:Matrix = new Matrix();
				var tile:Tile = SharedModel.gts.getSequenceByName(b.gtsSequence).tiles[b.gtsSequenceFrame];
				t.translate(tile.width * .5 - tile.center.x, tile.height * 0.5 - tile.center.y);
				t.translate(b.localOffset.x, b.localOffset.y);
				t.concat(m);
				var item:DrawItem = new DrawItem(b, t);
				drawStack.push(item);
			}
			for (var i:int = 0; i < b.children.length; i++) 
			{
				drawBone(b.children[i], m);
			}
		}
		
	}

}