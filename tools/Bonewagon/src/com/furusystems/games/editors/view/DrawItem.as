package com.furusystems.games.editors.view {
	import com.furusystems.games.editors.model.gts.Sequence;
	import com.furusystems.games.editors.model.gts.Tile;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class DrawItem {
		public var bone:Bone;
		public var zPos:Number = 0;
		public var vertices:Vector.<Number> = new Vector.<Number>();
		public var uvs:Vector.<Number> = new Vector.<Number>();
		public var indices:Vector.<int> = new Vector.<int>();
		
		public function DrawItem(bone:Bone, matrix:Matrix) {
			this.bone = bone;
			zPos = bone.z;
			var seq:Sequence = SharedModel.gts.getSequenceByName(bone.gtsSequence);
			var tex:BitmapData = SharedModel.gts.getTexture();
			var frame:Tile = seq.tiles[bone.gtsSequenceFrame];
			var w:Number = frame.width / 2;
			var h:Number = frame.height / 2;
			
			var tl:Point = new Point(-w, -h);
			var tr:Point = new Point(w, -h);
			var br:Point = new Point(w, h);
			var bl:Point = new Point(-w, h);
			
			tl = matrix.transformPoint(tl);
			tr = matrix.transformPoint(tr);
			bl = matrix.transformPoint(bl);
			br = matrix.transformPoint(br);
			
			vertices.push(tl.x, tl.y);
			vertices.push(tr.x, tr.y);
			vertices.push(br.x, br.y);
			vertices.push(bl.x, bl.y);
			uvs.push(frame.x / tex.width, frame.y / tex.height);
			uvs.push((frame.x + frame.width) / tex.width, frame.y / tex.height);
			uvs.push((frame.x + frame.width) / tex.width, (frame.y + frame.height) / tex.height);
			uvs.push(frame.x / tex.width, (frame.y + frame.height) / tex.height);
			indices.push(0, 1, 2, 0, 2, 3);
		}
	
	}

}