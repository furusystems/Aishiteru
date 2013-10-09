package com.furusystems.tilesheeter
{
	import com.furusystems.tilesheeter.canvas.Canvas;
	import com.furusystems.tilesheeter.dialog.Dialog;
	import com.furusystems.tilesheeter.magnifier.Magnifier;
	import com.furusystems.tilesheeter.sequences.SequenceEditor;
	import com.furusystems.tilesheeter.toolbar.Toolbar;
	import flash.desktop.NativeApplication;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import no.doomsday.tools.SplashScreen;
	
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Main extends Sprite 
	{
		private var tb:Toolbar;
		private var canvas:Canvas;
		private var sd:SharedData = new SharedData();
		private var mag:Magnifier;
		private var sequenceEditor:SequenceEditor;
		
		public function Main():void 
		{
			
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			canvas = new Canvas(sd);
			tb  = new Toolbar(sd,canvas);
			mag = new Magnifier();
			sequenceEditor = sd.sequenceEditor;
			addChild(canvas).x = tb.width;
			addChild(tb);
			addChild(mag);
			canvas.tileContainer.addChild(sequenceEditor);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(Event.RESIZE, onResize); 
			
			
			var ns:Namespace = NativeApplication.nativeApplication.applicationDescriptor.namespace();
			var v:String = NativeApplication.nativeApplication.applicationDescriptor.ns::versionNumber;
			
			var splashSource:Sprite = new Sprite();
			splashSource.graphics.beginFill(0x333333);
			splashSource.graphics.drawRect(0, 0, 320, 240);
			var tf:TextField = new TextField();
			tf.selectable = false;
			tf.multiline = true;
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.defaultTextFormat = new TextFormat("verdana", 10, 0xFEFEFE);
			tf.appendText("tilesheeter\n");
			tf.defaultTextFormat = new TextFormat("verdana", 10, 0xcccccc);
			tf.appendText(v);
			tf.x = tf.y = 5;
			splashSource.addChild(tf);
			
			SplashScreen.create(splashSource);
		}
		
		private function onResize(e:Event):void 
		{
			resize();
		}
		
		private function onAddedToStage(e:Event):void 
		{
			Dialog.stage = stage;
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			resize();
		}
		
		private function resize():void 
		{
			tb.resize();
			canvas.x = tb.width;
			canvas.resize();
		}
		
	}
	
}