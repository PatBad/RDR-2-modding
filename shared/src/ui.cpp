#include <rdr2/ui.h>

#include <rdr2/natives.h>

#include <deque>
#include <utility>

namespace rdr2::ui {

namespace {

struct Message {
    std::string text;
    ULONGLONG expiresAt;
};

std::deque<Message> g_messages;
constexpr size_t kMaxMessages = 5;

}  // namespace

void drawText(const char* text, float x, float y, float scale, Color color) {
    // HUD::_DISPLAY_TEXT and HUD::_SET_TEXT_COLOR stopped working in game build 1436;
    // the UIDEBUG::_BG_* natives are their working replacements.
    UIDEBUG::_BG_SET_TEXT_SCALE(scale, scale);
    UIDEBUG::_BG_SET_TEXT_COLOR(color.r, color.g, color.b, color.a);
    UIDEBUG::_BG_DISPLAY_TEXT(MISC::VAR_STRING(10, "LITERAL_STRING", text), x, y);
}

void notify(std::string text, int durationMs) {
    g_messages.push_back({std::move(text), GetTickCount64() + static_cast<ULONGLONG>(durationMs)});
    while (g_messages.size() > kMaxMessages) g_messages.pop_front();
}

void tick() {
    ULONGLONG now = GetTickCount64();
    while (!g_messages.empty() && g_messages.front().expiresAt <= now) g_messages.pop_front();

    float y = 0.03f;
    for (const Message& message : g_messages) {
        drawText(message.text.c_str(), 0.02f, y, 0.4f);
        y += 0.035f;
    }
}

}  // namespace rdr2::ui
