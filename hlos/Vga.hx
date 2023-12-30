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

	public static final WIDTH = 320;
	public static final HEIGHT = 200;
	public static var VGA_GFXMEM = hl.Bytes.fromAddress(haxe.Int64.make(0,0xA0000));

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

	public static function setMode13() {
		var regs = new Bios.Regs16();
		regs.ax = 0x13;
		Bios.interrupt(0x10, regs);
	}

	public static function setModeText() {
		var regs = new Bios.Regs16();
		regs.ax = 0x2;
		Bios.interrupt(0x10, regs);
	}

	public static function clear( color : Int ) {
		VGA_GFXMEM.fill(0, WIDTH * HEIGHT, color);
	}

	public static function setPixel( x : Int, y : Int, color : Int ) {
		VGA_GFXMEM.setUI8(x+y*WIDTH, color);
	}

	public static function getPixel( x : Int, y : Int ) {
		return VGA_GFXMEM.getUI8(x+y*WIDTH);
	}

	public static function setPalette( index : Int, color : Int ) {
		Bios.outb(0x3C8, index);
		Bios.outb(0x3C9, (((color >> 16) & 0xFF) + 3) >> 2);
		Bios.outb(0x3C9, (((color >> 8) & 0xFF) + 3) >> 2);
		Bios.outb(0x3C9, ((color & 0xFF) + 3) >> 2);
	}

	public static function getPalette( index : Int ) {
		Bios.outb(0x3C7, index);
		var r = Bios.inb(0x3C9);
		var g = Bios.inb(0x3C9);
		var b = Bios.inb(0x3C9);
		return (r << 18) | (g << 10) | (b << 2);
	}

}