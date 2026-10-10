#include <rdr2/input.h>

#include <array>
#include <atomic>

namespace rdr2::input {

namespace {
// Written on the game's window thread, read on the script thread.
std::array<std::atomic<bool>, 256> g_down{};
std::array<std::atomic<bool>, 256> g_pressed{};
}  // namespace

void onKeyboardMessage(DWORD key, WORD, BYTE, BOOL, BOOL, BOOL wasDownBefore, BOOL isUpNow) {
    if (key >= g_down.size()) return;
    g_down[key] = !isUpNow;
    if (!isUpNow && !wasDownBefore) g_pressed[key] = true;
}

bool consumePress(int vk) {
    if (vk <= 0 || vk >= static_cast<int>(g_pressed.size())) return false;
    return g_pressed[vk].exchange(false);
}

bool isDown(int vk) {
    if (vk <= 0 || vk >= static_cast<int>(g_down.size())) return false;
    return g_down[vk];
}

}  // namespace rdr2::input
