#include <rdr2/log.h>

#include <cstdarg>
#include <cstdio>
#include <mutex>

#include <share.h>

#include "paths.h"

namespace rdr2 {

namespace {
std::mutex g_mutex;
FILE* g_file = nullptr;
}  // namespace

void logInit(HMODULE module) {
    std::lock_guard lock(g_mutex);
    if (g_file) return;
    // Deny writes but allow reads, so the log can be read while the game is running.
    g_file = _wfsopen(detail::pathNextToModule(module, L".log").c_str(), L"w", _SH_DENYWR);
}

void log(const char* format, ...) {
    std::lock_guard lock(g_mutex);
    if (!g_file) return;

    SYSTEMTIME now;
    GetLocalTime(&now);
    std::fprintf(g_file, "[%02d:%02d:%02d.%03d] ", now.wHour, now.wMinute, now.wSecond,
                 now.wMilliseconds);

    va_list args;
    va_start(args, format);
    std::vfprintf(g_file, format, args);
    va_end(args);

    std::fputc('\n', g_file);
    std::fflush(g_file);
}

}  // namespace rdr2
