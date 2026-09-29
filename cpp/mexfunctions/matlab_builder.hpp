#pragma once

#include "document_handler.hpp"
#include "util.hpp"

#include <string>
#include <variant>
#include <vector>

class MatlabBuilder : public DocumentHandler {
public:
    MatlabBuilder() = default;

    void startObject(size_t count) override;
    void key(std::string_view k) override;
    void endObject() override;

    void startArray(size_t count) override;
    void endArray() override;

    void nullValue() override;
    void boolValue(bool b) override;
    void intValue(int64_t i) override;
    void uintValue(uint64_t u) override;
    void doubleValue(double d) override;
    void stringValue(std::string_view s) override;
    void datetimeValue(std::string_view iso) override;

    matlab::data::Array result();

private:
    matlab::data::ArrayFactory factory;

    struct MapFrame {
        std::vector<std::string> keys;
        std::vector<matlab::data::Array> values;
    };

    struct ArrayFrame {
        std::vector<matlab::data::Array> elements;
    };

    using Frame = std::variant<MapFrame, ArrayFrame>;
    std::vector<Frame> stack;
    matlab::data::Array root;

    void pushValue(matlab::data::Array val);
};
