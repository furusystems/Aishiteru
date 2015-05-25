package bonewagon.model.animation;
import bonewagon.model.SharedModel;
/**
 * ...
 * @author Andreas Rønning
 */
class Playback 
{
	
	public var currentAnimation:Animation = null;
	public var time:Float = 0;
	var _selectedKey:SRT = null;
	
	public function new() 
	{
	}
	
	
	public function stop() 
	{
		
	}
	
	public function play() 
	{
		
	}
	
	
	public function applyAnimations(timeSeconds:Float) 
	{
		if (currentAnimation == null) return;
		//list valid animations
		//var animations:Array<Animation> = new Array<Animation>();
		//SharedModel.basePose.apply(0, false);
		currentAnimation.apply(timeSeconds,true);
		
		//SharedModel.playback.currentAnimation.apply(timeSeconds, true);
	}
	
	public var selectedKey(get, set):SRT;
	
	public function get_selectedKey():SRT 
	{
		return _selectedKey;
	}
	
	public function set_selectedKey(value:SRT) 
	{
		if (_selectedKey != null) _selectedKey.selected = false;
		_selectedKey = value;
		if (_selectedKey != null) _selectedKey.selected = true;
		return _selectedKey;
	}
	
}