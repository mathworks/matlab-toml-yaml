#include "util.hpp"
#include "mexAdapter.hpp"
#include "toml.hpp"

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

        toml::value data;
        try {
            data = toml::parse(filename);
        } catch (const std::exception& e) {
            throwMexError(*engine, factory,
                "readtomlMex:ParseError", e.what());
            return;
        }

        outputs[0] = tableToData(data);
    }

private:
    matlab::data::Array makeDatetime(const std::string& str,
                                      const char* format,
                                      const char* timeZone = nullptr) {
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

    matlab::data::Array tableToData(const toml::value& table) {
        auto obj = engine->feval(u"matlab.io.config.TOMLData",
                                  std::vector<matlab::data::Array>{});

        for (const auto& [key, val] : table.as_table()) {
            obj = engine->feval(u"setfield",
                {obj, factory.createCharArrayFromUTF8(key),
                 convert(val)});
        }
        return obj;
    }

    matlab::data::Array convert(const toml::value& val) {
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

            case toml::value_t::table:
                return tableToData(val);

            case toml::value_t::array:
                return convertArray(val.as_array());

            case toml::value_t::offset_datetime:
                return makeDatetime(
                    toml::to_string(val.as_offset_datetime()),
                    "yyyy-MM-dd'T'HH:mm:ssXXX", "UTC");

            case toml::value_t::local_datetime:
                return makeDatetime(
                    toml::to_string(val.as_local_datetime()),
                    "yyyy-MM-dd'T'HH:mm:ss");

            case toml::value_t::local_date:
                return makeDatetime(
                    toml::to_string(val.as_local_date()),
                    "yyyy-MM-dd");

            case toml::value_t::local_time:
                return makeDatetime(
                    toml::to_string(val.as_local_time()),
                    "HH:mm:ss");

            default:
                return engine->feval(u"missing",
                    std::vector<matlab::data::Array>{});
        }
    }

    matlab::data::Array convertArray(const toml::array& arr) {
        if (arr.empty()) {
            return factory.createArray<double>({0, 0});
        }

        std::vector<matlab::data::Array> elems;
        elems.reserve(arr.size());
        for (const auto& elem : arr) {
            elems.push_back(convert(elem));
        }

        auto firstType = arr.front().type();
        bool homogeneous = std::all_of(arr.begin(), arr.end(),
            [&](const toml::value& v) {
                return v.type() == firstType;
            });

        if (homogeneous && firstType == toml::value_t::table) {
            return engine->feval(u"vertcat", elems);
        }
        if (homogeneous && firstType != toml::value_t::array) {
            return engine->feval(u"horzcat", elems);
        }

        auto out = factory.createArray<matlab::data::Array>(
            {1, arr.size()});
        for (size_t i = 0; i < elems.size(); ++i) {
            out[0][i] = std::move(elems[i]);
        }
        return out;
    }
};
