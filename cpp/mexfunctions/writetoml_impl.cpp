#include "writetoml_impl.hpp"
#include "matlab_walker.hpp"

WriteTomlImpl::WriteTomlImpl(
        std::shared_ptr<matlab::engine::MATLABEngine> eng)
    : engine(std::move(eng)) {}

void WriteTomlImpl::execute(matlab::mex::ArgumentList outputs,
                            matlab::mex::ArgumentList inputs) {
    if (inputs.size() < 2) {
        throwMexError(*engine, factory,
            "writetomlMex:InvalidInput",
            "Node tree data required.");
        return;
    }

    matlab::data::Array data = inputs[1];

    arrayStyle = "auto";
    tableStyle = "auto";
    tableArrayStyle = "expanded";
    stringEscapeStyle = "auto";
    stringLayout = "auto";
    addSectionSpacing = true;
    indentSize = 2;
    precision = 6;

    if (inputs.size() > 2) {
        parseOptions(inputs[2]);
    }

    stack.clear();
    rootResult = toml::ordered_value();

    MatlabWalker::walk(data, *this);

    std::string content = toml::format(rootResult);

    if (!addSectionSpacing) {
        content = removeBlankLines(content);
    }

    auto output = factory.createArray<uint8_t>(
        {1, content.size()});
    std::copy(content.begin(), content.end(),
        output.begin());
    outputs[0] = std::move(output);
}

std::string WriteTomlImpl::getOptionString(
        const matlab::data::StructArray& opts,
        const std::string& field) {
    matlab::data::TypedArray<matlab::data::MATLABString> arr =
        opts[0][field];
    return matlabStringToUtf8(arr[0]);
}

double WriteTomlImpl::getOptionDouble(
        const matlab::data::StructArray& opts,
        const std::string& field) {
    matlab::data::TypedArray<double> arr = opts[0][field];
    return arr[0];
}

void WriteTomlImpl::parseOptions(const matlab::data::Array& optsArr) {
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

void WriteTomlImpl::pushToParent(toml::ordered_value val) {
    if (stack.empty()) {
        rootResult = std::move(val);
        return;
    }
    auto& frame = stack.back();
    if (auto* of = std::get_if<ObjectFrame>(&frame)) {
        of->table.push_back({of->pendingKey, std::move(val)});
    } else if (auto* af = std::get_if<ArrayFrame>(&frame)) {
        af->array.push_back(std::move(val));
    }
}

// ── DocumentHandler implementation ──────────────────────────────────

void WriteTomlImpl::startObject(size_t /*count*/) {
    stack.emplace_back(ObjectFrame{});
}

void WriteTomlImpl::key(std::string_view k) {
    auto& of = std::get<ObjectFrame>(stack.back());
    of.pendingKey.assign(k.data(), k.size());
}

void WriteTomlImpl::endObject() {
    auto of = std::get<ObjectFrame>(std::move(stack.back()));
    stack.pop_back();
    pushToParent(toml::ordered_value(std::move(of.table)));
}

void WriteTomlImpl::startArray(size_t /*count*/) {
    stack.emplace_back(ArrayFrame{});
}

void WriteTomlImpl::endArray() {
    auto af = std::get<ArrayFrame>(std::move(stack.back()));
    stack.pop_back();

    toml::array_format_info fmt;
    fmt.body_indent = indentSize;

    if (!af.array.empty() && af.array.front().is_table()) {
        fmt.fmt = resolveTableArrayFormat(af.array);
    } else {
        fmt.fmt = resolveArrayFormat(af.array);
    }

    pushToParent(toml::ordered_value(std::move(af.array), fmt));
}

void WriteTomlImpl::nullValue() {
    // TOML has no null type — discard this value.
    // In object context the pending key is simply overwritten by the next
    // key() call; in array context we omit the element.
}

void WriteTomlImpl::boolValue(bool b) {
    pushToParent(toml::ordered_value(b));
}

void WriteTomlImpl::intValue(int64_t i) {
    pushToParent(toml::ordered_value(
        static_cast<toml::ordered_value::integer_type>(i)));
}

void WriteTomlImpl::uintValue(uint64_t u) {
    pushToParent(toml::ordered_value(
        static_cast<toml::ordered_value::integer_type>(u)));
}

void WriteTomlImpl::doubleValue(double d) {
    pushToParent(convertDouble(d));
}

void WriteTomlImpl::stringValue(std::string_view s) {
    toml::string_format_info fmt;
    fmt.fmt = resolveStringFormat();
    pushToParent(toml::ordered_value(std::string(s), fmt));
}

void WriteTomlImpl::datetimeValue(std::string_view iso) {
    pushToParent(parseDatetimeFromString(std::string(iso)));
}

// ── TOML formatting helpers (unchanged) ─────────────────────────────

toml::ordered_value WriteTomlImpl::convertDouble(double v) {
    if (v == std::floor(v) && std::abs(v) < (1LL << 53)) {
        return toml::ordered_value(
            static_cast<toml::ordered_value::integer_type>(v));
    }
    toml::floating_format_info fmt;
    fmt.prec = static_cast<std::size_t>(precision);
    fmt.fmt = toml::floating_format::defaultfloat;
    return toml::ordered_value(v, fmt);
}

toml::string_format WriteTomlImpl::resolveStringFormat() {
    bool useLiteral = (stringEscapeStyle == "literal");
    bool useMultiline = (stringLayout == "multiline");

    if (useMultiline) {
        return useLiteral ? toml::string_format::multiline_literal
                          : toml::string_format::multiline_basic;
    }
    return useLiteral ? toml::string_format::literal
                      : toml::string_format::basic;
}

toml::ordered_value WriteTomlImpl::parseDatetimeFromString(
        const std::string& dtStr) {
    std::string doc = "v = " + dtStr + "\n";
    std::istringstream iss(doc);
    auto parsed = toml::parse<toml::ordered_type_config>(iss, "");
    return parsed.at("v");
}

toml::array_format WriteTomlImpl::resolveArrayFormat(
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

toml::array_format WriteTomlImpl::resolveTableArrayFormat(
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

std::string WriteTomlImpl::removeBlankLines(const std::string& s) {
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
