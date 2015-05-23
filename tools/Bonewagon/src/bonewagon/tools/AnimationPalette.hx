package bonewagon.tools;
import bonewagon.model.animation.Animation;
import bonewagon.model.SharedModel;
import bonewagon.tools.clips.ClipView;
import com.furusystems.fl.gui.Button;
import com.furusystems.fl.gui.HBox;
import com.furusystems.fl.gui.VBox;
import flash.desktop.NativeApplication;
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.display.NativeWindowSystemChrome;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
/**
 * ...
 * @author Andreas Rønning
 */
class AnimationPalette extends Sprite
{
	var listContainer:VBox;
	var addButton:Button;
	public var nw:NativeWindow;
	
	public var clipViews:Array<ClipView>;
	
	public function AnimationPalette() 
	{
		var options:NativeWindowInitOptions = new NativeWindowInitOptions();
		nw = new NativeWindow(options);
		nw.title = "Clips";
		nw.width = 320;
		nw.height = 800;
		nw.activate();
		nw.stage.addChild(this);
		nw.addEventListener(Event.CLOSING, onClosing);
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		stage.addEventListener(Event.RESIZE, onStageResize);
		stage.color = 0x222222;
		
		var allControls:VBox = new VBox();
		addChild(allControls);
		allControls.spacing = 1;
		var mainControls:HBox = new HBox();
		allControls.add(mainControls);
		addButton = new Button("Create");
		addButton.addEventListener(MouseEvent.CLICK, createNewClip);
		mainControls.add(addButton);
		
		listContainer = new VBox();
		listContainer.spacing = 1;
		allControls.add(listContainer);
		
		SharedModel.onChanged.add(onModelChanged);
	}
	
	
	function createNewClip(e:MouseEvent) 
	{
		var a:Animation = Animation.fromOb(SharedModel.basePose.serialize());
		SharedModel.playback.currentAnimation = a;
		SharedModel.animations.push(a);
		SharedModel.onChanged.dispatch(SharedModel.ANIMATION | SharedModel.ANIMATION_LIST, ChangedData.next(a));
	}
	
	function onModelChanged(flags:Int, data:Dynamic) 
	{
		if (flags & SharedModel.ANIMATION_LIST != 0 || flags & SharedModel.LOAD != 0) {
			rebuildList();
		}
	}
	
	function rebuildList() 
	{
		clipViews = new Array<ClipView>();
		listContainer.removeChildren();
		var c:ClipView = new ClipView(this, SharedModel.basePose,true);
		c.selected = SharedModel.basePose == SharedModel.playback.currentAnimation;
		c.setSize(stage.stageWidth);
		listContainer.addChild(c);
		for (a in SharedModel.animations) 
		{
			c = new ClipView(this, a);
			c.setSize(stage.stageWidth);
			listContainer.addChild(c);
			c.selected = a == SharedModel.playback.currentAnimation;
			clipViews.push(c);
		}
	}
	
	function onClosing(e:Event) 
	{
		NativeApplication.nativeApplication.exit(0);
	}
	
	function onStageResize(e:Event = null) 
	{
	}
	
}