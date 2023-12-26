import hlos.*;


class App {

	static function main() {
		Keyboard.init();
		Vga.setMode13();
		Vga.clear(1);
		for( x in 0...320 )
			Vga.setPixel(x,5,x);
		var mode = true;
		Keyboard.onKey = function(scan,_) {
			if( scan == Keyboard.K_ESCAPE ) {
				mode = !mode;
				if( mode ) {
					Vga.setMode13();
					Vga.clear(1);
				} else {
					Vga.setModeText();
					trace("Switching back to text mode");
				}
			}
		};
	}

}