#include "mex.hpp"
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
            throwError("readtomlMex:InvalidInput", "Filename required.");
            return;
        }

        std::string filename = matlabCharToUtf8(
            engine->feval(u"char", {inputs[0]}));

        datetimeAsString = false;
        if (inputs.size() > 1) {
            matlab::data::Array dtType = engine->feval(u"getfield",
                {inputs[1], factory.createCharArray("DatetimeType")});
            std::string val = matlabCharToUtf8(
                engine->feval(u"char", {dtType}));
            datetimeAsString = (val == "string");
        }

        toml::value data;
        try {
            data = toml::parse(filename);
        } catch (const std::exception& e) {
            throwError("readtomlMex:ParseError", e.what());
            return;
        }

        outputs[0] = tableToData(data);
    }

private:
    void throwError(const std::string& id, const std::string& msg) {
        engine->feval(u"error",
            {factory.createCharArray(id), factory.createCharArray(msg)});
    }

    std::string matlabCharToUtf8(const matlab::data::Array& charArr) {
        matlab::data::TypedArray<uint8_t> bytes = engine->feval(
            u"unicode2native",
            {charArr, factory.createCharArray("UTF-8")});
        std::string out;
        out.reserve(bytes.getNumberOfElements());
        for (auto b : bytes) {
            out += static_cast<char>(b);
        }
        return out;
    }

    matlab::data::Array makeString(const std::string& utf8) {
        auto bytes = factory.createArray<uint8_t>({1, utf8.size()});
        for (size_t i = 0; i < utf8.size(); ++i) {
            bytes[0][i] = static_cast<uint8_t>(utf8[i]);
        }
        auto chars = engine->feval(u"native2unicode",
            {std::move(bytes), factory.createCharArray("UTF-8")});
        return engine->feval(u"string", {chars});
    }

    matlab::data::Array makeDatetime(const std::string& str,
                                      const char* format,
                                      const char* timeZone = nullptr) {
        if (datetimeAsString) {
            return makeString(str);
        }
        std::vector<matlab::data::Array> args = {
            makeString(str),
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
                {obj, factory.createCharArray(key), convert(val)});
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
                return makeString(val.as_string());

            case toml::value_t::table:
                return tableToData(val);

            case toml::value_t::array:
                return convertArray(val.as_array());

            case toml::value_t::offset_datetime:
                return makeDatetime(toml::to_string(val.as_offset_datetime()),
                    "yyyy-MM-dd'T'HH:mm:ssXXX", "UTC");

            case toml::value_t::local_datetime:
                return makeDatetime(toml::to_string(val.as_local_datetime()),
                    "yyyy-MM-dd'T'HH:mm:ss");

            case toml::value_t::local_date:
                return makeDatetime(toml::to_string(val.as_local_date()),
                    "yyyy-MM-dd");

            case toml::value_t::local_time:
                return makeDatetime(toml::to_string(val.as_local_time()),
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

        // Mixed types or nested arrays → cell array
        auto out = factory.createArray<matlab::data::Array>(
            {1, arr.size()});
        for (size_t i = 0; i < elems.size(); ++i) {
            out[0][i] = std::move(elems[i]);
        }
        return out;
    }
};
