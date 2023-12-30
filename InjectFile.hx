
function main() {
	/**
		Inject or replace a file inside the ELF kernel file data section.
		Usage :
			haxe --run InjectFile [-path srcPath] <kernel-file> <files to add..>
	**/
	var args = Sys.args();
	var path = ".";
	while( args[0].charAt(0) == "-" )
		switch( args.shift() ) {
		case "-path":
			path = args.shift();
		case arg:
			throw "Unknown argument "+arg;
		}
	var elfFile = args.shift();
	var elfData = sys.io.File.getBytes(elfFile);
	// load file data
	var head = haxe.io.Bytes.ofString("KFILES_BEGIN");
	var CHK = 0xBAD0CAFE;
	var files = null;
	for( i in 0...elfData.length - head.length ) {
		if( elfData.get(i) != 'K'.code ) continue;
		var found = true;
		for( k in 0...head.length )
			if( elfData.get(i+k) != head.get(k) ) {
				found = false;
				break;
			}
		if( !found ) continue;
		var input = new haxe.io.BytesInput(elfData, i + head.length);
		files = {
			position : i,
			size : input.readInt32(),
			data : [],
		};
		if( files.size < 0 || i + files.size > elfData.length || elfData.getInt32(i+files.size-4) != CHK ) {
			files = null;
			continue;
		}
		while( true ) {
			var name = input.readUntil(0);
			if( name == "" ) break;
			var size = input.readInt32();
			var data = input.read(size);
			files.data.push({ name: name, data : data });
		}
	}
	if( files == null )
		throw "Couldn't locate kernel files section in "+elfFile;
	// add or replace files
	for( inFile in args ) {
		var data = sys.io.File.getBytes(path+"/"+inFile);
		var found = false;
		for( f in files.data )
			if( f.name == inFile ) {
				f.data = data;
				found = true;
				break;
			}
		if( !found )
			files.data.push({
				name : inFile,
				data : data,
			});
	}
	// build
	var out = new haxe.io.BytesOutput();
	out.writeString("KFILES_BEGIN");
	out.writeInt32(files.size);
	for( f in files.data ) {
		out.writeString(f.name);
		out.writeByte(0);
		out.writeInt32(f.data.length);
		out.write(f.data);
	}
	while( out.length < files.size - 4 )
		out.writeByte(0);
	out.writeInt32(CHK);
	var out = out.getBytes();
	if( out.length != files.size )
		throw "Could not save files, too much data "+out.length+" (max : "+files.size+")";
	// save
	elfData.blit(files.position, out, 0, out.length);
	sys.io.File.saveBytes(elfFile, elfData);
}
