package no.doomsday.games.tools.pathtool.timeline 
{
	import com.bit101.components.Label;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import no.doomsday.games.tools.pathtool.data.SplinePoint;
	import no.doomsday.games.tools.pathtool.IResizable;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class TimelineBar extends Sprite implements IResizable
	{
		private var line:Shape;
		public var pt:SplinePoint;
		private var timeline:Timeline;
		
		public function TimelineBar(timeline:Timeline, pt:SplinePoint) 
		{
			this.timeline = timeline;
			this.pt = pt;
			line = new Shape();
			addChild(line);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			buttonMode = true;
			
		}
		
		private function onMouseDown(e:MouseEvent):void 
		{
			timeline.sd.deselectAll();
			pt.selected = true;
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		private function onMouseUp(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		}
		
		private function onMouseMove(e:MouseEvent):void 
		{
			pt.time = Math.max(0, (parent.mouseX) / (stage.stageWidth - 40)) * Timeline.timelineRange;
			timeline.sd.consolidate();
			timeline.sd.updatePath();
		}
		
		private function onAddedToStage(e:Event):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			resize();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		private function onRemovedFromStage(e:Event):void 
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(e:Event):void 
		{
			if (pt.selected) {
				line.graphics.clear();
				line.graphics.beginFill(0x00FF00);
				line.graphics.drawRect(-2.5, 0, 5, 10);
				line.graphics.endFill();
			}else {
				line.graphics.clear();
				line.graphics.beginFill(0xFF0000);
				line.graphics.drawRect(-2.5, 0, 5, 10);
				line.graphics.endFill();
			}
			var w:Number = stage.stageWidth - 40;
			x = (pt.time / Timeline.timelineRange) * w;
		}
		
		public function resize():void 
		{
		}
		
	}

}