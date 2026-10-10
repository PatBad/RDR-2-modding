#pragma once

#include <filesystem>
#include <string>

#include <rdr2/scripthook.h>

namespace rdr2::detail {

// The module's own path with a different extension: ExampleMod.asi -> ExampleMod.ini.
inline std::filesystem::path pathNextToModule(HMODULE module, const wchar_t* extension) {
    std::wstring buffer(MAX_PATH, L'\0');
    for (;;) {
        DWORD length = GetModuleFileNameW(module, buffer.data(), static_cast<DWORD>(buffer.size()));
        if (length < buffer.size()) {
            buffer.resize(length);
            break;
        }
        buffer.resize(buffer.size() * 2);
    }
    std::filesystem::path path(buffer);
    path.replace_extension(extension);
    return path;
}

}  // namespace rdr2::detail
