package hlos;

@:struct class IdtEntry {
	public var lowOffset : hl.UI16;
	public var sel : hl.UI16;
	public var reserved : hl.UI8;
	public var flags : hl.UI8;
	public var highOffset : hl.UI16;
}

typedef IdtRegister = Kernel.GdtRegister;

enum IRQ {
	Timer;
	Keyboard;
}

@:build(hlos.Macros.duplicateFunctions())
class Interrupts {

	static var reg = new IdtRegister();
	static var idt : hl.CArray<IdtEntry>;

	static var irq_callbacks : Array<Void->Void> = [];
	static var ISR_HANDLERS = 32;
	static var IRQ_HANDLERS = 16;
	static var NAMES = [
		"Division By Zero",
		"Debug",
		"Non Maskable Interrupt",
		"Breakpoint",
		"Into Detected Overflow",
		"Out of Bounds",
		"Invalid Opcode",
		"No Coprocessor",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Bad TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection Fault",
		"Page Fault",
		"Unknown Interrupt",
		"Coprocessor Fault",
		"Alignment Check",
		"Machine Check",
	];

	static var IRQ_NAMES = IRQ.getConstructors();

	@:dup(48) static function handler__ID__() {
		Asm.setNakedFunction();
		Asm.emit(Pusha);
		Asm.set(Esi, __ID__);
		handleInterrupt();
		Asm.emit(Popa);
		Asm.emit(IRet);
	}

	static function handleInterrupt() {
		var int = 0;
		Asm.set(int, Esi);
		if( int >= ISR_HANDLERS ) {
			var irq = int - ISR_HANDLERS;
			if( irq >= 8 ) Bios.outb(0xA0, 0x20);
			Bios.outb(0x20, 0x20);
			if( irq_callbacks[irq] != null )
				irq_callbacks[irq]();
			else
				Sys.println('*** IRQ [${IRQ_NAMES[irq] ?? "#"+irq}] ***');
		} else {
			Sys.println('*** INTERUPT [${NAMES[int] ?? "#"+int}] ***');
		}
	}

	public static function setIRQHandler( irq : IRQ, callb : Void -> Void ) {
		irq_callbacks[irq.getIndex()] = callb;
	}

	public static function setTimer( freq : Int ) {
		var div = Std.int(1193180 / freq);
		Bios.outb(0x43, 0x36);
		Bios.outb(0x40, div);
		Bios.outb(0x40, div >> 8);
	}

	static var INSTALLED = false;

	public static function installHandlers() {
		if( INSTALLED ) return;
		INSTALLED = true;

		var count = 256;
		idt = hl.CArray.alloc(IdtEntry,count);
		for( i in 0...256 ) {
			var f = Reflect.field(Interrupts,"handler"+i) ?? handler0;
			var handlerPtr = Asm.getFunctionPtr(f);
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

		// remap the PIC to trigger interrupts
		Bios.outb(0x20, 0x11);
		Bios.outb(0xA0, 0x11);
		Bios.outb(0x21, 0x20);
		Bios.outb(0xA1, 0x28);
		Bios.outb(0x21, 0x04);
		Bios.outb(0xA1, 0x02);
		Bios.outb(0x21, 0x01);
		Bios.outb(0xA1, 0x01);
		Bios.outb(0x21, 0x0);
		Bios.outb(0xA1, 0x0);

		if( irq_callbacks[Timer.getIndex()] == null )
			setIRQHandler(Timer, function() {}); // ignore default timer

		// enable interrupts
		Asm.emit(Sti);
	}

	static function setIDT() {
		Asm.set(Eax, reg);
		// LIDT [EAX]
		untyped $asm(0, 0x0F);
		untyped $asm(0, 0x01);
		untyped $asm(0, 0x18);
	}

}