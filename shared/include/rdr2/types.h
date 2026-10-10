// Types used by the native wrappers in natives.h. Handles are plain script integers.
#pragma once

#include <cstdint>

#include "scripthook.h"

using Any = int;
using Hash = std::uint32_t;

using AnimScene = int;
using Blip = int;
using Cam = int;
using Entity = int;
using FireId = int;
using Interior = int;
using ItemSet = int;
using Object = int;
using Ped = int;
using PersChar = int;
using Pickup = int;
using Player = int;
using PopZone = int;
using Prompt = int;
using PropSet = int;
using ScrHandle = int;
using Vehicle = int;
using Volume = int;

// The game stores vectors as three 8-byte script slots, so each float is padded to 8 bytes.
#pragma pack(push, 1)
struct Vector3 {
    float x;
    DWORD _paddingx;
    float y;
    DWORD _paddingy;
    float z;
    DWORD _paddingz;
};
#pragma pack(pop)
static_assert(sizeof(Vector3) == 24, "Vector3 must match the game's script layout");

inline Vector3 makeVector3(float x, float y, float z) {
    Vector3 v{};
    v.x = x;
    v.y = y;
    v.z = z;
    return v;
}
