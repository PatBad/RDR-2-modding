// Line-buffered log file next to the .asi (ExampleMod.asi -> ExampleMod.log in the game folder).
// The file is recreated each time the game starts and flushed after every line, so it survives
// crashes. Safe to call from any thread.
#pragma once

#include "scripthook.h"

namespace rdr2 {

void logInit(HMODULE module);
void log(const char* format, ...);

}  // namespace rdr2
