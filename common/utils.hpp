#pragma once

#include <exception>
#include <spdlog/spdlog.h>
#include <type_traits>
#include <typeinfo>

namespace Shiba {

template<typename C, typename T, typename... Ts>
constexpr bool IsOneOf() {
    if constexpr (std::is_same<C, T>::value)
        return true;
    else if constexpr (sizeof...(Ts) > 0)
        return IsOneOf<C, Ts...>();
    else
        return false;
}

template<typename T, typename Iterable>
constexpr bool IsOneOf(const Iterable &types) {
    for (const auto &typ : types)
        if (typ == typeid(T))
            return true;
    return false;
}

inline void HandleException(std::exception_ptr ptr, const std::string &info = "No additional information provided") {
    try {
        std::rethrow_exception(ptr);
    } catch (const std::exception &e) {
        spdlog::error("Caught exception:\n\
        typeid(e).name() = \"{}\"\n\
        e.what() = \"{}\"\n\
        additional information: \"{}\"",
                      typeid(e).name(), e.what(), info);
    }
}

} // namespace Shiba