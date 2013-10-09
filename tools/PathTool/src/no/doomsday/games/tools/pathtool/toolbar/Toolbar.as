package no.doomsday.games.tools.pathtool.toolbar 
{
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.bit101.components.VBox;
	import com.bit101.components.VRangeSlider;
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import no.doomsday.games.tools.pathtool.canvas.Canvas;
	import no.doomsday.games.tools.pathtool.data.SplinePoint;
	import no.doomsday.games.tools.pathtool.IResizable;
	import no.doomsday.games.tools.pathtool.SharedData;
	import no.doomsday.games.tools.pathtool.splines.Interpolator;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Toolbar extends Sprite implements IResizable
	{
		
		private var _canvas:Canvas;
		private var widthSelector:NumericStepper;
		private var heightSelector:NumericStepper;
		
		public const LINEAR:int = 0;
		public const CUBIC_CURVE:int = 1;
		
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
		
		public function Toolbar(model:SharedData) 
		{
			_model = model;
			
			loadFileRef = new FileReference();
			loadFileRef.addEventListener(Event.COMPLETE, onFileLoaded, false, 0, true);
			loadFileRef.addEventListener(Event.SELECT, onFileSelected);
			
			//gamesize
			var vbox:VBox = new VBox(this, 10, 10);
			addChild(vbox);
			
			var label:Label = new Label(vbox, 0, 0, "Screen bounds");
			widthSelector = new NumericStepper(vbox, 0,0, onGameDimChange);
			heightSelector = new NumericStepper(vbox, 0, 0, onGameDimChange);
			widthSelector.value = _model.gameBounds.width;
			heightSelector.value = _model.gameBounds.height;
			
			label = new Label(vbox, 0, 0, "Canvas");
			gridToggle = new PushButton(vbox, 0, 0, "Grid toggle", onGridToggle);
			gridCellHeightSelector = new NumericStepper(vbox, 0, 0, onGridDimChange);
			gridCellHeightSelector.value = _model.gridRows;
			gridCellWidthSelector = new NumericStepper(vbox, 0, 0, onGridDimChange);
			gridCellWidthSelector.value = _model.gridColumns;
			
			label = new Label(vbox, 0, 0, "File");
			saveButton = new PushButton(vbox, 0, 0, "Save", save);
			saveButton = new PushButton(vbox, 0, 0, "To clipboard", clipboard);
			loadButton= new PushButton(vbox, 0, 0, "Load", load);
			saveButton = new PushButton(vbox, 0, 0, "From clipboard", fromClipboard);
			
			label = new Label(vbox, 0, 0, "Misc");
			undoButton= new PushButton(vbox, 0, 0, "Undo", onUndo);
			loadButton= new PushButton(vbox, 0, 0, "Clear", clear);
		}
		
		private function fromClipboard(e:Event):void 
		{
			_model.deserialize(String(Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT)));
		}
		
		private function clipboard(e:Event):void 
		{
			Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, _model.serialize(),false);
		}
		
		private function interpolate(...args:Array):void 
		{
			if (_model.currentSpline != null) {
				_model.currentSpline = Interpolator.interpolate(_model.currentSpline, curveResolutionStepper.value);
			}
		}
		
		private function onCurveResolutionChange(...args:Array):void 
		{
			
		}
		
		private function onUndo(...args:Array):void 
		{
			if (_model.undoStack.length > 0) {
				_model.currentSpline = _model.undoStack.pop();
				_model.splineLoaded.dispatch();
			}
		}
		
		
		private function clear(...args:Array):void 
		{
			_model.currentSpline = null;
			_model.splineLoaded.dispatch();
		}
		
		private function onFileSelected(e:Event):void 
		{
			loadFileRef.load();
		}
		
		private function load(...args:Array):void 
		{
			loadFileRef.browse([new FileFilter("path json", "*.txt")]);
		}
		
		private function onFileLoaded(e:Event):void 
		{
			var data:ByteArray = loadFileRef.data;
			_lastLoadedSpline = data.readUTFBytes(data.bytesAvailable);
			_model.deserialize(_lastLoadedSpline);
		}
		
		private function save(...args:Array):void 
		{
			_model.clearHistory();
			if (_model.currentSpline != null) {
				var f:FileReference = new FileReference();
				f.save(_model.serialize(), "path.txt");
			}
		}
		
		private function onGridDimChange(...args:Array):void 
		{
			_model.gridRows = gridCellHeightSelector.value;
			_model.gridColumns = gridCellWidthSelector.value;
		}
		
		private function onGridToggle(...args:Array):void 
		{
			_model.gridEnabled = !_model.gridEnabled;
		}
		
		private function onGameDimChange(...args:Array):void 
		{
			_model.gameBounds.width = widthSelector.value;
			_model.gameBounds.height = heightSelector.value;
			_model.setDirty();
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
		
	}

}