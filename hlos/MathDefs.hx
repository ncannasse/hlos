package hlos;

@:keep class MathDefs {

	static function cos(v:Float) {
		throw "Not implemented";
	}

	static function init() {
		// nothing (perform in __init__ so static vars can use defs)
	}

	static function __init__() {
		Kernel.defineFunction("std", "math_cos", cos);
	}

}