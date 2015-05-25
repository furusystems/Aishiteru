package bonewagon.view;
import bonewagon.model.gts.Sequence;
import bonewagon.model.gts.Tile;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;

using com.furusystems.games.extensions.ArrayUtils;

/**
 * ...
 * @author Andreas Rønning
 */
class DrawItem {
	public var bone:Bone;
	public var zPos:Float = 0;
	public var vertices = new Array<Float>();
	public var uvs = new Array<Float>();
	public var indices = new Array<Int>();
	
	public function new(bone:Bone, matrix:Matrix) {
		this.bone = bone;
		zPos = bone.z;
		var seq:Sequence = SharedModel.gts.getSequenceByName(bone.gtsSequence);
		var tex:BitmapData = SharedModel.gts.getTexture();
		var frame:Tile = seq.tiles[bone.gtsSequenceFrame];
		var w = frame.width / 2;
		var h = frame.height / 2;
		
		var tl = new Point(-w, -h);
		var tr = new Point(w, -h);
		var br = new Point(w, h);
		var bl = new Point(-w, h);
		
		tl = matrix.transformPoint(tl);
		tr = matrix.transformPoint(tr);
		bl = matrix.transformPoint(bl);
		br = matrix.transformPoint(br);
		
		vertices.pushTwo(tl.x, tl.y);
		vertices.pushTwo(tr.x, tr.y);
		vertices.pushTwo(br.x, br.y);
		vertices.pushTwo(bl.x, bl.y);
		uvs.pushTwo(frame.x / tex.width, frame.y / tex.height);
		uvs.pushTwo((frame.x + frame.width) / tex.width, frame.y / tex.height);
		uvs.pushTwo((frame.x + frame.width) / tex.width, (frame.y + frame.height) / tex.height);
		uvs.pushTwo(frame.x / tex.width, (frame.y + frame.height) / tex.height);
		indices = indices.concat([0, 1, 2, 0, 2, 3]);
	}

}

