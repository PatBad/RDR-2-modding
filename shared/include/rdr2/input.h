// Keyboard input from Script Hook's keyboard handler. Register onKeyboardMessage in DllMain with
// keyboardHandlerRegister, then poll from the script thread.
#pragma once

#include "scripthook.h"

namespace rdr2::input {

void onKeyboardMessage(DWORD key, WORD repeats, BYTE scanCode, BOOL isExtended, BOOL isWithAlt,
                       BOOL wasDownBefore, BOOL isUpNow);

// True once per physical key press (key repeat is ignored).
bool consumePress(int vk);

// True while the key is held down.
bool isDown(int vk);

}  // namespace rdr2::input
