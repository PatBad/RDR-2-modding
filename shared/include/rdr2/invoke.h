// Calls a native by hash through Script Hook. natives.h wraps every native with this.
#pragma once

#include <cstdint>
#include <cstring>
#include <type_traits>

#include "scripthook.h"
#include "types.h"

namespace rdr2::detail {

// Each native argument occupies one 64-bit slot.
template <typename T>
inline void pushArg(T value) {
    static_assert(sizeof(T) <= sizeof(std::uint64_t), "native arguments must fit in 64 bits");
    static_assert(std::is_trivially_copyable_v<T>, "native arguments must be plain values");
    std::uint64_t raw = 0;
    std::memcpy(&raw, &value, sizeof(T));
    nativePush64(raw);
}

}  // namespace rdr2::detail

template <typename R, typename... Args>
inline R invoke(std::uint64_t hash, Args... args) {
    nativeInit(hash);
    (rdr2::detail::pushArg(args), ...);
    if constexpr (std::is_void_v<R>) {
        nativeCall();
    } else {
        return *reinterpret_cast<R*>(nativeCall());
    }
}
