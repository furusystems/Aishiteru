package com.furusystems.games.rendering;
import com.furusystems.games.gameobject.GameObject;
import com.furusystems.games.gameobject.IResettable;
import com.furusystems.games.rendering.animation.gts.GTSManager;
import com.furusystems.games.rendering.animation.gts.GTSSheet;
import com.furusystems.games.vos.UpdateInfo;
import flash.display.Graphics;


/**
 * ...
 * @author Andreas Rønning
 */

class BatcherGroup extends GameObject implements IResettable
{
	public var gts:GTSSheet;
	public var batchers:Array<Batcher>;
	public function new(mgr:GTSManager, gtsPath:String) 
	{
		super();
		batchers = new Array<Batcher>();
		children = new Array<GameObject>();
		gts = mgr.get(gtsPath);
		renderinfo.tilesheet = gts.tilesheet;
	}
	public function createBatcher(cap:Int, type:String, ?name:String, ?defaultSequence:String):Batcher {
		trace("Creating batcher for type: " + type);
		return addBatcher(new Batcher(cap, type, gts, name, defaultSequence));
	}
	public function additive():Void {
		// renderinfo.flags |= flash.display.Graphics.TILE_BLEND_ADD;
	}
	private function addBatcher(b:Batcher):Batcher {
		addChild(b);
		b.grouped = true;
		batchers.push(b);
		return b;
	}
	public function removeBatcher(b:Batcher):Void {
		removeChild(b);
		b.grouped = false;
		batchers.remove(b);
	}
	override public function reset():Void {
		for (b in batchers) {
			b.reset();
		}
	}
	public function removeBatcherByType(type:String):Void {
		for (b in batchers) {
			if (b.classType == type) {
				batchers.remove(b);
				removeChild(b);
				return;
			}
		}
	}
	public function getBatcherByType(type:String):Batcher {
		for (b in batchers) {
			if (b.classType == type) {
				return b;
			}
		}
		return null;
	}
	
	public function countEnabledChildrenInBatchers():Int
	{
		var count:Int = 0;
		for (b in batchers) { count += b.countEnabledChildren(); }
		return count;
	}
	override public function renderChildren(info:UpdateInfo):Void 
	{
	}
	public function drawHitInfo(g:Graphics,camera:Camera):Void {
		if (children == null) return;
		for (b in batchers) {
			b.drawHitInfo(g,camera);
		}
	}
	override public function render(info:UpdateInfo):Void 
	{
		#if batchers
		renderinfo.beginGroup();
		if (children == null) return;
		for (i in 0...batchers.length) { //ensure sequential render here... at least
			renderinfo.tileinfoIndex = gatherBatcher(renderinfo.tileinfoIndex, batchers[i], renderinfo.tileinfo, info);
		}
		renderinfo.endGroup();
		info.addToRenderList(renderinfo);
		#end
	}
	private function gatherBatcher(index:Int, b:Batcher,target:Array<Float>,info:UpdateInfo):Int {
		var out:Array<Float> = target;
		if (b.children != null) {
			for (n in b.children) {
				if (!(n.toBeRemoved || n.age < 0 || !n.enabled || !n.visible))
				{
					index = setInfo(index, n, target, info);
					if (n.hasChildren) {
						index = gatherChildren(index, n, target, info);
					}
				}
			}
		}
		return index;
	}
	private inline function setInfo(index:Int, g:GameObject, target:Array<Float>, info:UpdateInfo):Int {
		g.updateRenderInfo(info, true);
		target[index] = g.renderinfo.tileinfo[0];
		target[index + 1] = g.renderinfo.tileinfo[1];
		target[index + 2] = g.renderinfo.tileinfo[2];
		target[index + 3] = g.renderinfo.tileinfo[3];
		target[index + 4] = g.renderinfo.tileinfo[4];
		index += 5;
		return index;
	}
	private function gatherChildren(index:Int, g:GameObject, target:Array<Float>, info:UpdateInfo):Int  {
		var out:Array<Float> = target;
		for (c in g.children) {
			index = setInfo(index, c, target, info);
			if (c.hasChildren) {
				index = gatherChildren(index, g, target, info);
			}
		}
		return index;
	}
	
}