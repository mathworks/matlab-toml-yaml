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
        std::string filename = matlabStringToUtf8(filenameArr[0]);

        std::istringstream iss(std::move(content));
        toml::ordered_value data = toml::parse<toml::ordered_type_config>(iss, filename);

        outputs[0] = tableToNode(data);
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

    matlab::data::Array tableToNode(const toml::ordered_value& table) {
        const auto& tbl = table.as_table();
        size_t n = tbl.size();

        auto keys = factory.createArray<matlab::data::MATLABString>({1, n});
        auto values = factory.createArray<matlab::data::Array>({1, n});

        size_t i = 0;
        for (const auto& [key, val] : tbl) {
            keys[0][i] = utf8ToMATLABString(key);

            if (val.type() == toml::value_t::table) {
                values[0][i] = tableToNode(val);
            } else if (val.type() == toml::value_t::array) {
                values[0][i] = convertArray(val.as_array());
            } else if (isDatetimeType(val.type())) {
                values[0][i] = makeValueNode(factory,
                    factory.createScalar(
                        utf8ToMATLABString(datetimeToString(val))),
                    "datetime");
            } else {
                values[0][i] = convertScalar(val);
            }
            ++i;
        }

        return makeTableNode(factory, keys, values);
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
                return factory.createScalar(*(utf8ToMATLABString(val.as_string())));
            default:
                return factory.createArray<double>({0, 0});
        }
    }

    matlab::data::Array convertArray(const toml::ordered_array& arr) {
        if (arr.empty()) {
            return factory.createArray<double>({0, 0});
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
                out[0][i] = tableToNode(arr[i]);
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
                out[0][i] = utf8ToMATLABString(arr[i].as_string());
            }
            return out;
        }

        std::vector<matlab::data::Array> elems;
        elems.reserve(arr.size());
        for (const auto& elem : arr) {
            if (elem.type() == toml::value_t::table) {
                elems.push_back(tableToNode(elem));
            } else if (elem.type() == toml::value_t::array) {
                elems.push_back(convertArray(elem.as_array()));
            } else if (isDatetimeType(elem.type())) {
                elems.push_back(factory.createScalar(utf8ToMATLABString(datetimeToString(elem))));
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
