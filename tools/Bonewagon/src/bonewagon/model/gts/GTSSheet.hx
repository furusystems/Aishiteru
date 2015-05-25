package bonewagon.model.gts;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import haxe.Json;

using com.furusystems.games.extensions.PNGTools;
/**
 * ...
 * @author Andreas Rønning
 */
class GTSSheet 
{		
	public var layers = new Array<BitmapLayer>();
	public var sequences = new Array<Sequence>();
	
	public var generatedTexture:BitmapData = null;
	public var textureBounds = new Rectangle();
	
	public var currentSequence:Sequence;
	public var currentTile:Tile;
	
	public function new() {
	}	
	
	public function addLayer(data:ByteArray,filename:String) 
	{
		trace("adding layer: " + filename);
		var l:BitmapLayer = new BitmapLayer(this, data, filename);
		layers.push(l);
	}
	
	
	public function parseDescriptor(json:String) 
	{
		//trace(json);
		clearSequences();
		var ob:Dynamic = Json.parse(json);
		if(ob.hasOwnProperty("resolution")){
			textureBounds.width = textureBounds.height = ob.resolution;
		}
		for (i in 0...ob.sequences.length) {
			var s = ob.sequences[i];
			addSequence(Sequence.fromObject(s));
		}
	}
	
	function clearSequences() 
	{
		sequences = new Array<Sequence>();
	}
	
	function buildSequenceDesc():String 
	{
		var out:Dynamic = { };
		out.sequences = [];
		out.resolution = textureBounds.width;
		for (s in sequences) {
			if (s.tiles.length == 0) continue;
			out.sequences.push(s.getObject());
		}
		return Json.stringify(out);
	}
	
	public function clear() 
	{
		layers = new Array<BitmapLayer>();
		sequences = new Array<Sequence>();
		currentSequence = null;
		currentTile = null;
	}
	

	public function getPng(scale:Float = 1):ByteArray 
	{
		return getTexture(scale).toPngBytes();
	}
	public function getTexture(scale:Float = 1):BitmapData {
		if (generatedTexture != null) return generatedTexture;
		var bmd:BitmapData = generatedTexture = new BitmapData(cast textureBounds.width * scale, cast textureBounds.height * scale, true, 0);
		var matrix:Matrix = new Matrix();
		for(l in layers) {
			if(scale!=1){
				matrix.identity();
				matrix.translate(l.x*scale, l.y*scale);
				matrix.scale(scale, scale);
			}
			bmd.draw(l.getBitmapData(), matrix, null, null, null, true);
		}
		return bmd;
	}
	
	public function addSequence(s:Sequence = null):Sequence 
	{
		if (s == null) currentSequence = new Sequence();
		else currentSequence = s;
		sequences.push(currentSequence);
		
		return currentSequence;
	}
	
	public function getSequenceArray():Array<Dynamic> 
	{
		var a = new Array<Dynamic>();
		for (s in sequences) 
		{
			a.push(s.name);
		}
		return a;
	}
	
	public function setCurrentTile(t:Tile, refresh:Bool = true) 
	{
		trace("Current tile set");
		currentTile = t;
		for(s in sequences){
			for (tile in s.tiles) {
				if (tile == t) {
					setCurrentSequence(s,refresh);
					return;
				}
			}
		}
	}
	
	public function sequencesToItems():Array<Dynamic> 
	{
		var a:Array<Dynamic> = [];
		for (s in sequences) 
		{
			a.push( { label:s.name, data:s } );
		}
		return a;
	}
	
	public function getSequenceByName(gtsSequence:String):Sequence 
	{
		for (s in sequences) 
		{
			if (s.name == gtsSequence) {
				return s;
			}
		}
		return null;
	}
			
	function setCurrentSequence(s:Sequence,refresh:Bool = true) 
	{
		currentSequence = s;
		currentSequence = s;
		
	}
	
}