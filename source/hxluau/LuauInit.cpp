// Ensure hxcpp precompiled header is included first
#include "hxcpp.h"

// Include Luau's initialization implementation after hxcpp PCH
// This provides luaL_openlibs and luaL_newstate
#include "linit.cpp"