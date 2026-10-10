// ExampleMod: a small Script Hook RDR2 mod showing this project's patterns.
//   F9  toggles god mode.
//   F10 refills the health, stamina and Dead Eye cores.
// Keys and options live in ExampleMod.ini next to the .asi and are re-read when the file changes.

#include <rdr2/config.h>
#include <rdr2/input.h>
#include <rdr2/log.h>
#include <rdr2/natives.h>
#include <rdr2/scripthook.h>
#include <rdr2/ui.h>

#include <string>

namespace {

rdr2::Config g_config;

struct Settings {
    int toggleGodModeKey = VK_F9;
    int refillCoresKey = VK_F10;
    bool showStatus = true;
};
Settings g_settings;

bool g_godMode = false;

void loadSettings() {
    g_settings.toggleGodModeKey = g_config.getKey("Keys", "ToggleGodMode", VK_F9);
    g_settings.refillCoresKey = g_config.getKey("Keys", "RefillCores", VK_F10);
    g_settings.showStatus = g_config.getBool("Display", "ShowStatus", true);
    rdr2::log("Settings: ToggleGodMode=%s RefillCores=%s ShowStatus=%d",
              rdr2::keyName(g_settings.toggleGodModeKey).c_str(),
              rdr2::keyName(g_settings.refillCoresKey).c_str(), g_settings.showStatus);
}

void refillCores(Ped ped) {
    // Core indices from the native's documentation: 0 = health, 1 = stamina, 2 = Dead Eye.
    for (int core = 0; core < 3; ++core) {
        ATTRIBUTE::_SET_ATTRIBUTE_CORE_VALUE(ped, core, 100);
    }
}

void update() {
    if (HUD::IS_PAUSE_MENU_ACTIVE()) return;

    Ped ped = PLAYER::PLAYER_PED_ID();
    if (!ENTITY::DOES_ENTITY_EXIST(ped)) return;

    if (rdr2::input::consumePress(g_settings.toggleGodModeKey)) {
        g_godMode = !g_godMode;
        if (!g_godMode) ENTITY::SET_ENTITY_INVINCIBLE(ped, FALSE);
        rdr2::ui::notify(g_godMode ? "God mode ON" : "God mode OFF");
        rdr2::log("God mode %s", g_godMode ? "enabled" : "disabled");
    }
    // The player's ped can be replaced (death, mission changes), so re-apply every frame.
    if (g_godMode) ENTITY::SET_ENTITY_INVINCIBLE(ped, TRUE);

    if (rdr2::input::consumePress(g_settings.refillCoresKey)) {
        refillCores(ped);
        rdr2::ui::notify("Cores refilled");
        rdr2::log("Cores refilled");
    }

    if (g_settings.showStatus && g_godMode) {
        rdr2::ui::drawText("God mode", 0.88f, 0.03f, 0.35f, {230, 60, 60, 255});
    }
}

void scriptMain() {
    rdr2::log("Script started");
    loadSettings();
    rdr2::ui::notify("ExampleMod loaded: " + rdr2::keyName(g_settings.toggleGodModeKey) +
                         " god mode, " + rdr2::keyName(g_settings.refillCoresKey) + " refill cores",
                     8000);

    // Natives may only be called from this loop. scriptWait(0) hands control back to the game
    // for one frame; never use Sleep() here.
    while (true) {
        if (g_config.reloadIfChanged()) {
            loadSettings();
            rdr2::ui::notify("ExampleMod: settings reloaded");
        }
        update();
        rdr2::ui::tick();
        scriptWait(0);
    }
}

}  // namespace

BOOL APIENTRY DllMain(HMODULE module, DWORD reason, LPVOID) {
    switch (reason) {
    case DLL_PROCESS_ATTACH:
        rdr2::logInit(module);
        rdr2::log("ExampleMod loaded");
        g_config.init(module);
        scriptRegister(module, scriptMain);
        keyboardHandlerRegister(rdr2::input::onKeyboardMessage);
        break;
    case DLL_PROCESS_DETACH:
        scriptUnregister(module);
        keyboardHandlerUnregister(rdr2::input::onKeyboardMessage);
        break;
    }
    return TRUE;
}
