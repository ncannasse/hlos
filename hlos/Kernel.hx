package hlos;

private typedef ForceImport = {
	var m : MathDefs;
}

@:struct class GdtSegment {
	public var limit : hl.UI16;
	public var base : hl.UI16;
	public var baseHigh : hl.UI8;
	public var access : hl.UI8;
	public var flagsLimit : hl.UI8; // 4 bits for limit high bits + 4 bits access
	public var baseHigh2 : hl.UI8;

	public function set( base : Int, limit : Int, access : Int, flags : Int ) {
		this.limit = limit & 0xFFFF;
		this.access = access;
		this.flagsLimit = (flags << 4) | ((limit >>> 16) & 15);
		this.base = base & 0xFFFF;
		this.baseHigh = base >>> 16;
		this.baseHigh2 = base >>> 24;
	}
}

@:struct class GdtEntry {
	public var start : Int;
	public var end : Int;
	@:packed public var code : GdtSegment;
	@:packed public var data : GdtSegment;
	public function new() {
	}
}

@:struct class GdtRegister {
	public var length : hl.UI16;
	public var baseLow : hl.UI16;
	public var baseHigh : hl.UI16;
	public function new() {
	}
}

class Kernel {

	static var reg = new GdtRegister();
	static var gdt = new GdtEntry();
	static var INSTALLED = false;

	public static function installGDT() {
		if( INSTALLED ) return;
		INSTALLED = true;
		gdt.code.set(0, 0xFFFFF, 0x9A, 0xC);
		gdt.data.set(0, 0xFFFFF, 0x9A, 0xC);
		var gaddr = Asm.getValuePtr(gdt);
		reg.length = 23;
		reg.baseHigh = gaddr >>> 16;
		reg.baseLow = gaddr & 0xFFFF;
		setGDT();
	}

	static function setGDT() {
		Asm.set(Eax, reg);
		// LGDT [EAX]
		untyped $asm(0, 0x0F);
		untyped $asm(0, 0x01);
		untyped $asm(0, 0x10);
	}

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

	/**
		In HLOS, native functions are all allowed but unknown ones will trigger a kernel panic error when called at runtime.
		Use this function to define a native function using a pure Haxe implementation before it is called.
	**/
	public static function defineFunction( lib : String, name : String, f : haxe.Constraints.Function ) {
		return define_function(@:privateAccess lib.toUtf8(), @:privateAccess name.toUtf8(), f);
	}

	@:hlNative("std") static function load_kernel_file( path : hl.Bytes, size : hl.Ref<Int> ) : hl.Bytes {
		return null;
	}

	@:hlNative("std") static function define_function( lib : hl.Bytes, name : hl.Bytes, f : Dynamic ) : Bool {
		return false;
	}

	@:hlNative("std","kprint_regs") public static function printRegs() : Void {
	}

}

