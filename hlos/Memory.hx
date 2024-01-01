package hlos;

@:struct class MemEntry {
	public var baseLow : Int;
	public var baseHigh : Int;
	public var lengthLow : Int;
	public var lengthHigh : Int;
	public var type : Int;
	public var acpi : Int;

	public var base(get,never) : haxe.Int64;
	public var length(get,never) : haxe.Int64;

	public function new() {
	}

	function get_base() {
		return haxe.Int64.make(baseHigh, baseLow);
	}

	function get_length() {
		return haxe.Int64.make(lengthHigh, lengthLow);
	}

	public function clone() {
		var e = new MemEntry();
		e.baseLow = baseLow;
		e.baseHigh = baseHigh;
		e.lengthLow = lengthLow;
		e.lengthHigh = lengthHigh;
		e.type = type;
		e.acpi = acpi;
		return e;
	}

}

@:struct class FreeCell {
	public var position : Int;
	public var length : Int;
	public var next : FreeCell;
}

@:keep class Memory {

	static var freeList : FreeCell;
	static var unused : FreeCell;
	static var bmpAlloc = 0;
	static var bmpMax = 0;
	static inline var CELL_SIZE = 12;

	static function outOfMemory() {
		freeList.position = bmpMax;
		freeList.length = 0x8000000;
		throw "Out of memory";
	}

	static function allocCell() {
		var c = unused;
		if( c != null ) {
			unused = c.next;
			return c;
		}
		if( bmpAlloc + CELL_SIZE > bmpMax )
			outOfMemory();
		var ptr : FreeCell = hl.Api.unsafeCast(bmpAlloc);
		bmpAlloc += CELL_SIZE;
		return ptr;
	}

	static function freeCell( c : FreeCell ) {
		var addr = Asm.getValuePtr(c);
		if( addr == bmpAlloc - CELL_SIZE )
			bmpAlloc -= CELL_SIZE;
		else {
			c.next = unused;
			unused = c.next;
		}
	}

	static function addMemoryRange( start : Int, length : Int ) {
		var f = freeList;
		var p = null;
		while( f != null ) {
			// enlarge low bounds
			if( start <= f.position && start + length >= f.position ) {
				var delta = f.position - start;
				f.position -= delta;
				f.length += delta;
				// move at end
				start += delta + f.length;
				length -= delta + f.length;
				if( length <= 0 ) return;
			}
			// enlarge high bounds
			if( start <= f.position + f.length && start + length >= f.position + f.length ) {
				// move at end
				var delta = f.position + f.length - start;
				start += delta;
				length -= delta;
				if( length > 0 )
					f.length += length;
				return;
			}
			p = f;
			f = f.next;
		}
		var c = allocCell();
		c.position = start;
		c.length = length;
		c.next = null;
		if( p == null )
			freeList = c;
		else
			p.next = c;
	}

	static function removeMemoryRange( start : Int, length : Int ) {
		var f = freeList;
		var p = null;
		while( f != null ) {
			// outside range
			if( start >= f.position + f.length || start + length <= f.position ) {
				p = f;
				f = f.next;
				continue;
			}
			if( start + length >= f.position + f.length ) {
				// remove high bounds
				var delta = f.position + f.length - start;
				f.length -= delta;
				if( f.length <= 0 ) {
					var n = f.next;
					if( p == null )
						freeList = n;
					else
						p.next = n;
					freeCell(f);
					f = n;
					continue;
				}
			} else if( start <= f.position ) {
				var delta = start + length - f.position;
				f.position += delta;
				f.length -= delta;
			} else {
				// split
				var c = allocCell();
				c.next = f;
				c.position = f.position;
				c.length = start - f.position;
				if( p == null )
					freeList = c;
				else
					p.next = c;
				var delta = f.position + f.length - (start + length);
				f.position = start + length;
				f.length = delta;
			}
			p = f;
			f = f.next;
		}
	}

	static function memAlloc( size : Int, align : Int ) : hl.Bytes {
		var f = freeList;
		var p = null;
		while( f != null ) {
			if( f.length >= size ) {
				var off = 0;
				if( align > 0 ) {
					var k = f.position % align;
					if( k != 0 ) off += align - k;
				}
				var osize = off + size;
				if( osize <= f.length ) {
					var ptr : hl.Bytes = hl.Api.unsafeCast(f.position + off);
					f.position += osize;
					f.length -= osize;
					if( f.length == 0 ) {
						if( p == null )
							freeList = f.next;
						else
							p.next = f.next;
						freeCell(f);
					}
					return ptr;
				}
			}
			p = f;
			f = f.next;
		}
		outOfMemory();
		return null;
	}

	static function memFree( ptr : hl.Bytes ) {
		// TODO
	}

	public static function init() {
		return;
		var entries = [];
		var e : MemEntry = hl.Api.unsafeCast(0x8000);
		e.acpi = 1;

		var regs : Bios.Regs16 = new Bios.Regs16();
		var addr = Asm.getValuePtr(e);
		regs.di = addr;
		regs.edx = 0x534D4150;

		while( true ) {
			regs.eax = 0xe820;
			regs.ecx = 24;
			Bios.interrupt(0x15,regs);
			if( regs.eax != 0x534D4150 )
				throw "assert";
			entries.push(e.clone());
			if( regs.ebx == 0 ) break;
		}
		entries.sort(function(e1,e2) return e1.base > e2.base ? 1 : -1);

		// take over memory allocation
		bmpAlloc = Asm.getValuePtr(Kernel.setMemAllocator(memAlloc,memFree));
		bmpMax = bmpAlloc + (128 << 20); // some space for our free lists
		for( e in entries ) {
			if( e.baseHigh != 0 || e.lengthHigh != 0 ) throw "assert";
			if( e.type == 1 ) addMemoryRange(e.baseLow, e.lengthLow);
		}
		// in case of overlap
		for( e in entries )
			if( e.type != 1 )
				removeMemoryRange(e.baseLow, e.lengthLow);
		// remove previously allocated
		removeMemoryRange(0, bmpAlloc);
	}

}