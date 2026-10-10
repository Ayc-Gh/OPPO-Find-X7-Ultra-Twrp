#pragma once
#include <charconv>
#include <string>
namespace android::base {
inline bool ParseInt(const std::string& text, int* value) {
    int parsed = 0;
    auto result = std::from_chars(text.data(), text.data() + text.size(), parsed);
    if (result.ec != std::errc{} || result.ptr != text.data() + text.size()) return false;
    *value = parsed;
    return true;
}
}
