package hlos;

class Mouse {

	static function waitWrite() {
		// wait until we can write data to 0x60 or 0x64
		while(true) {
			var v = Bios.inb(0x64);
			if( v & 2 == 0 ) break;
		}
	}

	static function waitRead() {
		// wait until we can read data from 0x60
		while(true) {
			var v = Bios.inb(0x64);
			if( v & 1 == 1 ) break;
		}
	}

	static function mouseWrite( cmd : Int ) {
		waitWrite();
		Bios.outb(0x64, 0xD4); // mouse command
		waitWrite();
		Bios.outb(0x60, cmd); // mouse command
	}

	static function mouseRead() {
		waitRead();
		return Bios.inb(0x60);
	}

	public static var currentButtons : Int;

	public static dynamic function onMouseButton( b : Int, down : Bool ) {
		trace("Mouse Button "+b+" = "+down);
	}

	public static dynamic function onMouseMove( dx : Int, dy : Int ) {
		trace("Mouse move "+dx+","+dy);
	}

	public static function init() {
		// disable until init finished : we don't want our init to trigger
		// irqs that will do port read
		var prev = Interrupts.setIRQHandler(Keyboard, function() {});
		Interrupts.setIRQHandler(Mouse, function() {});

		waitWrite();
		Bios.outb(0x64, 0xA8); // enable port
		waitWrite();
		Bios.outb(0x64, 0x20); // get status

		var st = mouseRead(); // status value
		st |= 2; // enable irq12

		waitWrite();
		Bios.outb(0x64, 0x60); // set status
		waitWrite();
		Bios.outb(0x60, st);

		mouseWrite(0xF6); // default settings
		mouseRead();

		mouseWrite(0xF4); // send packets
		mouseRead();

		var bytes = haxe.io.Bytes.alloc(3);
		var bindex = 0;
		Interrupts.setIRQHandler(Mouse, function() {
			var b = Bios.inb(0x60);
			bytes.set(bindex++, b);
			if( bindex == 3 ) {
				bindex = 0;
				var buttons = bytes.get(0) & 7;
				if( buttons != currentButtons ) {
					for( i in 0...3 ) {
						var mask = 1 << i;
						if( (buttons & mask) != (currentButtons & mask) ) {
							var down = buttons & mask != 0;
							if( down )
								currentButtons |= mask;
							else
								currentButtons &= ~mask;
							onMouseButton(i, down);
						}
					}
				}
				if( bytes.get(1) != 0 || bytes.get(2) != 0 ) {
					var dx = bytes.get(1);
					var dy = bytes.get(2);
					if( dx >= 0x80 ) dx -= 256;
					if( dy >= 0x80 ) dy -= 256;
					onMouseMove(dx, -dy);
				}
			}
		});

		Interrupts.setIRQHandler(Keyboard, prev); // restore
	}

}