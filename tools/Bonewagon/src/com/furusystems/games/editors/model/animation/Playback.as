package com.furusystems.games.editors.model.animation 
{
	import com.furusystems.dconsole2.DConsole;
	import com.furusystems.games.editors.model.SharedModel;
	/**
	 * ...
	 * @author Andreas Rønning
	 */
	public class Playback 
	{
		
		public var currentAnimation:Animation = null;
		public var time:Number = 0;
		private var _selectedKey:SRT = null;
		public function Playback() 
		{
			DConsole.createCommand("play", play);
			DConsole.createCommand("stop", stop);
		}
		
		
		public function stop():void 
		{
			
		}
		
		public function play():void 
		{
			
		}
		
		
		public function applyAnimations(timeSeconds:Number):void 
		{
			//list valid animations
			//var animations:Vector.<Animation> = new Vector.<Animation>();
			//SharedModel.basePose.apply(0, false);
			currentAnimation.apply(timeSeconds,true);
			
			//SharedModel.playback.currentAnimation.apply(timeSeconds, true);
		}
		
		public function get selectedKey():SRT 
		{
			return _selectedKey;
		}
		
		public function set selectedKey(value:SRT):void 
		{
			if (_selectedKey != null) _selectedKey.selected = false;
			_selectedKey = value;
			if (_selectedKey != null) _selectedKey.selected = true;
		}
		
	}

}