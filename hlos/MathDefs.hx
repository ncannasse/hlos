package hlos;

@:keep class MathDefs {

	static function cos(v:Float) {
		throw "Not implemented";
	}

	static function __init__() {
		Kernel.defineFunction("std", "math_cos", cos);
	}

}