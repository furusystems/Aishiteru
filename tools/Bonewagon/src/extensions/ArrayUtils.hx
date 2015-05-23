package extensions;
import flash.Vector;
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
	
	public static function toVector<T>(a:Array<T>):Vector<T> {
		var out = new Vector<T>(a.length, true);
		for (i in 0...a.length)
			out[i] = a[i];
		return out;
	}
	
	public static function single<T>( set : Iterable<T>, predicate:T -> Bool) : T {
		for (i in set) {
			if(predicate(i)) return i;
		}
		return null;
	}
	
}