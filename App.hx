import hlos.*;

class App {

	static function main() {
		Keyboard.init();
		//Keyboard.LAYOUT = Keyboard.AZERTY;
		Sys.println("Hello");
		//Interrupts.setIRQHandler(Timer, () -> Sys.print("."));
		//Interrupts.setTimer(1000);
		while( true ) {}
	}

}