package luau;

#if !cpp
#error 'Luau supports only C++ target platforms.'
#end
import haxe.DynamicAccess;
import haxe.extern.Rest;
import luau.Macro.*;
import luau.State;
import luau.Lua;
import luau.LuaCallback;

class Convert {
    static var __anonCallbackId:Int = 0;
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
				case TClass(haxe.ds.IntMap):
					var imap:haxe.ds.IntMap<Dynamic> = val;
					Lua.createtable(l, 0, 0);
					for (key in imap.keys()) {
						toLua(l, imap.get(key));
						Lua.rawseti(l, -2, key);
					}
				case TClass(haxe.ds.ObjectMap):
					var map:haxe.ds.ObjectMap<Dynamic, Dynamic> = val;
					Lua.createtable(l, 0, 0);
					for (key => value in map) {
						toLua(l, value);
						Lua.setfield(l, -2, Std.string(key));
					}
				case TClass(haxe.ds.StringMap):
					var map:haxe.ds.StringMap<Dynamic> = val;
					Lua.createtable(l, 0, 0);
					for (key => value in map) {
						toLua(l, value);
						Lua.setfield(l, -2, key);
					}
				case TClass(String):
					Lua.pushstring(l, cast(val, String));
				case TClass(haxe.io.Bytes):
					var b:haxe.io.Bytes = val;
					Lua.pushstring(l, b.toString());
				case TObject:
					var fields:Array<String> = Reflect.fields(val);
					Lua.createtable(l, fields.length, 0);

				for (key in fields) {
					toLua(l, Reflect.field(val, key));
					Lua.setfield(l, -2, key);
				}
            case TFunction:
                // Wrap Haxe function as a Luau C closure. The upvalue is the
                // numeric callback id so the bridge can look it up in one
                // IntMap read (no name string round-trip on the return trip).
                var id:Int = Lua_helper.allocCallbackId(val);
                var fname = 'hxluau_cb_$id';
                Lua_helper.callbacks.set(fname, val);
                Lua.pushinteger(l, id);
                Lua.pushcclosure(l, Lua_helper.callbackCallable, fname, 1);
            case TClass(LuaCallback):
                // Push a Luau function from registry reference so it can be passed as callback
                var cb:LuaCallback = cast val;
                Lua.rawgeti(l, Lua.REGISTRYINDEX, cb.ref);
				case TClass(_):
					// Reflect generic Haxe class instances into a Lua table with fields & method wrappers
					classToLua(l, val);
				case TEnum(_):
					Lua.pushstring(l, Type.enumConstructor(val));
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
				// Fast-path: treat pure array tables via rawgeti without scanning keys
				var fastArr = tableArrayFast(l, idx);
				if (fastArr != null) return cast fastArr;
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
						var index = Lua.tointeger(l, -2) - 1;
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
                // Move the function to the top and create a registry reference
                Lua.pushvalue(l, idx);
                var ref:Int = Lua.ref(l, -1);
                Lua.pop(l, 1);
                return new LuaCallback(cpp.Pointer.fromRaw(l), ref);
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
			toLua(l, arr[i]);
			Lua.rawseti(l, -2, i + 1);
		}
	}

	static function tableArrayFast(l:State, idx:Int):Array<Dynamic>
	{
		// objlen gives the array-part border in one call; 0 for hash-only tables.
		var n:Int = Std.int(Lua.objlen(l, idx));
		if (n == 0) return null;
		var res:Array<Dynamic> = [];
		res[n - 1] = null;
		for (i in 0...n)
		{
			// Luau's lua_rawgeti returns the type of the pushed value, so the
			// separate Lua.type call is unnecessary here.
			if (Lua.rawgeti(l, idx, i + 1) == Lua.TNIL)
			{
				Lua.pop(l, 1);
				return null;
			}
			res[i] = fromLua(l, -1);
			Lua.pop(l, 1);
		}
		return res;
	}

	static inline function classToLua(l:State, obj:Dynamic):Void {
		// Build a Lua table representing the class instance.
		// - Primitive fields are copied by value
		// - Function fields are exposed as callable closures that dispatch to the instance
		try {
			var cls = Type.getClass(obj);
			if (cls == null) {
				// Fallback to anonymous conversion if no class metadata
				Lua.createtable(l, 0, 0);
				return;
			}
			var fields = Type.getInstanceFields(cls);
			Lua.createtable(l, 0, fields.length);

			for (field in fields) {
				// Skip constructor and internal fields
				if (field == 'new' || StringTools.startsWith(field, '__')) continue;

				var v:Dynamic = null;
				try {
					v = Reflect.getProperty(obj, field);
				} catch (_:Dynamic) {
					// Property getter might not exist; try direct field access
					try v = Reflect.field(obj, field) catch (_:Dynamic) {}
				}

				if (v == null) continue;

				var vt = Type.typeof(v);
				switch (vt) {
					case TFunction:
						// Expose method as Lua closure that calls Reflect.callMethod on the instance
						var method = v;
						var fname = 'hxluau_obj_${__anonCallbackId++}_${field}';
						var wrapper:Dynamic = function(args:Rest<Dynamic>) {
							return Reflect.callMethod(obj, method, args);
						};
						var id:Int = Lua_helper.allocCallbackId(wrapper);
						Lua_helper.callbacks.set(fname, wrapper);
						Lua.pushinteger(l, id);
						Lua.pushcclosure(l, Lua_helper.callbackCallable, fname, 1);
						Lua.setfield(l, -2, field);
					case TInt | TFloat | TBool | TClass(String) | TEnum(_):
						toLua(l, v);
						Lua.setfield(l, -2, field);
					default:
						// Avoid deep recursion for nested class instances; expose as string descriptor
						var desc = try Type.getClassName(Type.getClass(v)) catch (_:Dynamic) null;
						Lua.pushstring(l, desc != null ? desc : Std.string(v));
						Lua.setfield(l, -2, field);
				}
			}

			// Attach a minimal metainfo block
			var cname = try Type.getClassName(cls) catch (_:Dynamic) 'unknown';
			Lua.pushstring(l, cname);
			Lua.setfield(l, -2, '__class__');
		} catch (e:Dynamic) {
			// If anything goes wrong, degrade to a string representation to avoid crashing conversion
			Lua.pushstring(l, '[hxobj] ' + Std.string(obj));
		}
	}
}
