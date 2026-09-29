#include "readtoml_impl.hpp"
#include "matlab_builder.hpp"

ReadTomlImpl::ReadTomlImpl(
        std::shared_ptr<matlab::engine::MATLABEngine> eng)
    : engine(std::move(eng)) {}

void ReadTomlImpl::execute(matlab::mex::ArgumentList outputs,
                           matlab::mex::ArgumentList inputs) {
    if (inputs.size() < 3) {
        throwMexError(*engine, factory,
            "readtomlMex:InvalidInput",
            "File content and filename required.");
        return;
    }

    matlab::data::TypedArray<uint8_t> contentArr = inputs[1];
    std::string content(contentArr.begin(), contentArr.end());

    matlab::data::TypedArray<matlab::data::MATLABString> filenameArr =
        inputs[2];
    std::string filename = matlabStringToUtf8(filenameArr[0]);

    std::istringstream iss(std::move(content));
    toml::ordered_value data =
        toml::parse<toml::ordered_type_config>(iss, filename);

    MatlabBuilder builder;
    emitTable(data, builder);
    outputs[0] = builder.result();
}

bool ReadTomlImpl::isDatetimeType(toml::value_t t) {
    return t == toml::value_t::offset_datetime ||
           t == toml::value_t::local_datetime ||
           t == toml::value_t::local_date ||
           t == toml::value_t::local_time;
}

std::string ReadTomlImpl::datetimeToString(
        const toml::ordered_value& val) {
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

void ReadTomlImpl::emitTable(const toml::ordered_value& table,
                             DocumentHandler& handler) {
    const auto& tbl = table.as_table();
    handler.startObject(tbl.size());

    for (const auto& [key, val] : tbl) {
        handler.key(key);
        emitValue(val, handler);
    }

    handler.endObject();
}

void ReadTomlImpl::emitValue(const toml::ordered_value& val,
                             DocumentHandler& handler) {
    auto t = val.type();

    if (t == toml::value_t::table) {
        emitTable(val, handler);
    } else if (t == toml::value_t::array) {
        emitArray(val.as_array(), handler);
    } else if (isDatetimeType(t)) {
        std::string iso = datetimeToString(val);
        handler.datetimeValue(iso);
    } else {
        emitScalar(val, handler);
    }
}

void ReadTomlImpl::emitArray(const toml::ordered_array& arr,
                             DocumentHandler& handler) {
    handler.startArray(arr.size());
    for (const auto& elem : arr) {
        emitValue(elem, handler);
    }
    handler.endArray();
}

void ReadTomlImpl::emitScalar(const toml::ordered_value& val,
                              DocumentHandler& handler) {
    switch (val.type()) {
        case toml::value_t::boolean:
            handler.boolValue(val.as_boolean());
            break;
        case toml::value_t::integer:
            handler.intValue(val.as_integer());
            break;
        case toml::value_t::floating:
            handler.doubleValue(val.as_floating());
            break;
        case toml::value_t::string:
            handler.stringValue(val.as_string());
            break;
        default:
            break;
    }
}
