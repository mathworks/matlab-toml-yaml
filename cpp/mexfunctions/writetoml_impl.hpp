#pragma once

#include "util.hpp"
#include "toml.hpp"

#include <cmath>
#include <sstream>
#include <string>
#include <vector>

class WriteTomlImpl {
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

public:
    explicit WriteTomlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

private:
    std::string getOptionString(const matlab::data::StructArray& opts,
                                const std::string& field);
    double getOptionDouble(const matlab::data::StructArray& opts,
                           const std::string& field);
    void parseOptions(const matlab::data::Array& optsArr);

    toml::ordered_value convertTable(const matlab::data::Array& nodeArr);
    bool isMissingNode(const matlab::data::Array& val);
    toml::ordered_value convert(const matlab::data::Array& val);
    toml::ordered_value convertValueNodeData(
        const matlab::data::StructArray& node);
    toml::ordered_value parseDatetimeFromString(const std::string& dtStr);

    toml::ordered_value convertDouble(double v);
    toml::ordered_value convertString(const matlab::data::Array& val);
    toml::string_format resolveStringFormat();
    toml::ordered_value convertDatetime(const matlab::data::Array& val);
    toml::local_datetime extractLocalDatetime(
        const matlab::data::Array& val);

    template <typename T>
    toml::ordered_value convertIntType(const matlab::data::Array& val,
                                       size_t numel) {
        if (numel == 1) {
            matlab::data::TypedArray<T> arr = val;
            return toml::ordered_value(
                static_cast<toml::ordered_value::integer_type>(arr[0]));
        }
        return convertNumericArray<T>(val, numel);
    }

    template <typename T>
    toml::ordered_value convertNumericArray(
            const matlab::data::Array& val, size_t numel) {
        matlab::data::TypedArray<T> arr = val;
        toml::ordered_array tomlArr;
        tomlArr.reserve(numel);

        for (auto elem : arr) {
            if constexpr (std::is_same_v<T, bool>) {
                tomlArr.push_back(toml::ordered_value(
                    static_cast<bool>(elem)));
            } else if constexpr (std::is_floating_point_v<T>) {
                tomlArr.push_back(convertDouble(
                    static_cast<double>(elem)));
            } else {
                tomlArr.push_back(toml::ordered_value(
                    static_cast<toml::ordered_value::integer_type>(
                        elem)));
            }
        }

        toml::array_format_info fmt;
        fmt.fmt = resolveArrayFormat(tomlArr);
        fmt.body_indent = indentSize;
        return toml::ordered_value(std::move(tomlArr), fmt);
    }

    toml::ordered_value convertStringArray(
        const matlab::data::Array& val, size_t numel);
    toml::ordered_value convertCellArray(
        const matlab::data::Array& val, size_t numel);
    toml::ordered_value convertObjectArray(
        const matlab::data::Array& val, size_t numel);
    toml::ordered_value convertDatetimeArray(
        const matlab::data::Array& val, size_t numel);

    toml::array_format resolveArrayFormat(
        const toml::ordered_array& arr);
    toml::array_format resolveTableArrayFormat(
        const toml::ordered_array& arr);
    std::string removeBlankLines(const std::string& s);
};
