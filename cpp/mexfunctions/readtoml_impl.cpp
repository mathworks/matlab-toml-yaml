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
    toml::ordered_value data;
    try {
        data = toml::parse<toml::ordered_type_config>(iss, filename);
    } catch (const toml::syntax_error& e) {
        const auto& errs = e.errors();
        std::string msg = errs.empty()
            ? std::string(e.what())
            : toml::format_error(errs.front());
        throwMexError(*engine, factory, "readtoml:ParseError", msg);
        return;
    }

    MatlabBuilder builder;
    emitValue(data, builder, true);
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

std::vector<std::string> ReadTomlImpl::commentLines(
        const toml::ordered_value& val) {
    std::vector<std::string> lines;
    for (const auto& c : val.comments()) {
        std::string line = c;
        if (!line.empty() && line[0] == '#') line.erase(0, 1);
        if (!line.empty() && line[0] == ' ') line.erase(0, 1);
        lines.push_back(std::move(line));
    }
    return lines;
}

// Record only formats that differ from the writer defaults, so files
// without special formatting produce the same node tree as before.
NodeMeta ReadTomlImpl::valueMeta(const toml::ordered_value& val,
                                 bool includeComments) {
    NodeMeta m;
    switch (val.type()) {
    case toml::value_t::integer:
        switch (val.as_integer_fmt().fmt) {
        case toml::integer_format::hex: m.fields["IntegerFormat"] = "hex"; break;
        case toml::integer_format::oct: m.fields["IntegerFormat"] = "oct"; break;
        case toml::integer_format::bin: m.fields["IntegerFormat"] = "bin"; break;
        default: break;
        }
        break;
    case toml::value_t::floating:
        if (val.as_floating_fmt().fmt == toml::floating_format::scientific) {
            m.fields["FloatFormat"] = "scientific";
        }
        break;
    case toml::value_t::string:
        switch (val.as_string_fmt().fmt) {
        case toml::string_format::literal:
            m.fields["StringEscapeStyle"] = "literal"; break;
        case toml::string_format::multiline_basic:
            m.fields["StringLayout"] = "multiline"; break;
        case toml::string_format::multiline_literal:
            m.fields["StringEscapeStyle"] = "literal";
            m.fields["StringLayout"] = "multiline"; break;
        default: break;
        }
        break;
    case toml::value_t::array: {
        bool ofTables = !val.as_array().empty() &&
            val.as_array().front().is_table();
        auto fmt = val.as_array_fmt().fmt;
        if (ofTables) {
            if (fmt == toml::array_format::oneline ||
                fmt == toml::array_format::multiline) {
                m.fields["TableArrayStyle"] = "inline";
            }
        } else if (fmt == toml::array_format::multiline) {
            m.fields["ArrayStyle"] = "block";
        }
        break;
    }
    case toml::value_t::table:
        switch (val.as_table_fmt().fmt) {
        case toml::table_format::oneline:
        case toml::table_format::multiline_oneline:
            m.fields["TableStyle"] = "inline"; break;
        case toml::table_format::dotted:
            m.fields["TableStyle"] = "dotted"; break;
        default: break;
        }
        break;
    default:
        break;
    }
    if (includeComments) m.comments = commentLines(val);
    return m;
}

void ReadTomlImpl::emitTable(const toml::ordered_value& table,
                             DocumentHandler& handler) {
    const auto& tbl = table.as_table();
    handler.startObject(tbl.size());

    for (const auto& [key, val] : tbl) {
        handler.key(key);
        // Comments on a table entry belong to the key.
        NodeMeta km;
        km.comments = commentLines(val);
        if (!km.empty()) handler.keyMetadata(km);
        emitValue(val, handler, false);
    }

    handler.endObject();
}

void ReadTomlImpl::emitValue(const toml::ordered_value& val,
                             DocumentHandler& handler,
                             bool includeComments) {
    NodeMeta m = valueMeta(val, includeComments);
    if (!m.empty()) handler.metadata(m);

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
        emitValue(elem, handler, true);
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
