package com.furusystems.games.editors.tools 
{
	import com.bit101.components.ComboBox;
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.bit101.components.TreeList;
	import com.bit101.components.VBox;
	import com.furusystems.games.editors.model.gts.GTSFormatter;
	import com.furusystems.games.editors.model.gts.GTSMap;
	import com.furusystems.games.editors.model.gts.GTSSheet;
	import com.furusystems.games.editors.model.gts.Sequence;
	import com.furusystems.games.editors.model.SharedModel;
	import com.furusystems.games.editors.model.skeleton.Bone;
	import com.furusystems.games.editors.utils.ComponentFactory;
	import com.furusystems.logging.slf4as.ILogger;
	import com.furusystems.logging.slf4as.Logging;
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ToolBar extends Sprite
	{
		[Embed(source = "../../../../../../bin/assets/glottis01.png")]
		private static var Glottis:Class;
		private var mainContents:VBox;
		private var newButton:PushButton;
		private var loadButton:PushButton;
		private var saveButton:PushButton;
		private var boneTree:TreeList;
		private var boneName:InputText;
		private var sheetPath:InputText;
		private var boneDepth:NumericStepper;
		private var loadFR:FileReference;
		private var charNameField:InputText;
		private var sequenceList:ComboBox;
		private var frameStepper:NumericStepper;
		private var gtsFile:File;
		private var localOffsetX:NumericStepper;
		private var localOffsetY:NumericStepper;
		private var exportButton:PushButton;
		private var importButton:PushButton;
		private var loadType:int;
		
		public var nw:NativeWindow;
		public static const L:ILogger = Logging.getLogger(ToolBar);
		static private const CHARACTER:int = 0;
		static private const ANIMATIONS:int = 1;
		
		public function ToolBar() 
		{
			var options:NativeWindowInitOptions = new NativeWindowInitOptions();
			nw = new NativeWindow(options);
			nw.title = "Tools";
			nw.width = 320;
			nw.height = 600;
			nw.activate();
			nw.stage.addChild(this);
			nw.addEventListener(Event.CLOSING, onClosing);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			stage.addChild(new Glottis()).alpha = 0.3;
			
			loadFR = new FileReference();
			loadFR.addEventListener(Event.SELECT, onLoadSelect);
			loadFR.addEventListener(Event.COMPLETE, onDataLoaded);
			
			SharedModel.onChanged.add(onModelChange);
			
			buildUI();
			
		}
		
		public function makeNew():void 
		{
			
		}
		
		private function onModelChange(flags:int, data:Object):void 
		{
			if (flags & SharedModel.STRUCTURE || flags & SharedModel.META) boneTree.items = [SharedModel.skeleton.toList()];
			if (flags & SharedModel.META ||  flags & SharedModel.SELECTION) {
				if(SharedModel.skeleton.selectedBone!=null){
					boneName.text = SharedModel.skeleton.selectedBone.name;
					boneDepth.value = SharedModel.skeleton.selectedBone.z;
					frameStepper.value = 0;
					
					localOffsetX.value = SharedModel.selection.localOffset.x;
					localOffsetY.value = SharedModel.selection.localOffset.y;
					
					boneTree.removeEventListener(Event.SELECT, handleTestTreeSelect);
					selectBoneByName(SharedModel.selection.name);
					boneTree.addEventListener(Event.SELECT, handleTestTreeSelect);
					
					if (SharedModel.gts != null) {
						sheetPath.text = SharedModel.gtsPath;
						populateGTS();
						var idx:int = 0;
						for (var j:int = 0; j < SharedModel.gts.sequences.length; j++) 
						{
							var name:String = SharedModel.gts.sequences[j].name;
							if (SharedModel.gts.sequences[j].name == SharedModel.selection.gtsSequence) {
								idx = j + 1; //add 1 to account for index 0 being "none"
								break;
							}
							
						}
						sequenceList.selectedIndex = idx;
						frameStepper.value = SharedModel.selection.gtsSequenceFrame;
					}
				}
				sheetPath.text = SharedModel.gtsPath;
				charNameField.text = SharedModel.characterName;
			}
		}
		
		private function buildUI():void 
		{
			mainContents = new VBox(stage,4,4);
			charNameField = ComponentFactory.labelledInputText("Name: ", mainContents);
			var label:Label = new Label(mainContents, 0, 0, "DiskOps");
			var hbox:HBox = new HBox(mainContents);
			newButton = new PushButton(hbox, 0, 0, "New", onDiskopButton);
			loadButton = new PushButton(hbox, 0, 0, "Load", onDiskopButton);
			saveButton = new PushButton(hbox, 0, 0, "Save", onDiskopButton);
			exportButton = new PushButton(hbox, 0, 0, "Export", onDiskopButton);
			//importButton = new PushButton(hbox, 0, 0, "Import", onDiskopButton);
			newButton.width = loadButton.width = saveButton.width = 50;
			
			hbox = new HBox(mainContents);
			sheetPath = ComponentFactory.labelledInputText("GTS Sheet path: ", hbox);
			new PushButton(hbox, 0, 0, "load").addEventListener(MouseEvent.CLICK, onGTSLoadClick);
			
			
			label = new Label(mainContents, 0, 0, "Skeleton");
			boneTree = new TreeList(mainContents , 0, 0, [SharedModel.skeleton.toList()]);
			boneTree.alpha = 0.9;
			boneTree.setSize(290, 100);
			boneTree.addEventListener(Event.SELECT, handleTestTreeSelect);
			hbox = new HBox(mainContents);
			new PushButton(hbox, 0, 0, "+").addEventListener(MouseEvent.CLICK, onAddBoneButton);
			new PushButton(hbox, 0, 0, "-").addEventListener(MouseEvent.CLICK, onRemoveBoneButton);
			
			label = new Label(mainContents, 0, 0, "Bone");
			boneName = ComponentFactory.labelledInputText("Name: ", mainContents);
			boneDepth = ComponentFactory.labelledStepper("Z: ", mainContents);
			hbox = new HBox(mainContents);
			new PushButton(hbox, 0, 0, "Flip X").addEventListener(MouseEvent.CLICK,flipX);
			new PushButton(hbox, 0, 0, "Flip Y").addEventListener(MouseEvent.CLICK,flipY);
			
			hbox = new HBox(mainContents);
			sequenceList = new ComboBox(hbox, 0, 0, "No GTS loaded");
			sequenceList.addEventListener(Event.SELECT, onSequenceSelect);
			frameStepper = new NumericStepper(hbox, 0, 0, onSequenceStep);
			hbox = new HBox(mainContents);
			label = new Label(hbox, 0, 0, "X offset");
			localOffsetX = new NumericStepper(hbox, 0, 0, onOffsetChange);
			hbox = new HBox(mainContents);
			label = new Label(hbox, 0, 0, "Y offset");
			localOffsetY = new NumericStepper(hbox, 0, 0, onOffsetChange);
			
			label = new Label(mainContents, 0, 0, "Animation");
			label = new Label(mainContents, 0, 0, "Meta");
			
			boneName.addEventListener(Event.CHANGE, onTfChange);
			boneDepth.addEventListener(Event.CHANGE, onTfChange);
			sheetPath.addEventListener(Event.CHANGE, onTfChange);
			charNameField.addEventListener(Event.CHANGE, onTfChange);
			
			gtsFile = new File();
			gtsFile.addEventListener(Event.SELECT, onGTSSelected);
		}
		
		private function onOffsetChange(e:Event):void 
		{
			if (SharedModel.selection == null) return;
			switch(e.currentTarget) {
				case localOffsetX:
					SharedModel.selection.localOffset.x = localOffsetX.value;
					break;
				case localOffsetY:
					SharedModel.selection.localOffset.y = localOffsetY.value;
					break;
			}
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
		}
		
		private function flipY(e:MouseEvent):void 
		{
			if (SharedModel.skeleton.selectedBone == null) return;
			SharedModel.selection.scale.y *= -1;
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
		}
		
		private function flipX(e:MouseEvent):void 
		{
			if (SharedModel.skeleton.selectedBone == null) return;
			SharedModel.selection.scale.x *= -1;
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
		}
		
		private function onGTSClearClick(e:MouseEvent):void 
		{
			if (SharedModel.skeleton.selectedBone == null) return;
			SharedModel.selection.clearGTS();
		}
		
		private function onSequenceStep(e:Event = null):void 
		{
			if (SharedModel.skeleton.selectedBone == null) return;
			var newValue:int = frameStepper.value;
			var seq:Sequence = SharedModel.gts.getSequenceByName(SharedModel.selection.gtsSequence);
			if (newValue > seq.tiles.length-1) {
				newValue = 0;
			}else if (newValue < 0) {
				newValue = seq.tiles.length - 1;
			}
			SharedModel.selection.gtsSequenceFrame = frameStepper.value = newValue;
			SharedModel.onChanged.dispatch(SharedModel.BONES, SharedModel.selection.boneID);
		}
		
		private function onGTSLoadClick(e:Event = null):void 
		{
			trace("GTS load request");
			gtsFile.browse([new FileFilter("GTS sheet 2.0", "*.gts")]);
		}
		
		private function onGTSSelected(e:Event):void 
		{
			trace("GTS Selected");
			var sheet:GTSSheet;
			if (GTSMap[gtsFile.nativePath] != null) {
				sheet = GTSMap[gtsFile.nativePath];
			}else {
				var load:FileStream = new FileStream();
				load.open(gtsFile, FileMode.READ);
				var bytes:ByteArray = new ByteArray();
				load.readBytes(bytes);
				sheet = GTSFormatter.read(bytes);
				GTSMap[gtsFile.nativePath] = sheet;
			}
			SharedModel.gts = sheet;
			sheetPath.text = gtsFile.nativePath;
			SharedModel.gtsPath = sheetPath.text;
			
			populateGTS();
			
			sequenceList.selectedIndex = 0;
			var allBones:Vector.<Bone> = SharedModel.skeleton.listBones();
			while (allBones.length > 0) {
				var b:Bone = allBones.pop();
				b.gtsSequence = "n/a";
				b.gtsSequenceFrame = 0;
			}
		}
		
		public function populateGTS():void 
		{
			sequenceList.removeAll();
			sequenceList.addItem( { label:"n/a" } );
			if (SharedModel.gts == null) return;
			for (var j:int = 0; j < SharedModel.gts.sequences.length; j++) 
			{
				sequenceList.addItem( { label:SharedModel.gts.sequences[j].name } );
			}
		}
		
		private function onSequenceSelect(e:Event):void 
		{
			if (SharedModel.skeleton.selectedBone == null) return;
			SharedModel.selection.gtsSequence = sequenceList.selectedItem.label;
			SharedModel.selection.inheritOffset();
			SharedModel.onChanged.dispatch(SharedModel.ANIMATION | SharedModel.BONES, SharedModel.selection.boneID);
		}
		
		private function onTfChange(e:Event):void 
		{
			switch(e.currentTarget) {
				case boneDepth:
					if (SharedModel.skeleton.selectedBone == null) return;
					SharedModel.skeleton.selectedBone.z = boneDepth.value;
					SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
					break;
				case boneName:
					if (SharedModel.skeleton.selectedBone == null) return;
					SharedModel.skeleton.selectedBone.name = boneName.text;
					break;
				case sheetPath:
					if (SharedModel.skeleton.selectedBone == null) return;
					SharedModel.gtsPath = sheetPath.text;
					break;
				case charNameField:
					SharedModel.characterName = charNameField.text;
					break;
			}
			SharedModel.onChanged.dispatch(SharedModel.META, null);
		}
		
		private function onKeyboardDown(e:KeyboardEvent):void 
		{
			if (e.keyCode == Keyboard.ENTER) {
				if (SharedModel.skeleton.selectedBone == null) return;
				switch(e.currentTarget) {
					case boneName:
						SharedModel.skeleton.selectedBone.name = boneName.text;
						break;
					case sheetPath:
						SharedModel.gtsPath = sheetPath.text;
						break;
					case charNameField:
						SharedModel.characterName = charNameField.text;
						break;
				}
				SharedModel.onChanged.dispatch(SharedModel.META, null);
			}
		}
		
		private function handleTestTreeSelect(e:Event):void
		{
			var item:* = TreeList(e.target).selectedItem;
			if (item == null) return;
			trace('TreeList select:', item.label, item.bone);
			SharedModel.skeleton.selectedBone = item.bone;
			SharedModel.onChanged.dispatch(SharedModel.SELECTION, SharedModel.selection.boneID);
		}
		
		private function onRemoveBoneButton(e:Event = null):void 
		{
			if (SharedModel.skeleton.selectedBone == null) return;
			var b:Bone = SharedModel.skeleton.selectedBone;
			if (b.parent == null) return;
			var p:Bone = b.parent;
			b.parent.removeChild(b);
			SharedModel.skeleton.selectedBone = p;
			selectBoneByName(p.name);
			b.dispose();
			SharedModel.onChanged.dispatch(SharedModel.STRUCTURE, null );
		}
		
		private function onAddBoneButton(e:Event = null):void 
		{
			if (SharedModel.skeleton.selectedBone == null) return;
			var b:Bone = SharedModel.skeleton.selectedBone;
			SharedModel.skeleton.selectedBone = b.addBone("");
			SharedModel.onChanged.dispatch(SharedModel.STRUCTURE, null);
			selectBoneByName(SharedModel.skeleton.selectedBone.name);
		}
		
		public function selectBoneByName(name:String):void {
			for (var i:int = boneTree.items.length; i--; ) 
			{
				if (boneTree.items[i].label == name) {
					boneTree.selectedIndex = i;
					return;
				}
			}
			boneTree.selectedIndex = 0;
		}
		
		private function onDiskopButton(e:Event = null):void 
		{
			var fr:FileReference;
			switch(e.currentTarget) {
				case newButton:
					SharedModel.clear();
					break;
				case loadButton:
					loadType = CHARACTER;
					loadFR.browse([new FileFilter("Character file", "*.char")]);
					break;
				case saveButton:
					fr = new FileReference();
					fr.save(SharedModel.serialize(), SharedModel.characterName + ".char");
					break;
				case exportButton:
					fr = new FileReference();
					fr.save(SharedModel.export(), SharedModel.characterName + ".anims");
					break;
			}
		}
		
		private function onLoadSelect(e:Event):void 
		{
			L.info("Load select");
			switch(loadType) {
				case CHARACTER:
					loadFR.load();
					boneTree.selectedIndex = 0;
					SharedModel.skeleton.selectedBone = SharedModel.skeleton;
					break;
				case ANIMATIONS:
					loadFR.load();
					break;
			}
		}
		
		private function onDataLoaded(e:Event):void 
		{
			switch(loadType) {
				case CHARACTER:
					L.info("Character load complete");
					SharedModel.load(loadFR.data.readUTFBytes(loadFR.data.bytesAvailable));
					populateGTS();
					break;
				case ANIMATIONS:
					L.info("Animation load complete");
					//SharedModel.importAnims(loadFR.data.readUTFBytes(loadFR.data.bytesAvailable));
					break;
			}
		}
		
		private function onClosing(e:Event):void 
		{
			NativeApplication.nativeApplication.exit(0);
		}
		
		private function onStageResize(e:Event):void 
		{
			
		}
		
	}

}