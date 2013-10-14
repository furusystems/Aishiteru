package com.furusystems.aishiteru.data;

/**
 * ...
 * @author Andreas Rønning
 */
interface ISerializable<T>
{
	function serialize():T;
	function deserialize(data:T):Void;
}