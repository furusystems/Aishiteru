package com.furusystems.games.rendering.animation.characters;
import com.furusystems.games.rendering.animation.gts.GTSSequence;
import com.furusystems.games.rendering.animation.gts.GTSSheet;
import com.furusystems.games.rendering.animation.gts.GTSTileMetrics;
import com.furusystems.games.rendering.animation.ISpriteSequence;
import com.furusystems.games.rendering.Camera;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.Vector;
using com.furusystems.games.rendering.utils.PointUtils;
/**
 * ...
 * @author Andreas Rønning
 */
class DrawItem
{
	public var joint:Joint;
	public var zPos:Float = 0;
	public var vertices:Vector<Float>;
	public var uvs:Vector<Float>;
	public var gts:GTSSheet;
	private static var utilMatrix:Matrix = new Matrix();
	var tl:Point;
	var tr:Point;
	var br:Point;
	var bl:Point;
	var pn:Point;
	var pn2:Point;
	public function new(joint:Joint, gts:GTSSheet) 
	{
		this.joint = joint;
		vertices = new Vector<Float>();
		uvs = new Vector<Float>();
		tl = new Point();
		tr = new Point();
		br = new Point();
		bl = new Point();
		pn = new Point();
		pn2 = new Point();
		zPos = joint.z;
		this.gts = gts;
	}
	public function update(cameraOffsetX:Float = 0, cameraOffsetY:Float = 0):Void {
		if (joint.sequence == "n/a") return;
		zPos = joint.z;
		var seq:GTSSequence = cast gts.getSequenceByName(joint.sequence);
		var tex:BitmapData = gts.texture;
		var frameMetrics:GTSTileMetrics = seq.getTileMetrics(joint.frame);
		var w:Float = frameMetrics.bounds.width * .5;
		var h:Float = frameMetrics.bounds.height * .5;
		
		pn2.x = w - (frameMetrics.offset.x + joint.owner.localOffset.x);
		pn2.y = h - (frameMetrics.offset.y + joint.owner.localOffset.y);
		
		tl.setTo( -w, -h);
		tr.setTo( w, -h);
		br.setTo( w, h);
		bl.setTo( -w, h);
		
		utilMatrix.identity();
		utilMatrix.translate(pn2.x, pn2.y);
		utilMatrix.concat(joint.matrix);
		utilMatrix.translate(-cameraOffsetX, -cameraOffsetY);
		
		utilMatrix.transformPointInPlace(tl);
		utilMatrix.transformPointInPlace(tr);
		utilMatrix.transformPointInPlace(bl);
		utilMatrix.transformPointInPlace(br);
		
		vertices[0] = tl.x;
		vertices[1] = tl.y;
		vertices[2] = tr.x;
		vertices[3] = tr.y;
		vertices[4] = br.x;
		vertices[5] = br.y;
		vertices[6] = bl.x;
		vertices[7] = bl.y;
		
		uvs[0] = (frameMetrics.bounds.x / tex.width);
		uvs[1] = (frameMetrics.bounds.y / tex.height);
		uvs[2] = ((frameMetrics.bounds.x + frameMetrics.bounds.width) / tex.width);
		uvs[3] = (frameMetrics.bounds.y / tex.height);
		uvs[4] = ((frameMetrics.bounds.x + frameMetrics.bounds.width) / tex.width);
		uvs[5] = ((frameMetrics.bounds.y + frameMetrics.bounds.height) / tex.height);
		uvs[6] = (frameMetrics.bounds.x / tex.width);
		uvs[7] = ((frameMetrics.bounds.y + frameMetrics.bounds.height) / tex.height);
	}
	
}