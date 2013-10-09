package com.furusystems.games.rendering;
import com.furusystems.games.GameBase2D;
#if customrenderer
import com.furusystems.games.rendering.opengl.OpenGLRenderer;
#end
import com.furusystems.games.vos.RenderInfo;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.errors.Error;
import flash.Lib;
import openfl.display.OpenGLView;
import openfl.display.Tilesheet;


/**
 * Basic renderer; Draws a stack of DrawInstructions to a Graphics object
 * @author Andreas Rønning
 */

class BatchRenderer extends Sprite
{
	public var accumulator:List<RenderInfo>;
	public var game:GameBase2D;
	#if customrenderer
	public var ogl:OpenGLRenderer;
	#end
	public function new(game:GameBase2D) 
	{
		super();
		this.game = game;
		accumulator = new List<RenderInfo>();
		#if customrenderer
		ogl = new OpenGLRenderer();
		addChild(ogl);
		#end
	}
	
	#if flash
	private function draw(r:RenderInfo, camera:Camera):Void 
	{
		try {
			if (r.customInstruction == null) r.tilesheet.drawTiles(graphics, r.tileinfo, game.config.tileSmoothing||r.smoothing, r.flags);
			else r.customInstruction.draw(graphics, r, camera);
		}catch (e:Error) {
			throw new Error("Rendering error for object: " + r.go);
		}
		
	}
	#else
	private function draw(r:RenderInfo, camera:Camera):Void 
	{
		#if debug
		try {
		#end
			if (r.customInstruction == null) graphics.drawTiles(r.tilesheet, r.tileinfo, game.config.tileSmoothing||r.smoothing, r.flags);
			else r.customInstruction.draw(graphics, r, camera);
		#if debug
		}catch (e:Error) {
			throw new Error("Rendering error for object: " + r.go);
		}
		#end
		
	}
	#end
	
	public function clearLayers():Void {
		clearAccumulator();
		graphics.clear();
	}
	public function drawBatch(renderinfos:List<RenderInfo>, camera:Camera):Void {
		for (r in renderinfos) {
			if (!r.go.visible) continue;
			#if customrenderer
			ogl.accumulate(r, camera);
			#else
			draw(r, camera);
			#end
		}
	}	
	public function clearAccumulator():Void 
	{
		accumulator = new List<RenderInfo>();
	}
	
	public function debugAccumulator():Void 
	{
		trace("Current render list: ");
		for (i in accumulator) {
			trace(i.tileinfo);
		}
	}
	
}