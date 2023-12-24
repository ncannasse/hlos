package hlos;

@:struct class IdtEntry {
	public var lowOffset : hl.UI16;
	public var sel : hl.UI16;
	public var reserved : hl.UI8;
	public var flags : hl.UI8;
	public var highOffset : hl.UI16;
}

@:struct class IdtRegister {
	public var length : hl.UI16;
	public var baseLow : hl.UI16;
	public var baseHigh : hl.UI16;
	public function new() {
	}
}

class Interrupts {

	static var reg = new IdtRegister();
	static var idt : hl.CArray<IdtEntry>;

	static function handler() {
		Asm.pop(Ebp);
		Asm.emit(Cli);
		handleInterrupt(); // don't use local variables as this might add to ESP
		Asm.emit(Sti);
		Asm.emit(IRet);
	}

	static function handleInterrupt() {
		Sys.println("EXCEPTION !");
	}

	public static function installHandlers() {
		var count = 256;
		idt = hl.CArray.alloc(IdtEntry,count);
		var handlerPtr = Asm.getFunctionPtr(handler);
		for( i in 0...count ) {
			var e = idt[i];
			e.flags = 0x8E;
			e.sel = 0x08; // kernel data segment
			e.lowOffset = handlerPtr & 0xFFFF;
			e.highOffset = handlerPtr >>> 16;
		}

		var idtPtr = Asm.getValuePtr(idt);
		reg.length = count * 8 - 1;
		reg.baseHigh = idtPtr >>> 16;
		reg.baseLow = idtPtr & 0xFFFF;

		setIDT();
	}

	static function setIDT() {
		Asm.set(Eax, reg);
		// LIDT [EAX]
		untyped $asm(0, 0x0F);
		untyped $asm(0, 0x01);
		untyped $asm(0, 0x18);
	}

}