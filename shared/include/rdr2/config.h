// Settings from an .ini file next to the .asi (ExampleMod.asi -> ExampleMod.ini).
// Values are read from disk on every get call, so read them into your own variables when the
// mod starts and again whenever reloadIfChanged() returns true.
#pragma once

#include <filesystem>
#include <string>

#include "scripthook.h"

namespace rdr2 {

class Config {
public:
    void init(HMODULE module);

    // Cheap to call every frame: checks the file's timestamp at most twice a second.
    bool reloadIfChanged();

    std::string getString(const char* section, const char* key, const char* fallback) const;
    int getInt(const char* section, const char* key, int fallback) const;
    float getFloat(const char* section, const char* key, float fallback) const;
    bool getBool(const char* section, const char* key, bool fallback) const;
    // Accepts a key name ("F9", "NUMPAD5", "K") or a virtual-key code ("0x78", "120").
    int getKey(const char* section, const char* key, int fallbackVk) const;

    const std::filesystem::path& path() const { return path_; }

private:
    std::filesystem::path path_;
    std::filesystem::file_time_type lastWrite_{};
    ULONGLONG lastCheck_ = 0;
};

// Display name for a virtual-key code ("F9"), for on-screen hints.
std::string keyName(int vk);

}  // namespace rdr2
