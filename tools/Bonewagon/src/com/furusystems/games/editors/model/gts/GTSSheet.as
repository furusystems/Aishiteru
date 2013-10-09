package com.furusystems.games.editors.model.gts 
{
	import com.adobe.images.PNGEncoder;
	import com.nochump.zip.ZipEntry;
	import com.nochump.zip.ZipFile;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class GTSSheet 
	{		
		public var layers:Vector.<BitmapLayer> = new Vector.<BitmapLayer>();
		public var sequences:Vector.<Sequence> = new Vector.<Sequence>();
		
		public var generatedTexture:BitmapData = null;
		public var textureBounds:Rectangle = new Rectangle();
		
		public var currentSequence:Sequence;
		public var currentTile:Tile;
		
		public function GTSSheet() {
		}	
		
		public function addLayer(data:ByteArray,filename:String):void 
		{
			trace("adding layer: " + filename);
			var l:BitmapLayer = new BitmapLayer(this, data, filename);
			layers.push(l);
		}
		
		
		public function parseDescriptor(json:String):void 
		{
			//trace(json);
			clearSequences();
			var ob:Object = JSON.parse(json);
			if(ob.hasOwnProperty("resolution")){
				textureBounds.width = textureBounds.height = ob.resolution;
			}
			for (var i:int = 0; i < ob.sequences.length; i++) {
				addSequence(Sequence.fromObject(ob.sequences[i]));
			}
		}
		
		private function clearSequences():void 
		{
			sequences = new Vector.<Sequence>();
		}
		
		private function buildSequenceDesc():String 
		{
			var out:Object = { };
			out.sequences = [];
			out.resolution = textureBounds.width;
			for each(var s:Sequence in sequences) {
				if (s.tiles.length == 0) continue;
				out.sequences.push(s.getObject());
			}
			return JSON.stringify(out);
		}
		
		public function clear():void 
		{
			layers = new Vector.<BitmapLayer>();
			sequences = new Vector.<Sequence>();
			currentSequence = null;
			currentTile = null;
		}
		

		public function getPng(scale:Number = 1):ByteArray 
		{
			return PNGEncoder.encode(getTexture(scale));
		}
		public function getTexture(scale:Number = 1):BitmapData {
			if (generatedTexture != null) return generatedTexture;
			var bmd:BitmapData = generatedTexture = new BitmapData(textureBounds.width * scale, textureBounds.height * scale, true, 0);
			var matrix:Matrix = new Matrix();
			for each(var l:BitmapLayer in layers) {
				if(scale!=1){
					matrix.identity();
					matrix.translate(l.x*scale, l.y*scale);
					matrix.scale(scale, scale);
				}
				bmd.draw(l.bitmapData, matrix, null, null, null, true);
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
		
		public function getSequenceArray():Array 
		{
			var a:Array = new Array();
			for (var i:int = 0; i < sequences.length; i++) 
			{
				a.push(sequences[i].name);
			}
			return a;
		}
		
		public function setCurrentTile(t:Tile, refresh:Boolean = true):void 
		{
			trace("Current tile set");
			currentTile = t;
			for each(var s:Sequence in sequences){
				for each(var tile:Tile in s.tiles) {
					if (tile == t) {
						setCurrentSequence(s,refresh);
						return;
					}
				}
			}
		}
		
		public function sequencesToItems():Array 
		{
			var a:Array = [];
			for (var i:int = 0; i < sequences.length; i++) 
			{
				a.push( { label:sequences[i].name, data:sequences[i] } );
			}
			return a;
		}
		
		public function getSequenceByName(gtsSequence:String):Sequence 
		{
			for (var i:int = 0; i < sequences.length; i++) 
			{
				if (sequences[i].name == gtsSequence) {
					return sequences[i];
				}
			}
			return null;
		}
				
		private function setCurrentSequence(s:Sequence,refresh:Boolean = true):void 
		{
			currentSequence = s;
			currentSequence = s;
			
		}
		
	}

}