
function main() {
	/**
		Extract symbol table and functions addresses from our ELF executable.
		This could be done by binary reader but is faster for now to use objdump
	**/
	var args = Sys.args();
	var elfFile = args[0];
	var outFile = args[1];
	var objdump = Sys.getEnv("OBJDUMP");
	var lines = new sys.io.Process(objdump,["-t", elfFile]).stdout.readAll().toString().split("\n");
	var r_line = ~/^([0-9A-Fa-f]+) g +F \.text[ \t]+[0-9A-Fa-f]+[ \t]+([A-Za-z0-9_]+)\r?$/;
	var out = new haxe.io.BytesBuffer();
	out.addString("SYM_TBL_BEGIN");
	var all = [];
	for( l in lines )
		if( r_line.match(l) ) {
			var addr = Std.parseInt("0x"+r_line.matched(1));
			var name = r_line.matched(2);
			all.push({name:name, addr:addr});
		}
	all.sort(function(s1,s2) return s1.addr - s2.addr);
	for( s in all ) {
		out.addString(s.name);
		out.addInt32(s.addr);
	}
	out.addString("SYM_TBL_END");
	while( out.length % 512 != 0 )
		out.addByte(0xFF);
	sys.io.File.saveBytes(outFile, out.getBytes());
}