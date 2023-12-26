package hlos;
import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools;

class Macros {

	#if macro
	public static function duplicateFunctions() {
		var fields = Context.getBuildFields();

		function remapExpr( index : Int, e : Expr ) {
			e = e.map(remapExpr.bind(index));
			switch( e.expr ) {
			case EConst(CIdent("__ID__")):
				e.expr = EConst(CInt(""+index));
			default:
			}
			return e;
		}

		for( f in fields.copy() ) {
			var count = 0;
			for( m in f.meta )
				if( m.name == ":dup" )
					switch( m.params[0].expr ) {
					case EConst(CInt(n)): count = Std.parseInt(n);
					default:
					}
			if( count == 0 )
				continue;

			fields.remove(f);
			for( i in 0...count ) {
				var f2 = Reflect.copy(f);
				f2.name = f2.name.split("__ID__").join(""+i);
				f2.kind = switch( f.kind ) {
				case FFun(f):
					var f2 = Reflect.copy(f);
					f2.expr = remapExpr(i, f.expr);
					FFun(f2);
				default: throw "assert";
				}
				f2.meta.push({ name : ":keep", pos : f2.pos });
				fields.push(f2);
			}
		}

		return fields;
	}
	#end

}