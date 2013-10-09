package no.doomsday.games.tools.pathtool 
{
	import flash.geom.Rectangle;
	import no.doomsday.games.tools.pathtool.data.SplinePoint;
	import no.doomsday.games.tools.pathtool.export.Path;
	import org.osflash.signals.Signal;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class SharedData 
	{
		public static var instance:SharedData;
		private var _gameBounds:Rectangle = new Rectangle(0, 0, 960, 640);
		private var _gridWidth:int = 8;
		private var _gridHeight:int = 8;
		private var _gridEnabled:Boolean = false;
		private var _currentSpline:SplinePoint = null;
		private var _undoStack:Vector.<SplinePoint> = new Vector.<SplinePoint>();
		public const changed:Signal = new Signal();
		public const splineLoaded:Signal = new Signal();
		public var lastPathGenerated:Path = null;
		
		public function SharedData() {
			if (instance == null) {
				instance = this;
			}
		}
		
		public function get gameBounds():Rectangle 
		{
			return _gameBounds;
		}
		
		public function set gameBounds(value:Rectangle):void 
		{
			_gameBounds = value;
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
		
		public function get currentSpline():SplinePoint 
		{
			return _currentSpline;
		}
		
		public function set currentSpline(value:SplinePoint):void 
		{
			_currentSpline = value;
			setDirty();
		}
		public function clearHistory():void {
			_undoStack = new Vector.<SplinePoint>();
		}
		public function addUndoLevel():void {
			if (_currentSpline != null) {
				_undoStack.push(_currentSpline.makeCopy());
			}
		}
		public function get undoStack():Vector.<SplinePoint> 
		{
			return _undoStack;
		}
		
		public function setDirty():void 
		{
			lastPathGenerated = generatePath();
			changed.dispatch();
		}
		
		public function get splineLength():int {
			if (_currentSpline == null) return 0;
			var n:SplinePoint = _currentSpline;
			var count:int = 1;
			while (n.hasNext()) {
				count++;
				n = n.next;
			}
			return count;
		}
		public function deselectAll():void 
		{
			if (currentSpline == null) return;
			var n:SplinePoint = currentSpline;
			n.selected = false;
			while (n.hasNext()) {
				n = n.next;
				n.selected = false;
			}
		}
		
		public function nextTime():Number {
			if(!lastPathGenerated) updatePath();
			if (lastPathGenerated.points.length == 0) {
				return 0;
			}
			return lastPathGenerated.maxT + 0.25;
		}
		
		public function updatePath():void {
			lastPathGenerated = generatePath();
		}
		public function generatePath():Path {
			var p:Path = new Path();
			if (_currentSpline == null) return p;
			var n:SplinePoint = _currentSpline;
			n.calcAngle();
			p.addPoint(n.x, n.y, n.time, n.angleToNext);
			while (n.hasNext()) {
				n = n.next;
				n.calcAngle();
				p.addPoint(n.x, n.y, n.time,n.angleToNext);
			}
			return p;
		}
		
		public function consolidate():void 
		{
			if (currentSpline == null) return;
			var n:SplinePoint = currentSpline;
			while (n.hasNext()) {
				if (n.time > n.next.time) {
					n.time = n.next.time;
				}
				n = n.next;
			}
		}
		
		public function deserialize(s:String):void 
		{
			var spline:Object = JSON.parse(s);
			clearHistory();
			var node:SplinePoint = _currentSpline = new SplinePoint();
			for (var i:int = 0; i < spline.points.length; i++) {
				var p:Object = spline.points[i];
				if (i == 0) {
					node.time = p.time;
					node.angleToNext = p.angle;
					node.x = p.x;
					node.y = p.y;
				}else {
					node = node.append(new SplinePoint());
					node.time = p.time;
					node.angleToNext = p.angle;
					node.x = p.x;
					node.y = p.y;
				}
			}
			splineLoaded.dispatch();
			setDirty();
		}
		
		public function serialize():String 
		{
			return lastPathGenerated.serialize();
		}
		
	}

}