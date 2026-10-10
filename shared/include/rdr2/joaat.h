// Compile-time version of MISC::GET_HASH_KEY: Jenkins one-at-a-time, case-insensitive.
//   constexpr Hash kCattleman = rdr2::joaat("WEAPON_REVOLVER_CATTLEMAN");
#pragma once

#include <string_view>

#include "types.h"

namespace rdr2 {

constexpr Hash joaat(std::string_view text) {
    std::uint32_t hash = 0;
    for (char c : text) {
        auto ch = static_cast<unsigned char>(c);
        if (ch >= 'A' && ch <= 'Z') ch = static_cast<unsigned char>(ch + ('a' - 'A'));
        hash += ch;
        hash += hash << 10;
        hash ^= hash >> 6;
    }
    hash += hash << 3;
    hash ^= hash >> 11;
    hash += hash << 15;
    return hash;
}

}  // namespace rdr2
