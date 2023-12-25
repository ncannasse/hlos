package hlos;
import hlos.Asm.*;

class Bios {

	public static macro function interrupt( id : Int ) {
		return macro {
			$asm(0,0xCD);
			$asm(0,$v{id});
		};
	}

	#if !macro

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
