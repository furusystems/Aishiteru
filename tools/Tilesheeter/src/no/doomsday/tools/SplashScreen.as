package no.doomsday.tools 
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class SplashScreen 
	{
		private static var screen:SplashScreen;
		private var source:DisplayObject;
		private var duration:Number;
		private var nw:NativeWindow;
		private var t:Timer;
		public static function create(source:DisplayObject,duration:Number = 1500):void {
			screen = new SplashScreen(source, duration);
		}
		public static function closeScreen(e:Event = null):void {
			if (screen != null) {
				screen.nw.close();
			}
			screen = null;
		}
		public function SplashScreen(source:DisplayObject,duration:Number = 1500) 
		{
			super();
			this.duration = duration;
			this.source = source;
			var options:NativeWindowInitOptions = new NativeWindowInitOptions();
			options.systemChrome = "none";
			options.minimizable = options.maximizable = false;
			options.transparent = true;
			nw = new NativeWindow(options);
			nw.stage.scaleMode = StageScaleMode.NO_SCALE;
			nw.stage.align = StageAlign.TOP_LEFT;
			nw.alwaysInFront = true;
			nw.stage.addChild(source);
			nw.width = source.width;
			nw.height = source.height;
			nw.x = Capabilities.screenResolutionX / 2 - source.width / 2;
			nw.y = Capabilities.screenResolutionY / 2 - source.height / 2;
			nw.activate();
			t = new Timer(duration, 1);
			t.addEventListener(TimerEvent.TIMER_COMPLETE, onTimer,false,0,true);
			t.start();
			nw.stage.addEventListener(MouseEvent.CLICK, onTimer, false, 0, true);
		}
		
		private function onTimer(e:Event):void 
		{
			closeScreen();
		}
		
	}

}