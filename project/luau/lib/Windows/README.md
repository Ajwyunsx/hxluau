# Windows Luau Library

The Windows x64 version of `luau.lib` was removed from this repository due to GitHub's file size limitations (the file exceeded 100MB).

## How to obtain the Luau library

You have several options to obtain the required Luau library:

### Option 1: Build from source
1. Clone the Luau repository: `git clone https://github.com/luau-lang/luau.git`
2. Follow the build instructions for Windows in the Luau repository
3. Copy the generated `luau.lib` to this directory

### Option 2: Download pre-built binaries
1. Visit the Luau releases page: https://github.com/luau-lang/luau/releases
2. Download the appropriate Windows build
3. Extract `luau.lib` to this directory

### Option 3: Use the ARM64 version
If you're building for ARM64 Windows, the `luau.lib` file is already available in the `arm64` subdirectory.

## File Structure
```
Windows/
├── x64/
│   └── .gitkeep        # Placeholder - you need to add luau.lib here
└── arm64/
    └── luau.lib        # Available for ARM64 builds
```

After obtaining the library, place it in the appropriate directory based on your target architecture.