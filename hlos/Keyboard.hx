package hlos;

typedef KeybLayout = {
	var keys : String;
	var shifts : String;
}

class Keyboard {

	public static final QWERTY : KeybLayout = {
		keys : "  1234567890-=  qwertyuiop[]  asdfghjkl;'` \\zxcvbnm,./ * ",
		shifts : "  1234567890-=  QWERTYUIOP[]  ASDFGHJKL;'` \\ZXCVBNM,./ * ",
	};

	public static final AZERTY : KeybLayout = {
		keys : "  &é\"'(-è_çà)=  azertyuiop $  qsdfghjklmù  *wxcvbn,;:! ",
		shifts : "  1234567890°+  AZERTYUIOP £  QSDFGHJKLM%  µWXCVBN?./§ ",
	};

	public static var LAYOUT = QWERTY;

	static var SHIFT_DOWN = 0;

	public static inline var K_ESCAPE = 1;
	public static inline var K_BACK = 14;
	public static inline var K_TAB = 15;
	public static inline var K_SPACE = 57;
	public static inline var K_ENTER = 28;
	public static inline var K_NUM_MULT = 55;
	public static inline var K_NUM_MINUS = 74;
	public static inline var K_NUM_ADD = 78;
	public static inline var K_NUM7 = 71;
	public static inline var K_NUM8 = 72;
	public static inline var K_NUM9 = 73;
	public static inline var K_NUM4 = 75;
	public static inline var K_NUM5 = 76;
	public static inline var K_NUM6 = 77;
	public static inline var K_NUM1 = 79;
	public static inline var K_NUM2 = 80;
	public static inline var K_NUM3 = 81;
	public static inline var K_NUM0 = 82;
	public static inline var K_NUMDOT = 83;

	public static inline var LSHIFT = 42;
	public static inline var RSHIFT = 54;

	public static var KEYS = [
		K_BACK => 8, // backspace
		K_TAB => '\t'.code,
		K_SPACE => ' '.code,
		K_ENTER => '\n'.code,
		K_NUM_MULT => '*'.code,
		K_NUM_MINUS => '-'.code,
		K_NUM_ADD => '+'.code,
		K_NUM0 => '0'.code,
		K_NUM1 => '1'.code,
		K_NUM2 => '2'.code,
		K_NUM3 => '3'.code,
		K_NUM4 => '4'.code,
		K_NUM5 => '5'.code,
		K_NUM6 => '6'.code,
		K_NUM7 => '7'.code,
		K_NUM8 => '8'.code,
		K_NUM9 => '9'.code,
		K_NUMDOT => '.'.code,
	];

	static var KEY_DOWNS = [];

	static function onIRQ() {
		var scan = Bios.inb(0x60);
		if( scan >= 128 ) {
			// TODO : handle extended keys encoded on two bytes
			scan &= 0x7F;
			if( scan == LSHIFT ) SHIFT_DOWN &= ~1;
			if( scan == RSHIFT ) SHIFT_DOWN &= ~2;
			return;
		}
		if( scan == LSHIFT ) SHIFT_DOWN |= 1;
		if( scan == RSHIFT ) SHIFT_DOWN |= 2;
		var key : Int = (SHIFT_DOWN != 0 ? LAYOUT.shifts : LAYOUT.keys).charCodeAt(scan);
		if( key == ' '.code ) key = 0;
		if( key == 0 )
			key = KEYS.get(scan);
		onKey(scan,key);
	}

	public dynamic static function onKey( scan : Int, key : Int ) {
		if( key != 0 ) Sys.print(String.fromCharCode(key));
	}

	public static function init() {
		Interrupts.setIRQHandler(Keyboard, onIRQ);
		Interrupts.installHandlers();
	}

}