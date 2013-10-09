package com.furusystems.tilesheeter 
{
	import com.adobe.images.PNGEncoder;
	import com.bit101.components.ListItem;
	import com.furusystems.tilesheeter.canvas.BitmapLayer;
	import com.furusystems.tilesheeter.canvas.Subtexture;
	import com.furusystems.tilesheeter.dialog.Dialog;
	import com.furusystems.tilesheeter.format.GTSFormatter;
	import com.furusystems.tilesheeter.sequences.Sequence;
	import com.furusystems.tilesheeter.sequences.SequenceEditor;
	import com.furusystems.tilesheeter.sequences.Tile;
	import com.nochump.zip.ZipEntry;
	import com.nochump.zip.ZipFile;
	import com.nochump.zip.ZipOutput;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import ion.utils.png.PNGDecoder;
	import org.osflash.signals.Signal;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class SharedData 
	{
		public static var instance:SharedData;
		private var _textureSize:Rectangle = new Rectangle(0, 0, 0, 0);
		private var _gridWidth:int = 8;
		private var _gridHeight:int = 8;
		private var _gridEnabled:Boolean = false;
		public var interactionMode:String = "texture";
		
		public var baseTexture:BitmapData;
		public var subTextures:Vector.<Subtexture>;
		
		public var sequences:Vector.<Sequence> = new Vector.<Sequence>();
		public var sequenceEditor:SequenceEditor;
		
		public const changed:Signal = new Signal();
		public const modeChanged:Signal = new Signal();
		public var currentSequence:Sequence;
		public var currentTile:Tile;
		
		public function SharedData() {
			if (instance == null) {
				instance = this;
			}
			sequenceEditor = new SequenceEditor(this);
			subTextures = new Vector.<Subtexture>();
			baseTexture = null;
		}
		
		public function setTexture(data:ByteArray):void 
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onMainTextureLoaded);
			loader.loadBytes(data);
		}
		
		private function onMainTextureLoaded(e:Event):void 
		{
			var ldr:Loader = LoaderInfo(e.currentTarget).loader;
			LoaderInfo(e.currentTarget).removeEventListener(Event.COMPLETE, onMainTextureLoaded);
			var tex:BitmapData = Bitmap(ldr.content).bitmapData;
			if(!evalTex(tex)) {
				new Dialog("Texture not square or not power of two");
				return;
			}
			baseTexture = tex;
			_textureSize.setTo(0, 0, baseTexture.width, baseTexture.height);
			setDirty();
		}
		
		private function evalTex(tex:BitmapData):Boolean {
			return(tex.width == tex.height && isPot(tex.width));
		}
		
		private function isPot(x:int):Boolean 
		{
			return (x & (x - 1)) == 0;
		}
		
		public function addSubtexture(data:ByteArray):void 
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSubTextureLoaded);
			loader.loadBytes(data);
		}
		
		private function onSubTextureLoaded(e:Event):void 
		{
			var ldr:Loader = LoaderInfo(e.currentTarget).loader;
			LoaderInfo(e.currentTarget).removeEventListener(Event.COMPLETE, onSubTextureLoaded);
			var tex:BitmapData = Bitmap(ldr.content).bitmapData;
			
			var nt:Subtexture = new Subtexture(tex);
			if (evalTex(nt.bmd) && nt.bmd.width != textureBounds.width ) {
				subTextures.push(nt);
				setDirty();
			}else {
				new Dialog("Subtexture not square, not power of two or duplicate size of main");
			}
		}
		
		public function deleteObject():void 
		{
			var i:int;
			if (interactionMode == "texture") {
			}else {
				if (currentTile != null) {
					for (i = 0; i < currentSequence.tiles.length; i++) {
						if (currentSequence.tiles[i] == currentTile) {
							currentSequence.tiles.splice(i, 1);
							break;
						}
					}
					setDirty();
				}
			}
		}
		public function nudgeLayer(x:Number, y:Number, shiftKey:Boolean, ctrlKey:Boolean):void {
			if (interactionMode == "texture") {
			}else {
				if (currentTile) {
					if(!shiftKey&&!ctrlKey){
						currentTile.x += x;
						currentTile.y += y;
					}else if(ctrlKey){
						currentTile.center.x += x;
						currentTile.center.y += y;
					}else if (shiftKey) {
						currentTile.width += x;
						currentTile.height += y;
					}
				}
				setDirty();
			}
		}
		
		public function get textureBounds():Rectangle 
		{
			return _textureSize;
		}
		
		public function set textureBounds(value:Rectangle):void 
		{
			_textureSize = value;
			setDirty();
		}
		
		public function get gridColumns():int 
		{
			return _gridWidth;
		}
		
		public function set gridColumns(value:int):void 
		{
			_gridWidth = value;
			setDirty();
		}
		
		public function get gridRows():int 
		{
			return _gridHeight;
		}
		
		public function set gridRows(value:int):void 
		{
			_gridHeight = value;
			setDirty();
		}
		
		public function get gridEnabled():Boolean 
		{
			return _gridEnabled;
		}
		
		public function set gridEnabled(value:Boolean):void 
		{
			_gridEnabled = value;
			setDirty();
		}
		
		
		public function setDirty():void 
		{
			changed.dispatch();
		}
		
		public function buildDescriptor(newFormat:Boolean = true):ByteArray 
		{
			if (newFormat) {
				var images:Vector.<BitmapData> = new Vector.<BitmapData>();
				images.push(getTexture());
				for (var i:int = 0; i < subTextures.length; i++) 
				{
					images.push(subTextures[i].bmd);
				}
				return GTSFormatter.generate(buildSequenceDesc(), images);
			}
			var out:ZipOutput = new ZipOutput();
			
			var entry:ZipEntry = new ZipEntry("descriptor.txt");
			var descriptor:ByteArray = new ByteArray();
			descriptor.writeUTFBytes(buildSequenceDesc());
			out.putNextEntry(entry);
			out.write(descriptor);
			out.closeEntry();
			
			var res:String = textureBounds.width + "x" + textureBounds.height;
			
			entry = new ZipEntry("texture"+res+".png");
			out.putNextEntry(entry);
			out.write(getPng());
			out.closeEntry();
			
			out.finish();
			
			return out.byteArray;
		}
		
		public function loadDescriptor(bytearray:ByteArray):void 
		{
			if (CONFIG::debug) {	
				GTSFormatter.read(bytearray, this);
			}else {
				try {
					GTSFormatter.read(bytearray, this);
					return;
				}catch (e:Error) {
					trace(e);
					new Dialog("Old style GTS");
				}
			}
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
			setDirty();
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
			subTextures = new Vector.<Subtexture>();
			baseTexture = null;
			sequences = new Vector.<Sequence>();
			currentSequence = null;
			currentTile = null;
			setDirty();
		}
		
		public function getPng():ByteArray 
		{
			return PNGEncoder.encode(getTexture());
		}
		public function getTexture():BitmapData {
			return baseTexture;
		}
		
		public function toggleMode():void 
		{
			interactionMode = interactionMode == "sequence"?"texture":"sequence";
			modeChanged.dispatch();
		}
		
		public function addSequence(s:Sequence = null):Sequence 
		{
			if (s == null) currentSequence = new Sequence();
			else currentSequence = s;
			sequences.push(currentSequence);
			setDirty();
			
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
		
		public function removeCurrentSequence():void 
		{
			for (var i:int = 0; i < sequences.length; i++) 
			{
				if (sequences[i] == currentSequence) {
					sequences.splice(i, 1);
				}
			}
			if (sequences.length != 0) currentSequence = sequences[sequences.length - 1];
			else currentSequence = null;
			setDirty();
		}
		
		public function setCurrentTile(t:Tile, refresh:Boolean = true):void 
		{
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
		
		public function getJSON():String 
		{
			return buildSequenceDesc();
		}
		
		public function removeSubTexture(l:Subtexture):void 
		{
			for (var i:int = 0; i < subTextures.length; i++) 
			{
				if (subTextures[i] == l) {
					subTextures.splice(i, 1);
					setDirty();
					return;
				}
			}
		}
		
		private function setCurrentSequence(s:Sequence,refresh:Boolean = true):void 
		{
			currentSequence = s;
			if (refresh) setDirty();
			
		}
		
	}

}