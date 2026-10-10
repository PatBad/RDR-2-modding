// Declarations of the functions exported by ScriptHookRDR2.dll.
//
// These mirror inc/main.h from the Script Hook RDR2 SDK (http://www.dev-c.com/rdr2/scripthookrdr2/),
// so mods link against the SDK's ScriptHookRDR2.lib without including its headers. The exports
// use C++ name mangling: if the linker reports an unresolved `__imp_?name@@...` symbol, compare
// the declaration below with `dumpbin /exports sdk\lib\ScriptHookRDR2.lib` and fix it here and
// in ci/ScriptHookRDR2.def.
#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#define SHRDR2_IMPORT __declspec(dllimport)

// Keyboard: called on the game's window thread for every key event.
typedef void (*KeyboardHandler)(DWORD key, WORD repeats, BYTE scanCode, BOOL isExtended,
                                BOOL isWithAlt, BOOL wasDownBefore, BOOL isUpNow);
SHRDR2_IMPORT void keyboardHandlerRegister(KeyboardHandler handler);
SHRDR2_IMPORT void keyboardHandlerUnregister(KeyboardHandler handler);

// Scripts: scriptRegister runs `scriptMain` as a game script. Natives may only be called from it.
SHRDR2_IMPORT void scriptWait(DWORD time);
SHRDR2_IMPORT void scriptRegister(HMODULE module, void (*scriptMain)());
SHRDR2_IMPORT void scriptRegisterAdditionalThread(HMODULE module, void (*scriptMain)());
SHRDR2_IMPORT void scriptUnregister(HMODULE module);

// Natives: used by invoke.h; call the wrappers in natives.h instead.
SHRDR2_IMPORT void nativeInit(UINT64 hash);
SHRDR2_IMPORT void nativePush64(UINT64 value);
SHRDR2_IMPORT PUINT64 nativeCall();

// Script globals.
SHRDR2_IMPORT UINT64* getGlobalPtr(int globalId);

// World pools: fill `arr` with handles and return how many were written.
SHRDR2_IMPORT int worldGetAllVehicles(int* arr, int arrSize);
SHRDR2_IMPORT int worldGetAllPeds(int* arr, int arrSize);
SHRDR2_IMPORT int worldGetAllObjects(int* arr, int arrSize);
SHRDR2_IMPORT int worldGetAllPickups(int* arr, int arrSize);

// Misc.
SHRDR2_IMPORT BYTE* getScriptHandleBaseAddress(int handle);
