#pragma once

#include <cstddef>
#include <cstdint>
#include <string_view>

class DocumentHandler {
public:
    virtual ~DocumentHandler() = default;

    virtual void startObject(size_t count) = 0;
    virtual void key(std::string_view k) = 0;
    virtual void endObject() = 0;

    virtual void startArray(size_t count) = 0;
    virtual void endArray() = 0;

    virtual void nullValue() = 0;
    virtual void boolValue(bool b) = 0;
    virtual void intValue(int64_t i) = 0;
    virtual void uintValue(uint64_t u) = 0;
    virtual void doubleValue(double d) = 0;
    virtual void stringValue(std::string_view s) = 0;
    virtual void datetimeValue(std::string_view iso) = 0;
};
