package com.furusystems.games.rendering;
import com.furusystems.games.vos.RenderInfo;
import flash.display.Graphics;

/**
 * A DrawInstruction represents a single draw call, implementation specific
 * @author Andreas Rønning
 */

interface DrawInstruction 
{
	function draw(g:Graphics,info:RenderInfo, camera:Camera):Void;
}