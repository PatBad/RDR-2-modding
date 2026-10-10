// On-screen text. Everything here calls natives, so use it only from the script thread, and
// redraw every frame: text drawn by the game lasts for a single frame.
#pragma once

#include <string>

namespace rdr2::ui {

struct Color {
    int r, g, b, a;
};

// x and y are screen fractions (0..1) from the top-left corner.
void drawText(const char* text, float x, float y, float scale = 0.4f,
              Color color = {255, 255, 255, 255});

// Shows a message in the top-left corner for `durationMs`. Drawn by tick().
void notify(std::string text, int durationMs = 3000);

// Call once per frame from the script loop.
void tick();

}  // namespace rdr2::ui
