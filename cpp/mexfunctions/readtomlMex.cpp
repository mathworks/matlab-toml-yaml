#include "util.hpp"
#include "mexAdapter.hpp"
#include "toml.hpp"

#include <vector>

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;
    bool datetimeAsString = false;

public:
    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.size() < 1) {
            throwMexError(*engine, factory,
                "readtomlMex:InvalidInput", "Filename required.");
            return;
        }

        matlab::data::TypedArray<matlab::data::MATLABString> filenameArr =
            inputs[0];
        std::string filename = matlabStringToUtf8(factory, filenameArr[0]);

        datetimeAsString = false;
        if (inputs.size() > 1) {
            matlab::data::StructArray opts(inputs[1]);
            matlab::data::TypedArray<matlab::data::MATLABString> dtType =
                opts[0]["DatetimeType"];
            datetimeAsString =
                (matlabStringToUtf8(factory, dtType[0]) == "string");
        }

        toml::value data = toml::parse(filename);

        outputs[0] = tableToCompactStruct(data);
    }

private:
    bool isDatetimeType(toml::value_t t) {
        return t == toml::value_t::offset_datetime ||
               t == toml::value_t::local_datetime ||
               t == toml::value_t::local_date ||
               t == toml::value_t::local_time;
    }

    matlab::data::Array makeDatetime(const toml::value& val) {
        std::string str;
        const char* format;
        const char* timeZone = nullptr;

        switch (val.type()) {
            case toml::value_t::offset_datetime:
                str = toml::to_string(val.as_offset_datetime());
                format = "yyyy-MM-dd'T'HH:mm:ssXXX";
                timeZone = "UTC";
                break;
            case toml::value_t::local_datetime:
                str = toml::to_string(val.as_local_datetime());
                format = "yyyy-MM-dd'T'HH:mm:ss";
                break;
            case toml::value_t::local_date:
                str = toml::to_string(val.as_local_date());
                format = "yyyy-MM-dd";
                break;
            case toml::value_t::local_time:
                str = toml::to_string(val.as_local_time());
                format = "HH:mm:ss";
                break;
            default:
                return factory.createArray<double>({0, 0});
        }

        if (datetimeAsString) {
            return makeString(factory, str);
        }

        std::vector<matlab::data::Array> args = {
            makeString(factory, str),
            factory.createCharArray("InputFormat"),
            factory.createCharArray(format)
        };
        if (timeZone) {
            args.push_back(factory.createCharArray("TimeZone"));
            args.push_back(factory.createCharArray(timeZone));
        }
        return engine->feval(u"datetime", args);
    }

    matlab::data::Array tableToCompactStruct(const toml::value& table) {
        const auto& tbl = table.as_table();
        size_t n = tbl.size();

        auto keys = factory.createArray<matlab::data::MATLABString>({1, n});
        auto values = factory.createArray<matlab::data::Array>({1, n});
        std::vector<double> nullIdx, datetimeIdx;

        size_t i = 0;
        for (const auto& [key, val] : tbl) {
            keys[0][i] = matlab::data::MATLABString(
                factory.createCharArrayFromUTF8(key).toUTF16());

            if (val.type() == toml::value_t::table) {
                values[0][i] = tableToCompactStruct(val);
            } else if (val.type() == toml::value_t::array) {
                values[0][i] = convertArray(val.as_array());
            } else if (isDatetimeType(val.type())) {
                datetimeIdx.push_back(static_cast<double>(i + 1));
                values[0][i] = makeDatetime(val);
            } else {
                values[0][i] = convertScalar(val);
            }
            ++i;
        }

        auto nullArr = toDoubleArray(nullIdx);
        auto dtArr = toDoubleArray(datetimeIdx);
        auto emptyArr = factory.createArray<double>({1, 0});

        return makeCompactStruct(factory, keys, values, nullArr, dtArr, emptyArr);
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
                return factory.createArray<double>({0, 0});
        }
    }

    matlab::data::Array convertArray(const toml::array& arr) {
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
                elems.push_back(makeDatetime(elem));
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
