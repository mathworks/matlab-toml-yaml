#pragma once

#include "document_handler.hpp"
#include "util.hpp"
#include "toml.hpp"

#include <cmath>
#include <sstream>
#include <string>
#include <variant>
#include <vector>

class WriteTomlImpl : public DocumentHandler {
    std::shared_ptr<matlab::engine::MATLABEngine> engine;
    matlab::data::ArrayFactory factory;

    std::string arrayStyle;
    std::string tableStyle;
    std::string tableArrayStyle;
    std::string stringEscapeStyle;
    std::string stringLayout;
    bool addSectionSpacing = true;
    int indentSize = 2;
    int precision = 6;

    struct ObjectFrame {
        toml::ordered_table table;
        std::string pendingKey;
    };
    struct ArrayFrame {
        toml::ordered_array array;
    };
    using Frame = std::variant<ObjectFrame, ArrayFrame>;
    std::vector<Frame> stack;
    toml::ordered_value rootResult;

public:
    explicit WriteTomlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

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

private:
    std::string getOptionString(const matlab::data::StructArray& opts,
                                const std::string& field);
    double getOptionDouble(const matlab::data::StructArray& opts,
                           const std::string& field);
    void parseOptions(const matlab::data::Array& optsArr);

    void pushToParent(toml::ordered_value val);

    toml::ordered_value convertDouble(double v);
    toml::string_format resolveStringFormat();
    toml::array_format resolveArrayFormat(
        const toml::ordered_array& arr);
    toml::array_format resolveTableArrayFormat(
        const toml::ordered_array& arr);
    toml::ordered_value parseDatetimeFromString(const std::string& dtStr);
    std::string removeBlankLines(const std::string& s);
};
