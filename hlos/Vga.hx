package hlos;

class Vga {

	static final VGA_MEM = hl.Bytes.fromAddress(haxe.Int64.make(0,0xB8000));
	static final VGA_OP = 0x3d4;
	static final VGA_DATA = 0x3d5;
	static final VGA_CURSOR_POS_LOW = 15;
	static final VGA_CURSOR_POS_HIGH = 14;
	public static final ROWS = 25;
	public static final COLS = 80;
	public static var DEFAULT_COLOR = 0x7;

	public static function getCursor() {
		Bios.outb(VGA_OP, VGA_CURSOR_POS_HIGH);
		var position = Bios.inb(VGA_DATA);
		position <<= 8;
		Bios.outb(VGA_OP, VGA_CURSOR_POS_LOW);
		position += Bios.inb(VGA_DATA);
		return position;
	}

	public static function setCursor( position : Int ) {
		Bios.outb(VGA_OP, VGA_CURSOR_POS_HIGH);
		Bios.outb(VGA_DATA, position >> 8);
		Bios.outb(VGA_OP, VGA_CURSOR_POS_LOW);
		Bios.outb(VGA_DATA, position & 0xFF);
	}

	public static function setChar( position : Int, char : Int, ?color ) {
		VGA_MEM.setUI8(position << 1, char);
		VGA_MEM.setUI8((position<<1)|1, color ?? DEFAULT_COLOR);
	}

}