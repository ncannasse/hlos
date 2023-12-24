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

class Asm {

	static var asm(get,never) : haxe.macro.Expr;
	static function get_asm() return macro untyped $i{"$asm"};

	public static macro function discard( e : Expr ) {
		return switch( getValue(e) ) {
		case VReg(r): macro @:pos(e.pos) $asm(1,$v{r.getIndex()});
		default: Context.error("Should be a CPU register", e.pos);
		}
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

	public static macro function interupt( id : Int ) {
		return macro {
			$asm(0xCD);
			$asm($v{id});
		};
	}

	#if macro

	static function getValue( e : haxe.macro.Expr ) {
		switch( e.expr ) {
		case EConst(CIdent(i)):
			switch( i ) {
			case "Eax": return VReg(Eax);
			case "Ebx": return VReg(Ebx);
			case "Ecx": return VReg(Ecx);
			case "Edx": return VReg(Edx);
			case "Esi": return VReg(Esi);
			case "Edi": return VReg(Edi);
			case "Ebp": return VReg(Ebp);
			case "Esp": return VReg(Esp);
			}
		case EConst(CInt(i)):
			return VInt(Std.parseInt(i));
		default:
		}
		return VExpr(e);
	}

	#end

}