#include "util.hpp"
#include "mexAdapter.hpp"
#include "toml.hpp"

#include <cmath>
#include <vector>

using matlab::data::ArrayType;

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
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
    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.size() < 1) {
            throwMexError(*engine, factory,
                "writetomlMex:InvalidInput",
                "CompactStruct data required.");
            return;
        }

        matlab::data::Array data = inputs[0];

        arrayStyle = "auto";
        tableStyle = "auto";
        tableArrayStyle = "expanded";
        stringEscapeStyle = "auto";
        stringLayout = "auto";
        addSectionSpacing = true;
        indentSize = 2;
        precision = 6;

        if (inputs.size() > 1) {
            parseOptions(inputs[1]);
        }

        toml::ordered_value root = convertTable(data);

        std::string content = toml::format(root);

        if (!addSectionSpacing) {
            content = removeBlankLines(content);
        }

        auto output = factory.createArray<uint8_t>(
            {1, content.size()});
        std::copy(content.begin(), content.end(),
            output.begin());
        outputs[0] = std::move(output);
    }

private:

    // --- Option parsing via StructArray ---

    std::string getOptionString(const matlab::data::StructArray& opts,
                                const std::string& field) {
        matlab::data::TypedArray<matlab::data::MATLABString> arr =
            opts[0][field];
        return matlabStringToUtf8(arr[0]);
    }

    double getOptionDouble(const matlab::data::StructArray& opts,
                           const std::string& field) {
        matlab::data::TypedArray<double> arr = opts[0][field];
        return arr[0];
    }

    void parseOptions(const matlab::data::Array& optsArr) {
        matlab::data::StructArray opts(optsArr);

        arrayStyle        = getOptionString(opts, "ArrayStyle");
        tableStyle        = getOptionString(opts, "TableStyle");
        tableArrayStyle   = getOptionString(opts, "TableArrayStyle");
        stringEscapeStyle = getOptionString(opts, "StringEscapeStyle");
        stringLayout      = getOptionString(opts, "StringLayout");

        addSectionSpacing =
            (getOptionString(opts, "SectionSpacing") == "loose");

        indentSize = static_cast<int>(
            getOptionDouble(opts, "NumIndentationSpaces"));
        precision = static_cast<int>(
            getOptionDouble(opts, "Precision"));
    }

    // --- Index set helper ---

    static std::vector<bool> buildIndexSet(
            const matlab::data::Array& indices, size_t n) {
        std::vector<bool> flags(n + 1, false);
        if (indices.getNumberOfElements() > 0) {
            matlab::data::TypedArray<double> idx = indices;
            for (auto v : idx) {
                size_t i = static_cast<size_t>(v);
                if (i >= 1 && i <= n) flags[i] = true;
            }
        }
        return flags;
    }

    // --- Conversion from CompactStruct ---

    toml::ordered_value convertTable(const matlab::data::Array& csArr) {
        matlab::data::StructArray cs(csArr);

        matlab::data::TypedArray<matlab::data::MATLABString> keys =
            cs[0]["Keys"];
        matlab::data::TypedArray<matlab::data::Array> values =
            cs[0]["Values"];

        size_t n = keys.getNumberOfElements();
        auto isNull = buildIndexSet(cs[0]["NullIndices"], n);
        auto isDt = buildIndexSet(cs[0]["DatetimeIndices"], n);

        toml::ordered_table tbl;
        for (size_t i = 0; i < n; ++i) {
            std::string key = matlabStringToUtf8(keys[i]);

            if (isNull[i + 1]) {
                continue;
            }

            matlab::data::Array val = values[i];

            if (isDt[i + 1]) {
                tbl.push_back({key, convertDatetime(val)});
            } else {
                tbl.push_back({key, convert(val)});
            }
        }

        return toml::ordered_value(std::move(tbl));
    }

    toml::ordered_value convert(const matlab::data::Array& val) {
        auto type = val.getType();
        size_t numel = val.getNumberOfElements();

        if (type == ArrayType::STRUCT) {
            return convertTable(val);
        }

        if (type == ArrayType::CELL) {
            matlab::data::TypedArray<matlab::data::Array> cells = val;
            if (numel > 0 &&
                cells[0].getType() == ArrayType::STRUCT) {
                return convertObjectArray(val, numel);
            }
            return convertCellArray(val, numel);
        }

        switch (type) {
            case ArrayType::LOGICAL:
                if (numel == 1) {
                    matlab::data::TypedArray<bool> b = val;
                    return toml::ordered_value(static_cast<bool>(b[0]));
                }
                return convertNumericArray<bool>(val, numel);

            case ArrayType::DOUBLE:
                if (numel == 1) {
                    return convertDouble(
                        matlab::data::TypedArray<double>(val)[0]);
                }
                return convertNumericArray<double>(val, numel);

            case ArrayType::SINGLE:
                if (numel == 1) {
                    return convertDouble(static_cast<double>(
                        matlab::data::TypedArray<float>(val)[0]));
                }
                return convertNumericArray<float>(val, numel);

            case ArrayType::INT8:
                return convertIntType<int8_t>(val, numel);
            case ArrayType::INT16:
                return convertIntType<int16_t>(val, numel);
            case ArrayType::INT32:
                return convertIntType<int32_t>(val, numel);
            case ArrayType::INT64:
                return convertIntType<int64_t>(val, numel);
            case ArrayType::UINT8:
                return convertIntType<uint8_t>(val, numel);
            case ArrayType::UINT16:
                return convertIntType<uint16_t>(val, numel);
            case ArrayType::UINT32:
                return convertIntType<uint32_t>(val, numel);
            case ArrayType::UINT64:
                return convertIntType<uint64_t>(val, numel);

            case ArrayType::MATLAB_STRING:
                if (numel == 1) {
                    return convertString(val);
                }
                return convertStringArray(val, numel);

            case ArrayType::VALUE_OBJECT:
            case ArrayType::HANDLE_OBJECT_REF:
                if (numel == 1) {
                    return convertDatetime(val);
                }
                return convertDatetimeArray(val, numel);

            default:
                throwMexError(*engine, factory,
                    "writetomlMex:UnsupportedType",
                    "Cannot serialize this MATLAB type.");
                return toml::ordered_value();
        }
    }

    // --- Scalar converters ---

    toml::ordered_value convertDouble(double v) {
        if (v == std::floor(v) && std::abs(v) < (1LL << 53)) {
            return toml::ordered_value(
                static_cast<toml::ordered_value::integer_type>(v));
        }
        toml::floating_format_info fmt;
        fmt.prec = static_cast<std::size_t>(precision);
        fmt.fmt = toml::floating_format::defaultfloat;
        return toml::ordered_value(v, fmt);
    }

    toml::ordered_value convertString(const matlab::data::Array& val) {
        matlab::data::TypedArray<matlab::data::MATLABString> arr = val;
        std::string s = matlabStringToUtf8(arr[0]);

        toml::string_format_info fmt;
        fmt.fmt = resolveStringFormat();
        return toml::ordered_value(std::move(s), fmt);
    }

    toml::string_format resolveStringFormat() {
        bool useLiteral = (stringEscapeStyle == "literal");
        bool useMultiline = (stringLayout == "multiline");

        if (useMultiline) {
            return useLiteral ? toml::string_format::multiline_literal
                              : toml::string_format::multiline_basic;
        }
        return useLiteral ? toml::string_format::literal
                          : toml::string_format::basic;
    }

    toml::ordered_value convertDatetime(const matlab::data::Array& val) {
        matlab::data::CharArray tz(engine->feval(u"getfield",
            {val, factory.createCharArray("TimeZone")}));
        std::string tzStr;
        if (tz.getNumberOfElements() > 0) {
            tzStr = matlabStringToUtf8(tz.toUTF16());
        }

        if (tzStr.empty()) {
            return toml::ordered_value(extractLocalDatetime(val));
        }

        matlab::data::Array utcVal = engine->feval(u"datetime",
            {val, factory.createCharArray("TimeZone"),
             factory.createCharArray("UTC")});

        toml::local_datetime ldt = extractLocalDatetime(utcVal);
        return toml::ordered_value(toml::offset_datetime(
            ldt.date, ldt.time, toml::time_offset(0, 0)));
    }

    toml::local_datetime extractLocalDatetime(
            const matlab::data::Array& val) {
        auto intField = [&](const char16_t* fn) -> int {
            matlab::data::TypedArray<double> r =
                engine->feval(fn, {val});
            return static_cast<int>(r[0]);
        };

        int y  = intField(u"year");
        int mo = intField(u"month");
        int d  = intField(u"day");
        int h  = intField(u"hour");
        int mi = intField(u"minute");

        matlab::data::TypedArray<double> secArr =
            engine->feval(u"second", {val});
        double sec = secArr[0];
        int wholeSec = static_cast<int>(sec);
        int microseconds = static_cast<int>(
            std::round((sec - wholeSec) * 1e6));

        return toml::local_datetime(
            toml::local_date(y, static_cast<toml::month_t>(mo - 1), d),
            toml::local_time(h, mi, wholeSec, microseconds * 1000, 0));
    }

    // --- Array converters ---

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
            const matlab::data::Array& val, size_t numel) {
        matlab::data::TypedArray<matlab::data::MATLABString> arr = val;
        toml::ordered_array tomlArr;
        tomlArr.reserve(numel);

        toml::string_format_info strFmt;
        strFmt.fmt = resolveStringFormat();
        for (const auto& ms : arr) {
            std::string s = matlabStringToUtf8(ms);
            tomlArr.push_back(toml::ordered_value(std::move(s), strFmt));
        }

        toml::array_format_info fmt;
        fmt.fmt = resolveArrayFormat(tomlArr);
        fmt.body_indent = indentSize;
        return toml::ordered_value(std::move(tomlArr), fmt);
    }

    toml::ordered_value convertCellArray(
            const matlab::data::Array& val, size_t numel) {
        matlab::data::TypedArray<matlab::data::Array> cells = val;
        toml::ordered_array tomlArr;
        tomlArr.reserve(numel);

        for (size_t i = 0; i < numel; ++i) {
            tomlArr.push_back(convert(cells[i]));
        }

        toml::array_format_info fmt;
        fmt.fmt = resolveArrayFormat(tomlArr);
        fmt.body_indent = indentSize;
        return toml::ordered_value(std::move(tomlArr), fmt);
    }

    toml::ordered_value convertObjectArray(
            const matlab::data::Array& val, size_t numel) {
        matlab::data::TypedArray<matlab::data::Array> cells = val;

        toml::ordered_array tomlArr;
        tomlArr.reserve(numel);

        for (size_t i = 0; i < numel; ++i) {
            tomlArr.push_back(convertTable(cells[i]));
        }

        toml::array_format_info fmt;
        fmt.body_indent = indentSize;
        fmt.fmt = resolveTableArrayFormat(tomlArr);
        return toml::ordered_value(std::move(tomlArr), fmt);
    }

    toml::ordered_value convertDatetimeArray(
            const matlab::data::Array& val, size_t numel) {
        matlab::data::TypedArray<matlab::data::Array> cells =
            engine->feval(u"num2cell", {val});

        toml::ordered_array tomlArr;
        tomlArr.reserve(numel);

        for (size_t i = 0; i < numel; ++i) {
            tomlArr.push_back(convertDatetime(cells[i]));
        }

        toml::array_format_info fmt;
        fmt.fmt = resolveArrayFormat(tomlArr);
        fmt.body_indent = indentSize;
        return toml::ordered_value(std::move(tomlArr), fmt);
    }

    // --- Format resolution ---

    toml::array_format resolveArrayFormat(
            const toml::ordered_array& arr) {
        if (arrayStyle == "flow") {
            return toml::array_format::oneline;
        }
        if (arrayStyle == "block") {
            return toml::array_format::multiline;
        }

        if (arr.size() <= 3) {
            size_t totalLen = 2;
            for (const auto& elem : arr) {
                totalLen += toml::format(elem).size() + 2;
            }
            if (totalLen <= 60) {
                return toml::array_format::oneline;
            }
        }
        return toml::array_format::multiline;
    }

    toml::array_format resolveTableArrayFormat(
            const toml::ordered_array& arr) {
        if (tableArrayStyle == "inline") {
            return toml::array_format::oneline;
        }
        if (tableArrayStyle == "expanded") {
            return toml::array_format::array_of_tables;
        }

        if (arr.size() > 2) {
            return toml::array_format::array_of_tables;
        }
        for (const auto& elem : arr) {
            if (elem.is_table() && elem.as_table().size() > 3) {
                return toml::array_format::array_of_tables;
            }
        }
        return toml::array_format::oneline;
    }

    // --- Post-processing ---

    std::string removeBlankLines(const std::string& s) {
        std::string result;
        result.reserve(s.size());
        bool prevNewline = false;
        for (char c : s) {
            if (c == '\n') {
                if (prevNewline) {
                    continue;
                }
                prevNewline = true;
            } else {
                prevNewline = false;
            }
            result += c;
        }
        return result;
    }
};
