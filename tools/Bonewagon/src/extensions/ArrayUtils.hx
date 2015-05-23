package extensions;
using Lambda;
/**
 * ...
 * @author Andreas Rønning
 */
class ArrayUtils
{

	public static function pushTwo(a:Array<Float>, first:Float, second:Float) {
		a.push(first);
		a.push(second);
	}
	
	public static function single<T>( set : Iterable<T>, predicate:T -> Bool) : T {
		for (i in set) {
			if(predicate(i)) return i;
		}
		return null;
	}
	
}