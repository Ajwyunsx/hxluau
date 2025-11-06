package luau;

#if !cpp
#error 'Luau supports only C++ target platforms.'
#end
import haxe.DynamicAccess;
import luau.Macro.*;
import luau.State;
import luau.Lua;

class Convert {
	public static function toLua(l:State, val:Dynamic):Void {
		switch (Type.typeof(val)) {
			case TNull:
				Lua.pushnil(l);
			case TInt:
				Lua.pushinteger(l, cast(val, Int));
			case TFloat:
				Lua.pushnumber(l, cast(val, Float));
            case TBool:
                Lua.pushboolean(l, val);
			case TClass(Array):
				arrayToLua(l, val);
			case TClass(haxe.ds.ObjectMap) | TClass(haxe.ds.StringMap):
				var map:Map<String, Dynamic> = val;

				Lua.createtable(l, Lambda.count(map), 0);

				for (key => value in map) {
					Lua.pushstring(l, Std.isOfType(key, String) ? key : Std.string(key));
					toLua(l, value);
					Lua.settable(l, -3);
				}
			case TClass(String):
				Lua.pushstring(l, cast(val, String));
			case TObject:
				Lua.createtable(l, Reflect.fields(val).length, 0);

				for (key in Reflect.fields(val)) {
					Lua.pushstring(l, key);
					toLua(l, Reflect.field(val, key));
					Lua.settable(l, -3);
				}
			default:
				final typeName = Std.string(Type.typeof(val));
				Sys.println('Couldn\'t convert "${typeName}" to Lua.');
		}
	}

	public static function fromLua(l:State, idx:Int):Dynamic {
		switch (Lua.type(l, idx)) {
			case type if (type == Lua.TNIL):
				return null;
            case type if (type == Lua.TBOOLEAN):
                return Lua.toboolean(l, idx);
			case type if (type == Lua.TNUMBER):
				return Lua.tonumber(l, idx);
			case type if (type == Lua.TSTRING):
				return cast(Lua.tostring(l, idx), String);
			case type if (type == Lua.TTABLE):
				var count = 0;
				var array = true;

				loopTable(l, idx, {
					if (array) {
						if (Lua.type(l, -2) != Lua.TNUMBER)
							array = false;
						else {
							var index = Lua.tonumber(l, -2);
							if (index < 0 || Std.int(index) != index)
								array = false;
						}
					}
					count++;
				});

				return if (count == 0) {
					{};
				} else if (array) {
					var v = [];
					loopTable(l, idx, {
						var index = Std.int(Lua.tonumber(l, -2)) - 1;
						v[index] = fromLua(l, -1);
					});
					cast v;
				} else {
					var v:DynamicAccess<Any> = {};
					loopTable(l, idx, {
						switch Lua.type(l, -2) {
							case t if (t == Lua.TSTRING): 
								final key = Lua.tostring(l, -2);
								v.set(key, fromLua(l, -1));
							case t if (t == Lua.TNUMBER): 
								final num = Lua.tonumber(l, -2);
								v.set(Std.string(num), fromLua(l, -1));
						}
					});
					cast v;
				}
			case type if (type == Lua.TFUNCTION):
				return new LuaCallback(cpp.Pointer.fromRaw(l), Lua.ref(l, Lua.REGISTRYINDEX));
			default:
			final typeName = Lua.typename(l, idx);
			Sys.println('Couldn\'t convert "${typeName}" to Haxe.');
		}

		return null;
	}
	
	public static inline function arrayToLua(l:State, arr:Array<Dynamic>)
	{
		Lua.createtable(l, arr.length, 0);

		for (i in 0...arr.length)
		{
			Lua.pushinteger(l, i + 1);
			toLua(l, arr[i]);
			Lua.settable(l, -3);
		}
	}
}
