package hlos;

import haxe.macro.Context;
import haxe.macro.Expr;

enum Register {
	Eax;
	Ecx;
	Edx;
	Ebx;
	Esp;
	Ebp;
	Esi;
	Edi;
}

enum Value {
	VReg( r : Register );
	VExpr( e : haxe.macro.Expr );
	VInt( v : Int );
}

enum SimpleOp {
	IRet;
	Cli;
	Sti;
}

#if !macro
@:struct class HLClosure {
	public var type : hl.Type;
	public var funPtr : hl.Bytes;
	public var hasValue : Int;
	public var value : Dynamic;
}
#end

class Asm {

	static var CODES = [
		IRet => 0xCF,
		Cli => 0xFA,
		Sti => 0xFB,
	];

	#if !macro
	public static function getFunctionPtr(v:haxe.Constraints.Function) {
		var c : HLClosure = hl.Api.unsafeCast(v);
		return c.funPtr.address().low;
	}
	#end

	public static var asm(get,never) : haxe.macro.Expr;
	static function get_asm() return macro untyped $i{"$asm"};

	public static macro function setNakedFunction() {
		return macro $asm(4,0);
	}

	public static macro function getValuePtr( e : Expr ) {
		return macro (hl.Api.unsafeCast($e) : hl.Bytes).address().low;
	}

	public static macro function discard( e : ExprOf<Register> ) {
		return switch( getValue(e) ) {
		case VReg(r): macro @:pos(e.pos) $asm(1,$v{r.getIndex()});
		default: Context.error("Should be a CPU register", e.pos);
		}
	}

	public static macro function push( v : Expr ) {
		switch( getValue(v) ) {
		case VReg(r):
			Context.error("Not implemented", v.pos);
		case VInt(i):
			Context.error("Not implemented", v.pos);
		case VExpr(e):
			Context.error("Not implemented", v.pos);
		}
		return null;
	}

	public static macro function pop( v : Expr ) {
		switch( getValue(v) ) {
		case VReg(r):
			return macro $asm(0,$v{0x58+r.getIndex()});
		default:
			Context.error("Should be a register", v.pos);
		}
		return null;
	}

	public static macro function emit( op : ExprOf<SimpleOp> ) {
		var eop = getEnum(SimpleOp, op);
		if( eop == null ) Context.error("Should be SimpleOp", op.pos);
		return macro $asm(0,$v{CODES.get(eop)});
	}

	public static macro function set( dst : Expr, value : Expr ) {
		var vdst = getValue(dst);
		var v = getValue(value);
		var pos = Context.currentPos();
		return switch( [vdst, v] ) {
		case [VReg(r), VInt(v)]:
			macro @:pos(pos) {
				$asm(1,$v{r.getIndex()}); // discard reg
				$asm(0,$v{0xB8 + r.getIndex()});
				$asm(0,$v{v & 0xFF});
				$asm(0,$v{(v >>> 8) & 0xFF});
				$asm(0,$v{(v >>> 16) & 0xFF});
				$asm(0,$v{(v >>> 24) & 0xFF});
			}
		case [VReg(r), VExpr(e)]:
			macro @:pos(pos) $asm(2, $v{r.getIndex()}, $e);
		case [VExpr(e), VReg(r)]:
			switch( e.expr ) {
			case EConst(CIdent(i)):
				macro @:pos(pos) $asm(3, $v{r.getIndex()}, $e);
			default:
				Context.error("Should set a variable", e.pos);
			}
		default:
			Context.error("Invalid operation "+vdst.getName().substr(1)+" := "+v.getName().substr(1), pos);
		}
	}

	#if macro

	static function getEnum<T>( en : Enum<T>, e : Expr ) {
		return switch( e.expr ) {
		case EConst(CIdent(i)):
			try en.createByName(i) catch( e : Dynamic ) null;
		default:
			null;
		}
	}

	static function getValue( e : Expr ) {
		switch( e.expr ) {
		case EConst(CIdent(_)):
			var r = getEnum(Register,e);
			if( r != null )
				return VReg(r);
		case EConst(CInt(i)):
			return VInt(Std.parseInt(i));
		default:
		}
		return VExpr(e);
	}

	#end

}