# IFLOW Context for hxluau

## Project Overview

This project, `hxluau`, is a Haxe/hxcpp @:native binding library for [Luau](https://luau.org/). It allows Haxe applications targeting C++ to interface with the Luau engine, enabling embedding and executing Luau scripts within Haxe programs.

Key technologies:
- **Haxe**: A high-level, cross-platform programming language.
- **hxcpp**: The C++ target for the Haxe compiler, used to generate native C++ code.
- **Luau**: A fast, small, safe, gradually typed embeddable scripting language derived from Lua, known for its performance and enhanced type system.

The library provides Haxe externs that map to the core Luau C API, making it possible to call Luau functions, manipulate the Luau stack, register Haxe functions callable from Luau, and manage the Luau state from Haxe code. It includes pre-compiled Luau libraries for various platforms (Windows, macOS, Linux, Android, iOS).

## Building and Running

### Prerequisites

- Haxe compiler and hxcpp library installed.
- This library (`hxluau`) installed via haxelib.

### Installation

You can install `hxluau` through `Haxelib`:
```bash
haxelib install hxluau
```
Or through `Git` for the latest updates:
```bash
haxelib git hxluau https://github.com/luau-lang/luau.git
```

### Usage in a Haxe Project

1.  Add `hxluau` to your project's dependencies (e.g., in your `.hxml` file or `build.hxml`):
    ```
    -lib hxluau
    ```
2.  Import the necessary classes in your Haxe code:
    ```haxe
    import hxluau.Lua;
    import hxluau.LuaL;
    import hxluau.LuauVM;  // For Luau-specific functionality (like compile and load)
    import hxluau.Types;
    ```
3.  Write Haxe code that interacts with the Luau API using the provided externs. Refer to the examples in the `examples/` directory.
4.  Compile your Haxe project targeting C++. The hxcpp build process will automatically link the appropriate Luau static library for your target platform based on the configuration in `project/Build.xml`.

### Examples

The `examples/` directory contains several Haxe projects demonstrating how to use `hxluau`:
-   `simple-call`: Basic example of calling a Luau function from Haxe.
-   `return-value`: Shows how to retrieve values returned by Luau functions.
-   `pass-variable`: Demonstrates passing Haxe variables to Luau scripts.
-   `array`: Example of working with Luau tables (arrays) from Haxe.
-   `module`: Shows how to load and use Luau modules.
-   `callback`: Illustrates registering Haxe functions that can be called from Luau.
-   `luau-syntax`: Example showcasing Luau-specific syntax features like type annotations.
-   `override`: Shows how to override Luau functions with Haxe implementations.
-   `alter-state`: Demonstrates manipulating the Luau state directly.
-   `stack-dump`: Example of inspecting the Luau stack.

To build an example (e.g., `simple-call`), navigate to its directory and run the appropriate build script:
-   On Unix-like systems: `haxe build-unix.hxml`
-   On Windows: `haxe build-win.hxml`

## Development Conventions

- **Extern Definitions**: The core of the library consists of `extern` class definitions (`Lua.hx`, `LuaL.hx`, `LuauVM.hx`, `Types.hx`) that map Haxe types and functions to the underlying C API of Luau. These files should accurately reflect the C API and follow Haxe's extern conventions.
- **Platform Support**: Platform-specific Luau static libraries are included in `project/luau/lib/`. The `project/Build.xml` file configures the hxcpp build system to link the correct library based on the target platform and architecture.
- **Build Configuration**: The `haxelib.json` file defines the library's metadata, dependencies (like `hxcpp`), and class path (`source`).
- **Naming**: Haxe identifiers generally follow the naming conventions of the underlying C API, with Haxe-style capitalization (e.g., `lua_pushnumber` becomes `Lua.pushnumber`).

## Luau Syntax Features

Luau extends Lua with several modern language features:

1. **Type Annotations**: Luau supports optional type annotations for variables, function parameters, and return values.
2. **Enhanced Table Types**: Luau provides more precise table typing with support for dictionary and array-like tables.
3. **Union Types**: Variables can have multiple possible types using the `|` operator.
4. **Generic Functions and Types**: Functions and types can be parameterized with type variables.
5. **Improved Error Messages**: Luau provides more detailed and helpful error messages than standard Lua.
6. **Built-in Library Enhancements**: Luau includes enhanced versions of standard Lua libraries with better type information.