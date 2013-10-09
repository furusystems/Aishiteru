package com.furusystems.games.rendering;
import com.furusystems.games.gameobject.GameObject;
import com.furusystems.games.gameobject.IResettable;
import com.furusystems.games.rendering.animation.gts.GTSSequence;
import com.furusystems.games.rendering.animation.gts.GTSSheet;
import com.furusystems.games.vos.UpdateInfo;
import com.furusystems.utils.ClassFactory;
import flash.display.Graphics;

	/**
	 * Stepper that contains a group of gameentities that all use the same spritesheet pointer
	 * @author Andreas Rønning
	 */
	class Batcher extends GameObject implements IResettable
	{
		private var _objectPool:Array<GameObject>;
		public var classType:String;
		public var spriteSheetInfo:Array<Int>;
		private var isGTS:Bool;
		private var gtsSheet:GTSSheet;
		private var defaultSequence:String;
		private var tintEnabled:Bool;
		private var poolIndex:Int;
		public var customInstructions:Bool;
		public var grouped:Bool;
		public function new(maxCapacity:Int, type:String, ?gts:GTSSheet, ?name:String, ?defaultSequence:String)
		{
			if (name != null) { super(name); } else { super(); }
			customInstructions = false;
			children = new Array<GameObject>();
			classType = type;
			this.defaultSequence = (defaultSequence == null) ? "none" : defaultSequence;
			setGts(gts);
			poolIndex = 0;
			_objectPool = new Array<GameObject>();
			trace("Creating " + maxCapacity + " instances of " + classType);
			allocate(maxCapacity);
		}
		public function additive():Void {
			#if cpp
			renderinfo.flags |= flash.display.Graphics.TILE_BLEND_ADD;
			#end
		}
		private function allocate(num:Int):Void 
		{
			for (i in 0...num) {
				_objectPool.push(fabricate());
			}
		}
		
		private function setGts(g:GTSSheet):Void {
			gtsSheet = g;
			renderinfo.tilesheet = gtsSheet.tilesheet;
		}
		override public function reset():Void {
			removeChildren();
		}
		private function fabricate():GameObject
		{
			var out:GameObject = ClassFactory.create(classType);
			out.onBatcherSetup(this, gtsSheet, defaultSequence);
			return out;
		}
		public function drawHitInfo(g:Graphics,camera:Camera):Void {
			for (o in children) {
				g.drawRect(o.transform.x - camera.derivedX - o.transform.hitbox.halfWidth, o.transform.y - camera.derivedY - o.transform.hitbox.halfHeight, o.transform.hitbox.width, o.transform.hitbox.height);
			}
		}
		public function emit(x:Float, y:Float, ?scale:Float = 1, ?rotation:Float = 0, ?timeOffset:Int = 0, ?initAge:Float = 0, ?initVelocityX:Float, ?initVelocityY:Float, ?extraInfo:Dynamic = null):GameObject {
			if (poolIndex >= _objectPool.length) {
				poolIndex = 0;
			}
			var b:GameObject = _objectPool[poolIndex];
			
			b.transform.x = x;
			b.transform.y = y;
			b.transform.rotationRad = rotation;
			
			if (extraInfo != null) b.handleExtraInfo(extraInfo);
			
			if (initVelocityY != null) {
				b.transform.vy = initVelocityY;
			}
			if (initVelocityX != null) {
				b.transform.vx = initVelocityX;
			}
			
			b.age = initAge+timeOffset;
			b.enabled = true;
			b.toBeRemoved = false;
			b.transform.scale = scale;
			
			if (b.objectID == -1) {
				addChild(b);
			}
			b.objectID = poolIndex;
			poolIndex++;
			
			return b;
		}
		override public function updateChildren(info:UpdateInfo):Void 
		{
			if (children == null) return;
			for (n in children) {
				if (n.enabled) {
					n.update(info);
					n.postUpdate(info);
				}
				if (n.toBeRemoved) {
					info.removeList.add(n);
					n.objectID = -1;
				}
			}
		}
		override public function render(info:UpdateInfo):Void 
		{
			#if batchers
			if (grouped) return;
			if (children == null) return;
			if(!customInstructions){
				renderinfo.beginGroup();
				var target:Array<Float> = renderinfo.tileinfo;
				for (n in children) {
					if (!(n.toBeRemoved || n.age <= 0 || !n.enabled || !n.visible)) {
						n.updateRenderInfo(info, true);
						target[renderinfo.tileinfoIndex] = n.renderinfo.tileinfo[0];
						target[renderinfo.tileinfoIndex+1] = n.renderinfo.tileinfo[1];
						target[renderinfo.tileinfoIndex+2] = n.renderinfo.tileinfo[2];
						target[renderinfo.tileinfoIndex+3] = n.renderinfo.tileinfo[3];
						target[renderinfo.tileinfoIndex+4] = n.renderinfo.tileinfo[4];
						renderinfo.tileinfoIndex += 5;
						if (n.hasChildren) {
							renderinfo.tileinfoIndex = renderGroup(renderinfo.tileinfoIndex, renderinfo.tileinfo, n.children, info);
						}
					}
				}
				renderinfo.endGroup();
				info.addToRenderList(renderinfo);
			}
			#end
		}
		private function renderGroup(idx:Int, target:Array<Float>, group:Array<GameObject>,info:UpdateInfo):Int {
			for (i in 0...group.length) {
				var n:GameObject = group[i];
				n.updateRenderInfo(info);
				target[idx] = n.renderinfo.tileinfo[0];
				target[idx+1] = n.renderinfo.tileinfo[1];
				target[idx+2] = n.renderinfo.tileinfo[2];
				target[idx+3] = n.renderinfo.tileinfo[3];
				target[idx+4] = n.renderinfo.tileinfo[4];
				idx += 5;
			}
			return idx;
		}
		
		public function countEnabledChildren():Int
		{
			if (children == null) return 0;
			var count:Int = 0;
			for (c in children) { if (c.enabled) count++; }
			return count;
		}
		
		
		override public function dispose():Void
		{
			_objectPool = null;
			super.dispose();
		}
	}