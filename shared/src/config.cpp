#include <rdr2/config.h>

#include <rdr2/log.h>

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <iterator>
#include <system_error>
#include <utility>

#include "paths.h"

namespace rdr2 {

namespace {

std::wstring widen(const char* text) {
    int size = MultiByteToWideChar(CP_UTF8, 0, text, -1, nullptr, 0);
    std::wstring result(size > 0 ? size - 1 : 0, L'\0');
    if (size > 1) MultiByteToWideChar(CP_UTF8, 0, text, -1, result.data(), size);
    return result;
}

std::string narrow(const std::wstring& text) {
    int size = WideCharToMultiByte(CP_UTF8, 0, text.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string result(size > 0 ? size - 1 : 0, '\0');
    if (size > 1) WideCharToMultiByte(CP_UTF8, 0, text.c_str(), -1, result.data(), size, nullptr, nullptr);
    return result;
}

std::string trim(std::string text) {
    auto notSpace = [](unsigned char c) { return !std::isspace(c); };
    text.erase(text.begin(), std::find_if(text.begin(), text.end(), notSpace));
    text.erase(std::find_if(text.rbegin(), text.rend(), notSpace).base(), text.end());
    return text;
}

std::string upper(std::string text) {
    for (char& c : text) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    return text;
}

// Named keys besides letters and digits, which map to their own character code.
const std::pair<const char*, int> kKeyNames[] = {
    {"F1", VK_F1},           {"F2", VK_F2},         {"F3", VK_F3},         {"F4", VK_F4},
    {"F5", VK_F5},           {"F6", VK_F6},         {"F7", VK_F7},         {"F8", VK_F8},
    {"F9", VK_F9},           {"F10", VK_F10},       {"F11", VK_F11},       {"F12", VK_F12},
    {"F13", VK_F13},         {"F14", VK_F14},       {"F15", VK_F15},       {"F16", VK_F16},
    {"F17", VK_F17},         {"F18", VK_F18},       {"F19", VK_F19},       {"F20", VK_F20},
    {"F21", VK_F21},         {"F22", VK_F22},       {"F23", VK_F23},       {"F24", VK_F24},
    {"NUMPAD0", VK_NUMPAD0}, {"NUMPAD1", VK_NUMPAD1}, {"NUMPAD2", VK_NUMPAD2},
    {"NUMPAD3", VK_NUMPAD3}, {"NUMPAD4", VK_NUMPAD4}, {"NUMPAD5", VK_NUMPAD5},
    {"NUMPAD6", VK_NUMPAD6}, {"NUMPAD7", VK_NUMPAD7}, {"NUMPAD8", VK_NUMPAD8},
    {"NUMPAD9", VK_NUMPAD9}, {"MULTIPLY", VK_MULTIPLY}, {"ADD", VK_ADD},
    {"SUBTRACT", VK_SUBTRACT}, {"DECIMAL", VK_DECIMAL}, {"DIVIDE", VK_DIVIDE},
    {"INSERT", VK_INSERT},   {"DELETE", VK_DELETE}, {"HOME", VK_HOME},     {"END", VK_END},
    {"PAGEUP", VK_PRIOR},    {"PAGEDOWN", VK_NEXT}, {"UP", VK_UP},         {"DOWN", VK_DOWN},
    {"LEFT", VK_LEFT},       {"RIGHT", VK_RIGHT},   {"SPACE", VK_SPACE},   {"ENTER", VK_RETURN},
    {"TAB", VK_TAB},         {"BACKSPACE", VK_BACK}, {"PAUSE", VK_PAUSE},
    {"SCROLLLOCK", VK_SCROLL}, {"CAPSLOCK", VK_CAPITAL},
};

}  // namespace

void Config::init(HMODULE module) {
    path_ = detail::pathNextToModule(module, L".ini");
    std::error_code ec;
    lastWrite_ = std::filesystem::last_write_time(path_, ec);
    if (ec) log("Config file not found: %s (using defaults)", narrow(path_.wstring()).c_str());
}

bool Config::reloadIfChanged() {
    ULONGLONG now = GetTickCount64();
    if (now - lastCheck_ < 500) return false;
    lastCheck_ = now;

    std::error_code ec;
    auto writeTime = std::filesystem::last_write_time(path_, ec);
    if (ec || writeTime == lastWrite_) return false;
    lastWrite_ = writeTime;
    log("Config file changed, reloading");
    return true;
}

std::string Config::getString(const char* section, const char* key, const char* fallback) const {
    wchar_t buffer[512];
    GetPrivateProfileStringW(widen(section).c_str(), widen(key).c_str(), widen(fallback).c_str(),
                             buffer, static_cast<DWORD>(std::size(buffer)), path_.c_str());
    return trim(narrow(buffer));
}

int Config::getInt(const char* section, const char* key, int fallback) const {
    std::string value = getString(section, key, "");
    if (value.empty()) return fallback;
    char* end = nullptr;
    long result = std::strtol(value.c_str(), &end, 0);
    return *end == '\0' ? static_cast<int>(result) : fallback;
}

float Config::getFloat(const char* section, const char* key, float fallback) const {
    std::string value = getString(section, key, "");
    if (value.empty()) return fallback;
    char* end = nullptr;
    float result = std::strtof(value.c_str(), &end);
    return *end == '\0' ? result : fallback;
}

bool Config::getBool(const char* section, const char* key, bool fallback) const {
    std::string value = upper(getString(section, key, ""));
    if (value == "1" || value == "TRUE" || value == "YES" || value == "ON") return true;
    if (value == "0" || value == "FALSE" || value == "NO" || value == "OFF") return false;
    return fallback;
}

int Config::getKey(const char* section, const char* key, int fallbackVk) const {
    std::string value = upper(getString(section, key, ""));
    if (value.empty()) return fallbackVk;
    if (value.size() == 1 && std::isalnum(static_cast<unsigned char>(value[0]))) return value[0];
    for (const auto& [name, vk] : kKeyNames) {
        if (value == name) return vk;
    }
    char* end = nullptr;
    long vk = std::strtol(value.c_str(), &end, 0);
    if (*end == '\0' && vk > 0 && vk < 256) return static_cast<int>(vk);
    log("[%s] %s=%s is not a key name or code; using %s", section, key, value.c_str(),
        keyName(fallbackVk).c_str());
    return fallbackVk;
}

std::string keyName(int vk) {
    if ((vk >= '0' && vk <= '9') || (vk >= 'A' && vk <= 'Z')) return std::string(1, static_cast<char>(vk));
    for (const auto& [name, code] : kKeyNames) {
        if (code == vk) return name;
    }
    char buffer[8];
    std::snprintf(buffer, sizeof(buffer), "0x%02X", vk);
    return buffer;
}

}  // namespace rdr2
