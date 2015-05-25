package bonewagon.view;
import bonewagon.model.gts.Sequence;
import bonewagon.model.gts.Tile;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.Vector;

using com.furusystems.games.extensions.ArrayUtils;

/**
 * ...
 * @author Andreas Rønning
 */
class TileRenderer extends Sprite
{
	
	var drawStack:Array<DrawItem>;
	var indexOffset:Int;
	var lastDraw:Int = -1;
	public function new() 
	{
		super();
		SharedModel.onChanged.add(onModelChanged);
	}
	
	function onModelChanged(flags:Int, data:Dynamic) 
	{
		if (flags & SharedModel.ANIMATION != 0) redraw();
	}
	
	function redraw() 
	{
		if (lastDraw == SharedModel.currentFrame) return;
		lastDraw = SharedModel.currentFrame;
		indexOffset = 0;
		drawStack = new Array<DrawItem>();
		drawBone(SharedModel.skeleton, SharedModel.worldMatrix);
		drawStack.sort(sortZ);
		renderStack();
	}
	
	function sortZ(a:DrawItem, b:DrawItem):Int
	{
		if (a.zPos < b.zPos) return -1;
		if (a.zPos > b.zPos) return 1;
		return 0;
	}
	
	function renderStack() 
	{
		if (SharedModel.gts == null) return;
		var verts = new Array<Float>();
		var indices = new Array<Int>();
		var uvs = new Array<Float>();
		indexOffset = 0;
		for (item in drawStack) 
		{
			verts = verts.concat(item.vertices);
			indices = indices.concat([0 + indexOffset, 1 + indexOffset, 2 + indexOffset, 0 + indexOffset, 2 + indexOffset, 3 + indexOffset]);
			uvs = uvs.concat(item.uvs);
			indexOffset += 4;
		}
		graphics.clear();
		graphics.beginBitmapFill(SharedModel.gts.getTexture(), null, false, true);
		
		
		graphics.drawTriangles(verts.toVector(), indices.toVector(), uvs.toVector());
		graphics.endFill();
	}
	
	function drawBone(b:Bone, parentMatrix:Matrix = null) 
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
		for (c in b.children) 
		{
			drawBone(c, m);
		}
	}
	
}