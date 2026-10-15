#pragma once

#define RYML_WITH_LEGACY_OPERATORS
#include "ryml.hpp"

#include <stdexcept>
#include <string>

struct RymlParseError : std::runtime_error {
    size_t line;
    size_t col;
    RymlParseError(const std::string& msg, size_t line, size_t col)
        : std::runtime_error(msg), line(line), col(col) {}
};

void installRymlErrorHandlers();
