package hlos;

@:struct class GdtSegment {
	public var length : hl.UI16;
	public var base : hl.UI16;
	public var baseLow : hl.UI8;
	public var flags1 : hl.UI8;
	public var flags2 : hl.UI8;
	public var baseAddr : hl.UI8;
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

	static function installGDT() {
		gdt.code.length = 0xFFFF;
		gdt.data.length = 0xFFFF;
		gdt.code.flags1 = 0x9A;
		gdt.data.flags1 = 0x9A;
		gdt.code.flags2 = 0xCF;
		gdt.data.flags2 = 0xCF;
		var gaddr = Asm.getValuePtr(gdt);
		reg.length = 23;
		reg.baseHigh = gaddr >>> 16;
		reg.baseLow = gaddr & 0xFFFF;
		setGDT();
		return true;
	}

	static function setGDT() {
		Asm.set(Eax, reg);
		// LGDT [EAX]
		untyped $asm(0, 0x0F);
		untyped $asm(0, 0x01);
		untyped $asm(0, 0x10);
	}

	@:keep static var _ = installGDT();

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

