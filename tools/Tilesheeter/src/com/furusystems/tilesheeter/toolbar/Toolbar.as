package com.furusystems.tilesheeter.toolbar 
{
	import com.bit101.components.CheckBox;
	import com.bit101.components.ComboBox;
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.List;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.bit101.components.VBox;
	import com.furusystems.tilesheeter.canvas.BitmapLayer;
	import com.furusystems.tilesheeter.canvas.Canvas;
	import com.furusystems.tilesheeter.canvas.Subtexture;
	import com.furusystems.tilesheeter.IResizable;
	import com.furusystems.tilesheeter.preview.Preview;
	import com.furusystems.tilesheeter.sequences.Sequence;
	import com.furusystems.tilesheeter.SharedData;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Toolbar extends Sprite implements IResizable
	{
		
		private var _canvas:Canvas;
		private var sizeSelector:NumericStepper;

		private var _currentTool:int;
		private var _gridenabled:Boolean = false;
		private var gridCellHeightSelector:NumericStepper;
		private var gridCellWidthSelector:NumericStepper;
		private var gridToggle:PushButton;
		private var _model:SharedData;
		private var saveButton:PushButton;
		private var loadButton:PushButton;
		private var loadFileRef:FileReference;
		private var curveResolutionStepper:NumericStepper;
		private var catmullRomExecuteButton:PushButton;
		private var undoButton:PushButton;
		private var revertButton:PushButton;
		private var _lastLoadedSpline:String;
		private const filemode_texture:int = 0;
		private const filemode_descriptor:int = 1;
		private const filemode_subtexture:int = 2;
		private var fileMode:int;
		private var lastFilenameOpened:String;
		private var modeSwitch:PushButton;
		private var modeLabel:Label;
		private var guiContents:VBox;
		private var textureModeContents:VBox;
		private var sequenceModeContents:VBox;
		private var sequenceList:ComboBox;
		private var sequenceName:InputText;
		private var addSequenceBtn:PushButton;
		private var removeSequenceBtn:PushButton;
		private var tileList:List;
		private var toolList:List;
		private var preview:Preview;
		private var playButton:PushButton;
		private var centerButton:PushButton;
		private var frameRate:InputText;
		private var bgSwitch:PushButton;
		private var loopButton:PushButton;
		private var hitareaX:InputText;
		private var hitareaY:InputText;
		private var saveButton2:PushButton;
		private var loadButton2:PushButton;
		private var textureList:VBox;
		private var addSubtexBtn:PushButton;
		private var sizeLabel:Label;
		private var fileOptions:VBox;
		private var commonContents:VBox;
		
		public function Toolbar(model:SharedData,canvas:Canvas) 
		{
			_model = model;
			_model.changed.add(onModelChanged);
			_canvas = canvas;
			
			loadFileRef = new FileReference();
			loadFileRef.addEventListener(Event.COMPLETE, onFileLoaded, false, 0, true);
			loadFileRef.addEventListener(Event.SELECT, onFileSelected);
			
			guiContents = new VBox(this, 10, 10);
			
			commonContents = new VBox(guiContents);
			new Label(commonContents, 0, 0, "Canvas");
			bgSwitch = new PushButton(commonContents, 0, 0, "Background", switchBackground);
			
			modeSwitch = new PushButton(commonContents, 0, 0, "Switch mode", toggleMode);
			modeLabel = new Label(commonContents, 0, 0, _model.interactionMode);
			
			//{sequence mode
			sequenceModeContents = new VBox(null, 10, 10);
			sequenceModeContents.spacing = 2;
			
			var alphaMaskSwitch:PushButton = new PushButton(sequenceModeContents, 0, 0, "Toggle alpha", _canvas.toggleAlphaMask);
			new Label(sequenceModeContents, 0, 0, "Sequences");
			var hbox:HBox = new HBox(sequenceModeContents);
			addSequenceBtn = new PushButton(hbox, 0, 0, "Add", addSequence);
			removeSequenceBtn = new PushButton(hbox, 0, 0, "Delete", removeSequence);
			addSequenceBtn.width = removeSequenceBtn.width = 80;
			sequenceList = new ComboBox(sequenceModeContents, 0, 0, "Sequences");
			sequenceList.addEventListener(Event.SELECT, onSequenceSelected);
			
			new Label(sequenceModeContents, 0, 0, "Sequence");
			sequenceName = new InputText(sequenceModeContents, 0, 0, "...", onSequenceNameChanged);
			
			tileList = new List(sequenceModeContents, 0, 0, null);
			tileList.height = 60;
			tileList.addEventListener(Event.SELECT, onTileSelected);
			loopButton = new PushButton(sequenceModeContents, 0, 0, "Looping", toggleLoop);
			
			new Label(sequenceModeContents, 0, 0, "Hitarea");
			hitareaX = new InputText(sequenceModeContents, 0, 0, "0", onHitAreaInputChange);
			hitareaY = new InputText(sequenceModeContents, 0, 0, "0", onHitAreaInputChange);
			
			new Label(sequenceModeContents, 0, 0, "Preview");
			preview = new Preview(_model);
			centerButton = new PushButton(sequenceModeContents, 0, 0, "Center frame", centerFrame);
			sequenceModeContents.addChild(preview);
			playButton = new PushButton(sequenceModeContents, 0, 0, "Toggle play",preview.togglePlay);
			frameRate = new InputText(sequenceModeContents, 0, 0, "30", onFramerateChanged);
			
			//}
			
			//{ texture mode
			textureModeContents = new VBox(guiContents, 10, 10);
			var lb:HBox = new HBox(textureModeContents)
			new PushButton(lb, 0, 0, "Set base", loadTexture).setSize(80, 20);
			sizeLabel = new Label(lb, 0, 0, "");
			
			new Label(textureModeContents, 0, 0, "Subtextures");
			addSubtexBtn = new PushButton(textureModeContents, 0, 0, "Add", addVersion);
			addSubtexBtn.enabled = false;
			textureList = new VBox(textureModeContents);
			//}
			
			fileOptions = new VBox(guiContents);
			new Label(fileOptions, 0, 0, "GTS");
			saveButton = new PushButton(fileOptions, 0, 0, "Save", saveGTS);
			loadButton= new PushButton(fileOptions, 0, 0, "Load", loadGTS);
			saveButton2 = new PushButton(fileOptions, 0, 0, "JSON to clipboard", jsonToClipboard);
			loadButton2= new PushButton(fileOptions, 0, 0, "JSON from clipboard", jsonFromClipboard);
		}
		
		private function addVersion(e:Event):void 
		{
			fileMode = filemode_subtexture;
			loadFileRef.browse([new FileFilter("bitmap", "*.png")]);
		}
		
		private function jsonFromClipboard(e:Event):void 
		{
			_model.parseDescriptor(String(Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT)));
		}
		
		private function jsonToClipboard(e:Event):void 
		{
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, _model.getJSON());
		}
		
		private function onHitAreaInputChange(e:Event = null):void 
		{
			if (_model.currentSequence == null) return;
			if (hitareaX.text == "0" && hitareaY.text == "0") {
				_model.currentSequence.hitAreaType = Sequence.NONE;
			}else if (hitareaX.text != "0" && hitareaY.text == "0") {
				_model.currentSequence.hitAreaType = Sequence.CIRCLE;
				_model.currentSequence.hitcircle = Number(hitareaX.text);
			}else if (hitareaX.text == "0" && hitareaY.text != "0") {
				_model.currentSequence.hitAreaType = Sequence.CIRCLE;
				_model.currentSequence.hitcircle = Number(hitareaY.text);
			}else {
				_model.currentSequence.hitAreaType = Sequence.RECT;
				_model.currentSequence.hitbox.width = Number(hitareaX.text);
				_model.currentSequence.hitbox.height = Number(hitareaY.text);
			}
		}
		
		private function toggleLoop(e:Event):void 
		{
			if (_model.currentSequence) {
				_model.currentSequence.looping = !_model.currentSequence.looping;
				loopButton.label = _model.currentSequence.looping?"Looping":"Not looping";
			}
		}
		
		private function switchBackground(e:Event):void 
		{
			_canvas.nextBackground();
		}
		
		private function onFramerateChanged(e:Event):void 
		{
			if (_model.currentSequence) {
				_model.currentSequence.frameRate = Number(frameRate.text);
			}
		}
		
		private function centerFrame(e:Event):void 
		{
			if (_model.currentTile != null) {
				_model.currentTile.makeCenter();
			}
			_model.setDirty();
		}
		
		private function onToolSelected(e:Event):void 
		{
			
		}
		
		private function onTileSelected(e:Event):void 
		{
			if (_model.currentSequence.tiles.length == 0) return;
			_model.setCurrentTile(_model.currentSequence.tiles[tileList.selectedIndex],false);
			preview.setFrame(_model.currentSequence.tiles[tileList.selectedIndex], _model.getTexture());
			trace("Tile selected: " + tileList.selectedIndex);
		}
		
		private function onSequenceSelected(e:Event):void 
		{
			for (var i:int = 0; i < _model.sequences.length; i++) 
			{
				if (_model.sequences[i].name == sequenceList.selectedItem) {
					_model.currentSequence = _model.sequences[i];
					if (_model.currentSequence.tiles.length > 0) _model.currentTile = _model.currentSequence.tiles[0];
					sequenceName.text = _model.currentSequence.name;
					rebuildTileList();
					loopButton.label = _model.currentSequence.looping?"Looping":"Not looping";
					updateHitboxFields();
					preview.poke();
					break;
				}
			}
			
		}
		
		private function updateHitboxFields():void 
		{
			if (_model.currentSequence == null) return;
			switch(_model.currentSequence.hitAreaType) {
				case Sequence.CIRCLE:
					hitareaX.text = ""+_model.currentSequence.hitcircle;
					hitareaY.text = "0";
					break;
				case Sequence.RECT:
					hitareaX.text = ""+_model.currentSequence.hitbox.width;
					hitareaY.text = ""+_model.currentSequence.hitbox.height;
					break;
				default:
					hitareaX.text = "0";
					hitareaY.text = "0";
			}
		}
		
		
		private function removeSequence(e:Event):void 
		{
			_model.removeCurrentSequence();
			rebuildSequenceList();
			if(_model.currentSequence!=null) sequenceList.selectedItem = _model.currentSequence.name;
		}
		
		private function addSequence(e:Event):void 
		{
			sequenceList.selectedItem = _model.addSequence().name;
			rebuildTileList();
			tileList.selectedIndex = 0;
		}
		
		private function onSequenceNameChanged(e:Event):void 
		{
			if (_model.currentSequence != null) {
				_model.currentSequence.name = sequenceName.text;
				rebuildSequenceList();
				sequenceList.selectedItem = sequenceName.text;
			}
		}
		
		private function toggleMode(e:Event):void 
		{
			_model.toggleMode();
			modeLabel.text = _model.interactionMode;
			updateGUI();
		}
		
		private function updateGUI():void {
			guiContents.removeChildren();
			guiContents.addChild(commonContents);
			switch(_model.interactionMode) {
				case "texture":
					guiContents.addChild(textureModeContents);
					_canvas.turnoffAlphaMask();
					break;
				case "sequence":
					guiContents.addChild(sequenceModeContents);
					break;
			}
			guiContents.addChild(fileOptions);
		}
		
		private function saveTexture(e:Event):void 
		{
			new FileReference().save(_model.getPng(), "texture.png");
		}
		
		private function loadTexture(e:Event):void 
		{
			fileMode = filemode_texture;
			loadFileRef.browse([new FileFilter("bitmap", "*.png;")]);
		}
		
		private function onFileSelected(e:Event):void 
		{
			lastFilenameOpened = loadFileRef.name;
			loadFileRef.load();
		}
		
		private function loadGTS(...args:Array):void 
		{
			fileMode = filemode_descriptor;
			loadFileRef.browse([new FileFilter("gameworx tilesheet", "*.gts;*.mega")]);
		}
		
		private function onFileLoaded(e:Event):void 
		{
			var data:ByteArray = loadFileRef.data;
			switch(fileMode) {
				case filemode_descriptor:
					_model.loadDescriptor(data);
					break;
				case filemode_texture:
					_model.setTexture(data);
					break;
				case filemode_subtexture:
					_model.addSubtexture(data);
					break;
			}
		}
		
		private function saveGTS(e:MouseEvent):void 
		{
			new FileReference().save(_model.buildDescriptor(), "sprites.gts");
		}
		
		/* INTERFACE no.doomsday.games.tools.pathtool.IResizable */
		
		public function resize():void 
		{
			graphics.clear();
			graphics.lineStyle(1, 0);
			graphics.beginFill(0);
			graphics.drawRect(0, 0, 200, stage.stageHeight);
			graphics.endFill();
		}
		
		private function onModelChanged():void 
		{
			addSubtexBtn.enabled = _model.baseTexture != null;
			var name:String = _model.textureBounds.width+"";
			sizeLabel.text = name;
			rebuildSequenceList();
			rebuildTileList();
			updateHitboxFields();
			rebuildTexturesList();
			updateGUI();
			
		}
		
		private function rebuildTexturesList():void 
		{
			textureList.removeChildren();
			for each(var l:Subtexture in _model.subTextures) {
				textureList.addChild(createSubTexView(l));
			}
			textureList.parent.addChild(textureList);
		}
		
		private function createSubTexView(l:Subtexture):HBox 
		{
			var hbox:HBox = new HBox();
			var diff:Number = l.bmd.width / _model.textureBounds.width;
			new Label(hbox,0,0, l.name+"("+diff+")");
			new PushButton(hbox, 0, 0, "Delete", function(e:Event):void { _model.removeSubTexture(l) } ).setSize(40,15);
			new PushButton(hbox, 0, 0, "Replace", function(e:Event):void { _model.removeSubTexture(l); addVersion(e);  } ).setSize(40, 15);
			return hbox;
		}
		
		private function rebuildSequenceList():void 
		{
			sequenceList.removeAll();
			for (var i:int = 0; i < _model.sequences.length; i++) 
			{
				sequenceList.addItem(_model.sequences[i].name);
			}
			if(_model.currentSequence!=null) frameRate.text = ""+_model.currentSequence.frameRate;
		}
		
		private function rebuildTileList():void 
		{
			
			tileList.removeAll();
			if (_model.currentSequence == null) return;
			for (var i:int = 0; i < _model.currentSequence.tiles.length; i++) 
			{
				tileList.addItem("Frame " + i);
				if (_model.currentSequence.tiles[i] == _model.currentTile) {
					tileList.selectedIndex = i;
				}
			}
			if(_model.currentSequence!=null) frameRate.text = ""+_model.currentSequence.frameRate;
		}
		
	}

}