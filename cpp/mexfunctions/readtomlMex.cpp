#include "util.hpp"
#include "mexAdapter.hpp"
#include "toml.hpp"

#include <sstream>
#include <vector>

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;

public:
    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.size() < 2) {
            throwMexError(*engine, factory,
                "readtomlMex:InvalidInput",
                "File content and filename required.");
            return;
        }

        matlab::data::TypedArray<uint8_t> contentArr = inputs[0];
        std::string content(contentArr.begin(), contentArr.end());

        matlab::data::TypedArray<matlab::data::MATLABString> filenameArr =
            inputs[1];
        std::string filename = matlabStringToUtf8(factory, filenameArr[0]);

        std::istringstream iss(std::move(content));
        toml::ordered_value data = toml::parse<toml::ordered_type_config>(iss, filename);

        outputs[0] = tableToCompactStruct(data);
    }

private:
    bool isDatetimeType(toml::value_t t) {
        return t == toml::value_t::offset_datetime ||
               t == toml::value_t::local_datetime ||
               t == toml::value_t::local_date ||
               t == toml::value_t::local_time;
    }

    std::string datetimeToString(const toml::value& val) {
        switch (val.type()) {
            case toml::value_t::offset_datetime:
                return toml::to_string(val.as_offset_datetime());
            case toml::value_t::local_datetime:
                return toml::to_string(val.as_local_datetime());
            case toml::value_t::local_date:
                return toml::to_string(val.as_local_date());
            case toml::value_t::local_time:
                return toml::to_string(val.as_local_time());
            default:
                return {};
        }
    }

    matlab::data::Array emptyArray() {
        return factory.createArray<double>({0, 0});
    }

    // --- Style struct helpers ---

    matlab::data::Array commentsToArray(const toml::value& val) {
        const auto& comments = val.comments();
        size_t nc = comments.size();
        if (nc == 0) {
            return factory.createArray<matlab::data::MATLABString>({0, 0});
        }
        auto arr = factory.createArray<matlab::data::MATLABString>(
            {nc, 1});
        for (size_t j = 0; j < nc; ++j) {
            arr[j][0] = matlab::data::MATLABString(
                factory.createCharArrayFromUTF8(comments[j]).toUTF16());
        }
        return arr;
    }

    matlab::data::Array makeTOMLStyleStruct(
            const std::string& containerStyle,
            const std::string& scalarStyle,
            bool isArray,
            const std::string& integerFormat,
            const std::string& floatFormat,
            bool stringMultiline,
            const std::string& tableFormat,
            bool arrayOfTables,
            matlab::data::Array comments,
            const std::string& trailingComment) {
        auto s = factory.createStructArray({1, 1},
            {"ContainerStyle", "ScalarStyle", "IsArray",
             "IntegerFormat", "FloatFormat", "StringMultiline",
             "TableFormat", "ArrayOfTables",
             "Comments", "TrailingComment"});
        s[0]["ContainerStyle"] = makeString(factory, containerStyle);
        s[0]["ScalarStyle"] = makeString(factory, scalarStyle);
        s[0]["IsArray"] = factory.createScalar<bool>(isArray);
        s[0]["IntegerFormat"] = makeString(factory, integerFormat);
        s[0]["FloatFormat"] = makeString(factory, floatFormat);
        s[0]["StringMultiline"] = factory.createScalar<bool>(stringMultiline);
        s[0]["TableFormat"] = makeString(factory, tableFormat);
        s[0]["ArrayOfTables"] = factory.createScalar<bool>(arrayOfTables);
        s[0]["Comments"] = std::move(comments);
        s[0]["TrailingComment"] = makeString(factory, trailingComment);
        return s;
    }

    matlab::data::Array extractScalarStyle(const toml::value& val) {
        std::string scalarStyle = "auto";
        std::string integerFormat = "dec";
        std::string floatFormat = "default";
        bool stringMultiline = false;
        bool nonDefault = false;

        switch (val.type()) {
            case toml::value_t::integer: {
                auto fmt = val.as_integer_fmt().fmt;
                if (fmt == toml::integer_format::hex) {
                    integerFormat = "hex"; nonDefault = true;
                } else if (fmt == toml::integer_format::oct) {
                    integerFormat = "oct"; nonDefault = true;
                } else if (fmt == toml::integer_format::bin) {
                    integerFormat = "bin"; nonDefault = true;
                }
                break;
            }
            case toml::value_t::floating: {
                auto fmt = val.as_floating_fmt().fmt;
                if (fmt == toml::floating_format::fixed) {
                    floatFormat = "fixed"; nonDefault = true;
                } else if (fmt == toml::floating_format::scientific) {
                    floatFormat = "scientific"; nonDefault = true;
                }
                break;
            }
            case toml::value_t::string: {
                auto fmt = val.as_string_fmt().fmt;
                if (fmt == toml::string_format::literal) {
                    scalarStyle = "single-quoted"; nonDefault = true;
                } else if (fmt == toml::string_format::multiline_basic) {
                    stringMultiline = true; nonDefault = true;
                } else if (fmt == toml::string_format::multiline_literal) {
                    scalarStyle = "single-quoted";
                    stringMultiline = true; nonDefault = true;
                }
                break;
            }
            default:
                break;
        }

        if (!nonDefault && val.comments().empty()) {
            return emptyArray();
        }

        return makeTOMLStyleStruct(
            "block", scalarStyle, false,
            integerFormat, floatFormat, stringMultiline,
            "expanded", false,
            commentsToArray(val), "");
    }

    matlab::data::Array extractArrayStyle(const toml::ordered_value& val) {
        auto afmt = val.as_array_fmt().fmt;

        std::string containerStyle = "block";
        bool arrayOfTables = false;

        if (afmt == toml::array_format::oneline) {
            containerStyle = "flow";
        } else if (afmt == toml::array_format::array_of_tables) {
            arrayOfTables = true;
        }

        bool nonDefault = (containerStyle != "block") || arrayOfTables;
        if (!nonDefault && val.comments().empty()) {
            return emptyArray();
        }

        return makeTOMLStyleStruct(
            containerStyle, "auto", true,
            "dec", "default", false,
            "expanded", arrayOfTables,
            commentsToArray(val), "");
    }

    matlab::data::Array extractTableNodeStyle(const toml::ordered_value& table) {
        auto tfmt = table.as_table_fmt().fmt;

        std::string containerStyle = "block";
        std::string tableFormat = "expanded";

        if (tfmt == toml::table_format::oneline) {
            containerStyle = "flow";
            tableFormat = "inline";
        } else if (tfmt == toml::table_format::dotted) {
            tableFormat = "dotted";
        }

        bool nonDefault = (tableFormat != "expanded");
        if (!nonDefault && table.comments().empty()) {
            return emptyArray();
        }

        return makeTOMLStyleStruct(
            containerStyle, "auto", false,
            "dec", "default", false,
            tableFormat, false,
            commentsToArray(table), "");
    }

    // --- Main conversion ---

    matlab::data::Array tableToCompactStruct(const toml::ordered_value& table) {
        const auto& tbl = table.as_table();
        size_t n = tbl.size();

        auto keys = factory.createArray<matlab::data::MATLABString>({1, n});
        auto values = factory.createArray<matlab::data::Array>({1, n});
        auto keyStyles = factory.createArray<matlab::data::Array>({1, n});
        std::vector<double> nullIdx, datetimeIdx;

        size_t i = 0;
        for (const auto& [key, val] : tbl) {
            keys[0][i] = matlab::data::MATLABString(
                factory.createCharArrayFromUTF8(key).toUTF16());

            if (val.type() == toml::value_t::table) {
                values[0][i] = tableToCompactStruct(val);
            } else if (val.type() == toml::value_t::array) {
                values[0][i] = convertArray(val.as_array());
                keyStyles[0][i] = extractArrayStyle(val);
            } else if (isDatetimeType(val.type())) {
                datetimeIdx.push_back(static_cast<double>(i + 1));
                values[0][i] = makeString(factory, datetimeToString(val));
                keyStyles[0][i] = extractScalarStyle(val);
            } else {
                values[0][i] = convertScalar(val);
                keyStyles[0][i] = extractScalarStyle(val);
            }
            ++i;
        }

        auto nullArr = toDoubleArray(nullIdx);
        auto dtArr = toDoubleArray(datetimeIdx);
        auto emptyArr = factory.createArray<double>({1, 0});
        auto nodeStyle = extractTableNodeStyle(table);

        return makeCompactStruct(factory, keys, values, nullArr, dtArr,
                                 emptyArr, nodeStyle, keyStyles);
    }

    matlab::data::Array toDoubleArray(const std::vector<double>& vec) {
        if (vec.empty()) {
            return factory.createArray<double>({1, 0});
        }
        auto arr = factory.createArray<double>({1, vec.size()});
        for (size_t i = 0; i < vec.size(); ++i) {
            arr[0][i] = vec[i];
        }
        return arr;
    }

    matlab::data::Array convertScalar(const toml::value& val) {
        switch (val.type()) {
            case toml::value_t::boolean:
                return factory.createScalar<bool>(val.as_boolean());
            case toml::value_t::integer:
                return factory.createScalar<double>(
                    static_cast<double>(val.as_integer()));
            case toml::value_t::floating:
                return factory.createScalar<double>(val.as_floating());
            case toml::value_t::string:
                return makeString(factory, val.as_string());
            default:
                return emptyArray();
        }
    }

    matlab::data::Array convertArray(const toml::ordered_array& arr) {
        if (arr.empty()) {
            return emptyArray();
        }

        auto firstType = arr.front().type();
        bool homogeneous = std::all_of(arr.begin(), arr.end(),
            [&](const toml::value& v) {
                return v.type() == firstType;
            });

        if (homogeneous && firstType == toml::value_t::table) {
            size_t count = arr.size();
            auto out = factory.createArray<matlab::data::Array>({1, count});
            for (size_t i = 0; i < count; ++i) {
                out[0][i] = tableToCompactStruct(arr[i]);
            }
            return out;
        }

        if (homogeneous && firstType == toml::value_t::integer) {
            auto out = factory.createArray<double>({1, arr.size()});
            for (size_t i = 0; i < arr.size(); ++i) {
                out[0][i] = static_cast<double>(arr[i].as_integer());
            }
            return out;
        }

        if (homogeneous && firstType == toml::value_t::floating) {
            auto out = factory.createArray<double>({1, arr.size()});
            for (size_t i = 0; i < arr.size(); ++i) {
                out[0][i] = arr[i].as_floating();
            }
            return out;
        }

        if (homogeneous && firstType == toml::value_t::boolean) {
            auto out = factory.createArray<bool>({1, arr.size()});
            for (size_t i = 0; i < arr.size(); ++i) {
                out[0][i] = arr[i].as_boolean();
            }
            return out;
        }

        if (homogeneous && firstType == toml::value_t::string) {
            auto out = factory.createArray<matlab::data::MATLABString>(
                {1, arr.size()});
            for (size_t i = 0; i < arr.size(); ++i) {
                out[0][i] = matlab::data::MATLABString(
                    factory.createCharArrayFromUTF8(
                        arr[i].as_string()).toUTF16());
            }
            return out;
        }

        std::vector<matlab::data::Array> elems;
        elems.reserve(arr.size());
        for (const auto& elem : arr) {
            if (elem.type() == toml::value_t::table) {
                elems.push_back(tableToCompactStruct(elem));
            } else if (elem.type() == toml::value_t::array) {
                elems.push_back(convertArray(elem.as_array()));
            } else if (isDatetimeType(elem.type())) {
                elems.push_back(makeString(factory, datetimeToString(elem)));
            } else {
                elems.push_back(convertScalar(elem));
            }
        }

        auto out = factory.createArray<matlab::data::Array>(
            {1, arr.size()});
        for (size_t i = 0; i < elems.size(); ++i) {
            out[0][i] = std::move(elems[i]);
        }
        return out;
    }
};
