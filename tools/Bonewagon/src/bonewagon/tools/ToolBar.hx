package bonewagon.tools;
import bonewagon.model.gts.GTSSheet;
import bonewagon.model.gts.Sequence;
import bonewagon.model.SharedModel;
import bonewagon.model.skeleton.Bone;
import bonewagon.model.skeleton.Skeleton;
import bonewagon.utils.ComponentFactory;
import com.furusystems.fl.gui.Button;
import com.furusystems.fl.gui.compound.Dropdown;
import com.furusystems.fl.gui.compound.Stepper;
import com.furusystems.fl.gui.compound.Viewport;
import com.furusystems.fl.gui.layouts.AbstractLayout;
import com.furusystems.fl.gui.layouts.DBox;
import com.furusystems.fl.gui.layouts.treeview.TreeView;
import com.furusystems.fl.gui.Divider;
import com.furusystems.fl.gui.Label;
import com.furusystems.fl.gui.layouts.HBox;
import com.furusystems.fl.gui.layouts.VBox;
import flash.desktop.NativeApplication;
import flash.display.Loader;
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.geom.Rectangle;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.net.URLRequest;
/**
 * ...
 * @author Andreas Rønning
 */
class ToolBar extends Sprite
{
	/*[Embed(source = "../../../../../../bin/assets/glottis01.png")]
	static var Glottis:Class;*/
	
	var mainContents:AbstractLayout;
	var newButton:Button;
	var loadButton:Button;
	var saveButton:Button;
	var boneTree:TreeView;
	var boneName:Label;
	var sheetPath:Label;
	var boneDepth:Stepper;
	var charNameField:Label;
	var sequenceList:Dropdown;
	var frameStepper:Stepper;
	var localOffsetX:Stepper;
	var localOffsetY:Stepper;
	var exportButton:Button;
	var importButton:Button;
	
	var loadFR:FileReference;
	var gtsFile:File;
	var loadType:Int;
	
	public var nw:NativeWindow;
	static inline var CHARACTER:Int = 0;
	static inline var ANIMATIONS:Int = 1;
	
	public function new() 
	{
		super();
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
		//stage.addChild(new Glottis()).alpha = 0.3;
		
		loadFR = new FileReference();
		loadFR.addEventListener(Event.SELECT, onLoadSelect);
		loadFR.addEventListener(Event.COMPLETE, onDataLoaded);
		
		SharedModel.onChanged.add(onModelChange);
		
		buildUI();
		
	}
	
	public function makeNew() 
	{
		
	}
	
	function onModelChange(flags:Int, data:Dynamic) 
	{
		if (flags & SharedModel.STRUCTURE != 0 || flags & SharedModel.META != 0) boneTree.setData(cast SharedModel.skeleton);
		if (flags & SharedModel.META != 0 ||  flags & SharedModel.SELECTION != 0) {
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
					var idx:Int = 0;
					for (j in 0...SharedModel.gts.sequences.length) 
					{
						var name:String = SharedModel.gts.sequences[j].name;
						if (SharedModel.gts.sequences[j].name == SharedModel.selection.gtsSequence) {
							idx = j + 1; //add 1 to account for index 0 being "none"
							break;
						}
						
					}
					//sequenceList.selectedIndex = idx;
					frameStepper.value = SharedModel.selection.gtsSequenceFrame;
				}
			}
			//sheetPath.text = SharedModel.gtsPath;
			//charNameField.text = SharedModel.characterName;
		}
	}
	
	function buildUI() 
	{
		mainContents = new VBox();
		addChild(mainContents);
		mainContents.x = mainContents.y = 4;
		
		mainContents.add(new Divider(stage.stageWidth, HORIZONTAL, 5));
		
		charNameField = ComponentFactory.labelledLabel("Name: ", mainContents, true);

		var label = mainContents.add(new Label("DiskOps"));
		var dbox = mainContents.add(new DBox());
		newButton = dbox.add(new Button("New"));
		loadButton = dbox.add(new Button("Load"));
		saveButton = dbox.add(new Button("Save"));
		exportButton = dbox.add(new Button("Export"));
		newButton.width = loadButton.width = saveButton.width = 50;
		dbox.length = stage.stageWidth-20;
		
		mainContents.add(new Divider(stage.stageWidth, HORIZONTAL, 5));
		
		var hbox = mainContents.add(new HBox());
		hbox.add(new Button("load")).addEventListener(MouseEvent.CLICK, onGTSLoadClick);
		sheetPath = ComponentFactory.labelledLabel("GTS Sheet path: ", hbox);
		
		mainContents.add(new Divider(stage.stageWidth, HORIZONTAL, 5));
				
		label = mainContents.add(new Label("Skeleton"));
		
		var vp = new Viewport(new Rectangle(0, 0, stage.stageWidth-10, 240));
		mainContents.addChild(vp);
		
		boneTree = new TreeView();
		SharedModel.skeleton.buildDummyData();
		
		boneTree.setData(cast SharedModel.skeleton);
		vp.setContent(boneTree);
		//boneTree.addEventListener(Event.SELECT, handleTestTreeSelect);
		
		hbox = mainContents.add(new HBox());
		hbox.add(new Button("+")).addEventListener(MouseEvent.CLICK, onAddBoneButton);
		hbox.add(new Button("-")).addEventListener(MouseEvent.CLICK, onRemoveBoneButton);
		
		/*
		
		label = new Label(mainContents, 0, 0, "Bone");
		boneName = ComponentFactory.labelledLabel("Name: ", mainContents);
		boneDepth = ComponentFactory.labelledStepper("Z: ", mainContents);
		hbox = new HBox(mainContents);
		new Button(hbox, 0, 0, "Flip X").addEventListener(MouseEvent.CLICK,flipX);
		new Button(hbox, 0, 0, "Flip Y").addEventListener(MouseEvent.CLICK,flipY);
		
		hbox = new HBox(mainContents);
		sequenceList = new Dropdown(hbox, 0, 0, "No GTS loaded");
		sequenceList.addEventListener(Event.SELECT, onSequenceSelect);
		frameStepper = new Stepper(hbox, 0, 0, onSequenceStep);
		hbox = new HBox(mainContents);
		label = new Label(hbox, 0, 0, "X offset");
		localOffsetX = new Stepper(hbox, 0, 0, onOffsetChange);
		hbox = new HBox(mainContents);
		label = new Label(hbox, 0, 0, "Y offset");
		localOffsetY = new Stepper(hbox, 0, 0, onOffsetChange);
		
		label = new Label(mainContents, 0, 0, "Animation");
		label = new Label(mainContents, 0, 0, "Meta");
		
		boneName.addEventListener(Event.CHANGE, onTfChange);
		boneDepth.addEventListener(Event.CHANGE, onTfChange);
		sheetPath.addEventListener(Event.CHANGE, onTfChange);
		charNameField.addEventListener(Event.CHANGE, onTfChange);
		
		gtsFile = new File();
		gtsFile.addEventListener(Event.SELECT, onGTSSelected);
		
		*/
	}
	
	function onOffsetChange(e:Event) 
	{
		if (SharedModel.selection == null) return;
		/*
		switch(e.currentTarget) {
			case localOffsetX:
				SharedModel.selection.localOffset.x = localOffsetX.value;
			case localOffsetY:
				SharedModel.selection.localOffset.y = localOffsetY.value;
		}
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
		*/
	}
	
	function flipY(e:MouseEvent) 
	{
		if (SharedModel.skeleton.selectedBone == null) return;
		SharedModel.selection.scale.y *= -1;
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
	}
	
	function flipX(e:MouseEvent) 
	{
		if (SharedModel.skeleton.selectedBone == null) return;
		SharedModel.selection.scale.x *= -1;
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
	}
	
	function onGTSClearClick(e:MouseEvent) 
	{
		if (SharedModel.skeleton.selectedBone == null) return;
		SharedModel.selection.clearGTS();
	}
	
	function onSequenceStep(e:Event = null) 
	{
		if (SharedModel.skeleton.selectedBone == null) return;
		var newValue:Int = cast frameStepper.value;
		var seq:Sequence = SharedModel.gts.getSequenceByName(SharedModel.selection.gtsSequence);
		if (newValue > seq.tiles.length-1) {
			newValue = 0;
		}else if (newValue < 0) {
			newValue = seq.tiles.length - 1;
		}
		SharedModel.selection.gtsSequenceFrame = cast frameStepper.value = newValue;
		SharedModel.onChanged.dispatch(SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	
	function onGTSLoadClick(e:Event = null) 
	{
		trace("GTS load request");
		gtsFile.browse([new FileFilter("GTS sheet 2.0", "*.gts")]);
	}
	
	function onGTSSelected(e:Event) 
	{
		trace("GTS Selected");
		var sheet:GTSSheet;
		/*
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
		
		*/
		
		populateGTS();
		
		//sequenceList.selectedIndex = 0;
		var allBones:Array<Bone> = SharedModel.skeleton.listBones();
		while (allBones.length > 0) {
			var b:Bone = allBones.pop();
			b.gtsSequence = "n/a";
			b.gtsSequenceFrame = 0;
		}
	}
	
	public function populateGTS() 
	{
		/*
		sequenceList.removeAll();
		sequenceList.addItem( { label:"n/a" } );
		if (SharedModel.gts == null) return;
		for (seq in SharedModel.gts.sequences) 
		{
			sequenceList.addItem( { label:seq.name } );
		}
		*/
	}
	
	function onSequenceSelect(e:Event) 
	{
		if (SharedModel.skeleton.selectedBone == null) return;
		//SharedModel.selection.gtsSequence = sequenceList.selectedItem.label;
		SharedModel.selection.inheritOffset();
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION | SharedModel.BONES, ChangedData.next(SharedModel.selection.boneID));
	}
	
	function onTfChange(e:Event) 
	{
		/*switch(e.currentTarget) {
			case boneDepth:
				if (SharedModel.skeleton.selectedBone == null) return;
				SharedModel.skeleton.selectedBone.z = boneDepth.value;
				SharedModel.onChanged.dispatch(SharedModel.ANIMATION, null);
			case boneName:
				if (SharedModel.skeleton.selectedBone == null) return;
				SharedModel.skeleton.selectedBone.name = boneName.text;
			case sheetPath:
				if (SharedModel.skeleton.selectedBone == null) return;
				SharedModel.gtsPath = sheetPath.text;
			case charNameField:
				SharedModel.characterName = charNameField.text;
		}
		SharedModel.onChanged.dispatch(SharedModel.META, null);*/
	}
	
	function onKeyboardDown(e:KeyboardEvent) 
	{
		/*if (e.keyCode == Keyboard.ENTER) {
			if (SharedModel.skeleton.selectedBone == null) return;
			switch(e.currentTarget) {
				case boneName:
					SharedModel.skeleton.selectedBone.name = boneName.text;
				case sheetPath:
					SharedModel.gtsPath = sheetPath.text;
				case charNameField:
					SharedModel.characterName = charNameField.text;
			}
			SharedModel.onChanged.dispatch(SharedModel.META, null);
		}*/
	}
	
	function handleTestTreeSelect(e:Event)
	{
		var item = e.target.selectedItem;
		if (item == null) return;
		trace('TreeList select:', item.label, item.bone);
		SharedModel.skeleton.selectedBone = item.bone;
		SharedModel.onChanged.dispatch(SharedModel.SELECTION, ChangedData.next(SharedModel.selection.boneID));
	}
	
	function onRemoveBoneButton(e:Event = null) 
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
	
	function onAddBoneButton(e:Event = null) 
	{
		if (SharedModel.skeleton.selectedBone == null) return;
		var b:Bone = SharedModel.skeleton.selectedBone;
		SharedModel.skeleton.selectedBone = b.addBone("");
		SharedModel.onChanged.dispatch(SharedModel.STRUCTURE, null);
		selectBoneByName(SharedModel.skeleton.selectedBone.name);
	}
	
	public function selectBoneByName(name:String) {
		
		/*
		
		var i = boneTree.items.length;
		while (i-- > 0) 
		{
			if (boneTree.items[i].label == name) {
				boneTree.selectedIndex = i;
				return;
			}
		}
		boneTree.selectedIndex = 0;
		
		*/
	}
	
	function onDiskopButton(e:Event = null) 
	{
		/*switch(e.currentTarget) {
			case newButton:
				SharedModel.clear();
			case loadButton:
				loadType = CHARACTER;
				loadFR.browse([new FileFilter("Character file", "*.char")]);
			case saveButton:
				var fr = new FileReference();
				fr.save(SharedModel.serialize(), SharedModel.characterName + ".char");
			case exportButton:
				var fr = new FileReference();
				fr.save(SharedModel.export(), SharedModel.characterName + ".anims");
		}*/
	}
	
	function onLoadSelect(e:Event) 
	{
		trace("Load select");
		switch(loadType) {
			case CHARACTER:
				loadFR.load();
				//boneTree.selectedIndex = 0;
				SharedModel.skeleton.selectedBone = SharedModel.skeleton;
			case ANIMATIONS:
				loadFR.load();
		}
	}
	
	function onDataLoaded(e:Event) 
	{
		switch(loadType) {
			case CHARACTER:
				trace("Character load complete");
				SharedModel.load(loadFR.data.readUTFBytes(loadFR.data.bytesAvailable));
				populateGTS();
			case ANIMATIONS:
				trace("Animation load complete");
				//SharedModel.importAnims(loadFR.data.readUTFBytes(loadFR.data.bytesAvailable));
		}
	}
	
	function onClosing(e:Event) 
	{
		NativeApplication.nativeApplication.exit(0);
	}
	
	function onStageResize(e:Event) 
	{
		
	}
	
}