package hlos;
import hlos.Asm.*;

#if !macro
@:struct class Regs16 {
	public var di : hl.UI16;
	public var si : hl.UI16;
	public var bp : hl.UI16;
	public var sp : hl.UI16;
	public var bx : hl.UI16;
	public var dx : hl.UI16;
	public var cx : hl.UI16;
	public var ax : hl.UI16;
	public var gs : hl.UI16;
	public var fs : hl.UI16;
	public var es : hl.UI16;
	public var ds : hl.UI16;
	public var eflags : hl.UI16;
	public function new() {
	}
}
#end

class Bios {

	#if !macro

	@:hlNative("std", "int32") public static function interrupt( id : Int, regs : Regs16 ) : Void {
	}

	public static function inb( port : Int ) {
		var value = 0;
		set(Edx, port);
		untyped $asm(0,0xEC);
		set(value, Eax);
		return value & 0xFF;
	}

	public static function outb( port : Int, value : Int ) {
		set(Edx, port);
		set(Eax, value);
		untyped $asm(0,0xEE);
	}

	#end

}
