package hlos;

class Kernel {

	/**
		Load a file that was added to the kernel data using `InjectFile.hx` script.
	**/
	public static function loadFile( path : String ) {
		var size = 0;
		var data = load_kernel_file(@:privateAccess path.toUtf8(), size);
		if( data == null )
			return null;
		return @:privateAccess new haxe.io.Bytes(data, size);
	}

	@:hlNative("std") static function load_kernel_file( path : hl.Bytes, size : hl.Ref<Int> ) : hl.Bytes {
		return null;
	}

}

