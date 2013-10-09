package com.furusystems.games.editors.tools 
{
	import com.furusystems.games.editors.Main;
	import com.furusystems.games.editors.model.animation.ScriptKey;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.NativeWindowBoundsEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class ScriptEditor extends Sprite
	{
		private var nw:NativeWindow;
		private var currentKey:ScriptKey;
		public var main:Main;
		public var input:TextField = new TextField();
		public function ScriptEditor(main:Main) 
		{
			this.main = main;
			var options:NativeWindowInitOptions = new NativeWindowInitOptions();
			nw = new NativeWindow(options);
			nw.title = "Script editor";
			nw.stage.color = 0x111111;
			nw.width = 320;
			nw.height = 240;
			nw.stage.scaleMode = StageScaleMode.NO_SCALE;
			nw.stage.align = StageAlign.TOP_LEFT;
			addChild(input);
			nw.stage.addChild(this);
			
			input.multiline = true;
			input.defaultTextFormat = new TextFormat("_typewriter", 14, 0xCCCCCC);
			input.type = TextFieldType.INPUT;
			input.addEventListener(Event.CHANGE, onScriptChange);
			
			nw.addEventListener(Event.CLOSING, onWindowClose);
			nw.addEventListener(NativeWindowBoundsEvent.RESIZE, onWindowResize);
			onWindowResize();
		}
		
		private function onWindowClose(e:Event):void 
		{
			main.timeLine.deselectScript();
			hide();
			e.preventDefault();
		}
		
		private function onScriptChange(e:Event):void 
		{
			if (currentKey != null) {
				currentKey.script = input.text;
			}
		}
		public function show():void {
			if (!nw.active) nw.activate();
			nw.visible = true;
			nw.orderToFront();
		}
		
		public function hide():void {
			nw.visible = false;
		}
		public function populate(s:ScriptKey):void {
			this.currentKey = s;
			input.text = currentKey.script;
			show();
		}
		
		private function onWindowResize(e:NativeWindowBoundsEvent = null):void 
		{
			input.width = nw.stage.stageWidth;
			input.height = nw.stage.stageHeight;
		}
		
	}

}