import hlos.*;


class App {

	static function main() {
		Kernel.init();
		Vga.setMode13();
		Vga.clear(1);
		for( x in 0...320 )
			Vga.setPixel(x,5,x);
		var mode = true;
		var color = 2;
		var mouseX = 160;
		var mouseY = 100;
		var under = Vga.getPixel(mouseX, mouseY);
		var draw = false;
		Mouse.onMouseButton = function(b,down) {
			if( b == 0 )
				draw = down;
			else if( down ) {
				if( b == 1 ) color++;
			}
			Mouse.onMouseMove(0,0);
		}
		Mouse.onMouseMove = function(dx,dy) {
			Vga.setPixel(mouseX, mouseY, under);
			mouseX += dx;
			mouseY += dy;
			if( mouseX < 0 ) mouseX = 0;
			if( mouseY < 0 ) mouseY = 0;
			if( mouseX >= 320 ) mouseX = 319;
			if( mouseY >= 200 ) mouseY = 199;
			if( draw )
				Vga.setPixel(mouseX, mouseY, color);
			under = Vga.getPixel(mouseX, mouseY);
			Vga.setPixel(mouseX, mouseY, color);
		};
		Mouse.onMouseMove(0,0);

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