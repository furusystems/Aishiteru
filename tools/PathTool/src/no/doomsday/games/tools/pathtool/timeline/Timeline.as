package no.doomsday.games.tools.pathtool.timeline 
{
	import com.bit101.components.Label;
	import flash.display.BlendMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.getTimer;
	import no.doomsday.games.tools.pathtool.data.SplinePoint;
	import no.doomsday.games.tools.pathtool.IResizable;
	import no.doomsday.games.tools.pathtool.SharedData;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Timeline extends Sprite implements IResizable
	{
		
		private var lineContainer:Sprite = new Sprite();
		private var lines:Vector.<TimelineBar> = new Vector.<TimelineBar>();
		public var sd:SharedData;
		private var bg:Shape = new Shape();
		private var prevSplineCount:int = -1;
		private var playhead:Shape = new Shape();
		private var prevtime:Number;
		private var label:Label;
		public static var currentTime:Number = 0;
		public static var speed:Number = 1;
		public static var timelineRange:Number = 10;
		public function Timeline(sd:SharedData) 
		{
			this.sd = sd;
			sd.changed.add(onSplineCountChanged);
			addChild(bg);
			addChild(lineContainer);
			addChild(playhead);
			label = new Label(this, 0, 0, "Range: 0 -> " + timelineRange+"s");
			playhead.graphics.beginFill(0);
			playhead.graphics.drawRect( -1, 0, 2, 80);
			playhead.blendMode = BlendMode.INVERT;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			prevtime = getTimer();
		}
		
		private function onEnterFrame(e:Event):void 
		{
			var delta:Number = (getTimer() - prevtime) / 1000;
			prevtime = getTimer();
			currentTime += delta*speed;
			if (currentTime > timelineRange) currentTime = 0;
			playhead.x = 20+(currentTime/timelineRange) * (stage.stageWidth - 40);
		}
		
		private function onSplineCountChanged():void 
		{
			if (prevSplineCount == sd.splineLength) return;
			prevSplineCount = sd.splineLength;
			lineContainer.removeChildren();
			lines = new Vector.<TimelineBar>();
			if (sd.currentSpline == null) return;
			var pt:SplinePoint = sd.currentSpline;
			addBar(pt).mouseEnabled = false;
			while (pt.hasNext()) {
				pt = pt.next;
				addBar(pt);
			}
			resize();
		}
		
		private function addBar(pt:SplinePoint):TimelineBar 
		{
			var w:Number = (stage.stageWidth-40) / (sd.splineLength-1);
			var bar:TimelineBar = new TimelineBar(this, pt);
			lineContainer.addChild(bar);
			bar.resize();
			bar.x = bar.pt.time * w;
			return bar;
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			resize();
		}
		
		
		public function resize():void 
		{
			var w:Number = (stage.stageWidth-40) / (sd.splineLength-1);
			for each(var bar:TimelineBar in lines) {
				bar.resize();
				bar.x = (bar.pt.time / timelineRange) * w;
			}
			lineContainer.graphics.clear();
			lineContainer.graphics.beginFill(0x808080);
			lineContainer.graphics.drawRect(0, 0, stage.stageWidth-40, 10);
			lineContainer.graphics.endFill();
			lineContainer.y = 30;
			lineContainer.x = 20;
			bg.graphics.clear();
			bg.graphics.beginFill(0x222222);
			bg.graphics.drawRect(0, 0, stage.stageWidth, 80);
			x = 0;
			y = stage.stageHeight - 80;
		}
		
	}

}