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
    pendingMeta = NodeMeta();

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

NodeMeta WriteTomlImpl::takeMeta() {
    NodeMeta m = std::move(pendingMeta);
    pendingMeta = NodeMeta();
    return m;
}

void WriteTomlImpl::addComments(toml::ordered_value& val,
                                const std::vector<std::string>& lines) {
    for (const auto& line : lines) {
        val.comments().push_back(line.empty() ? "#" : "# " + line);
    }
}

void WriteTomlImpl::metadata(const NodeMeta& m) {
    pendingMeta = m;
}

void WriteTomlImpl::keyMetadata(const NodeMeta& m) {
    if (auto* of = std::get_if<ObjectFrame>(&stack.back())) {
        of->pendingKeyComments = m.comments;
    }
}

void WriteTomlImpl::pushToParent(toml::ordered_value val) {
    if (stack.empty()) {
        rootResult = std::move(val);
        return;
    }
    auto& frame = stack.back();
    if (auto* of = std::get_if<ObjectFrame>(&frame)) {
        addComments(val, of->pendingKeyComments);
        of->pendingKeyComments.clear();
        of->table.push_back({of->pendingKey, std::move(val)});
    } else if (auto* af = std::get_if<ArrayFrame>(&frame)) {
        af->array.push_back(std::move(val));
    }
}

// ── DocumentHandler implementation ──────────────────────────────────

void WriteTomlImpl::startObject(size_t /*count*/) {
    ObjectFrame of;
    of.meta = takeMeta();
    stack.emplace_back(std::move(of));
}

void WriteTomlImpl::key(std::string_view k) {
    auto& of = std::get<ObjectFrame>(stack.back());
    of.pendingKey.assign(k.data(), k.size());
    of.pendingKeyComments.clear();
}

void WriteTomlImpl::endObject() {
    auto of = std::get<ObjectFrame>(std::move(stack.back()));
    stack.pop_back();

    toml::table_format_info fmt;
    std::string style = of.meta.get("TableStyle");
    if (style == "inline") {
        fmt.fmt = toml::table_format::oneline;
    } else if (style == "dotted") {
        fmt.fmt = toml::table_format::dotted;
    }
    toml::ordered_value val(std::move(of.table), fmt);
    addComments(val, of.meta.comments);
    pushToParent(std::move(val));
}

void WriteTomlImpl::startArray(size_t /*count*/) {
    ArrayFrame af;
    af.meta = takeMeta();
    stack.emplace_back(std::move(af));
}

void WriteTomlImpl::endArray() {
    auto af = std::get<ArrayFrame>(std::move(stack.back()));
    stack.pop_back();

    toml::array_format_info fmt;
    fmt.body_indent = indentSize;

    // Per-node metadata takes precedence over the global writer options.
    if (!af.array.empty() && af.array.front().is_table()) {
        std::string style = af.meta.get("TableArrayStyle");
        if (style == "inline") {
            fmt.fmt = toml::array_format::oneline;
        } else if (style == "expanded") {
            fmt.fmt = toml::array_format::array_of_tables;
        } else {
            fmt.fmt = resolveTableArrayFormat(af.array);
        }
    } else {
        std::string style = af.meta.get("ArrayStyle");
        if (style == "flow") {
            fmt.fmt = toml::array_format::oneline;
        } else if (style == "block") {
            fmt.fmt = toml::array_format::multiline;
        } else {
            fmt.fmt = resolveArrayFormat(af.array);
        }
    }

    toml::ordered_value val(std::move(af.array), fmt);
    addComments(val, af.meta.comments);
    pushToParent(std::move(val));
}

void WriteTomlImpl::nullValue() {
    pendingMeta = NodeMeta();
    // TOML has no null type — discard this value.
    // In object context the pending key is simply overwritten by the next
    // key() call; in array context we omit the element.
}

void WriteTomlImpl::boolValue(bool b) {
    NodeMeta m = takeMeta();
    toml::ordered_value val(b);
    addComments(val, m.comments);
    pushToParent(std::move(val));
}

void WriteTomlImpl::intValue(int64_t i) {
    NodeMeta m = takeMeta();
    toml::integer_format_info fmt;
    std::string f = m.get("IntegerFormat");
    if (f == "hex") {
        fmt.fmt = toml::integer_format::hex;
    } else if (f == "oct") {
        fmt.fmt = toml::integer_format::oct;
    } else if (f == "bin") {
        fmt.fmt = toml::integer_format::bin;
    }
    // TOML only allows hex/oct/bin for non-negative integers.
    if (i < 0) fmt.fmt = toml::integer_format::dec;
    if (!m.get("FloatFormat").empty()) {
        pendingMeta = std::move(m);
        doubleValue(static_cast<double>(i));
        return;
    }
    toml::ordered_value val(
        static_cast<toml::ordered_value::integer_type>(i), fmt);
    addComments(val, m.comments);
    pushToParent(std::move(val));
}

void WriteTomlImpl::uintValue(uint64_t u) {
    if (u > static_cast<uint64_t>(std::numeric_limits<int64_t>::max())) {
        throwMexError(*engine, factory, "writetoml:IntegerOverflow",
            "Value " + std::to_string(u) +
            " exceeds TOML's signed 64-bit integer range.");
        return;
    }
    intValue(static_cast<int64_t>(u));
}

void WriteTomlImpl::doubleValue(double d) {
    NodeMeta m = takeMeta();
    std::string f = m.get("FloatFormat");
    toml::ordered_value val;
    if (f == "scientific" || f == "fixed") {
        toml::floating_format_info fmt;
        fmt.prec = static_cast<std::size_t>(precision);
        fmt.fmt = (f == "scientific") ? toml::floating_format::scientific
                                      : toml::floating_format::fixed;
        val = toml::ordered_value(d, fmt);
    } else {
        val = convertDouble(d);
    }
    addComments(val, m.comments);
    pushToParent(std::move(val));
}

void WriteTomlImpl::stringValue(std::string_view s) {
    NodeMeta m = takeMeta();
    toml::string_format_info fmt;
    fmt.fmt = resolveStringFormat(m.get("StringEscapeStyle"),
                                  m.get("StringLayout"));

    std::string str(s);
    bool hasNewline = str.find('\n') != std::string::npos;
    bool hasApostrophe = str.find('\'') != std::string::npos;
    bool hasTripleApostrophe = str.find("'''") != std::string::npos;

    if (fmt.fmt == toml::string_format::literal) {
        if (hasNewline && !hasApostrophe) {
            fmt.fmt = toml::string_format::multiline_literal;
        } else if (hasNewline) {
            fmt.fmt = toml::string_format::multiline_basic;
        } else if (hasApostrophe) {
            fmt.fmt = toml::string_format::basic;
        }
    } else if (fmt.fmt == toml::string_format::multiline_literal) {
        if (hasTripleApostrophe) {
            fmt.fmt = toml::string_format::multiline_basic;
        }
    }

    bool isMultiline =
        fmt.fmt == toml::string_format::multiline_basic ||
        fmt.fmt == toml::string_format::multiline_literal;
    if (isMultiline && !str.empty() && str[0] == '\n') {
        fmt.start_with_newline = true;
    }

    toml::ordered_value val(std::move(str), fmt);
    addComments(val, m.comments);
    pushToParent(std::move(val));
}

void WriteTomlImpl::datetimeValue(std::string_view iso) {
    NodeMeta m = takeMeta();
    toml::ordered_value val = parseDatetimeFromString(std::string(iso));
    addComments(val, m.comments);
    pushToParent(std::move(val));
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

toml::string_format WriteTomlImpl::resolveStringFormat(
        const std::string& escapeStyle, const std::string& layout) {
    // Per-node metadata takes precedence over the global writer options.
    const std::string& escape = escapeStyle.empty() ? stringEscapeStyle : escapeStyle;
    const std::string& lines = layout.empty() ? stringLayout : layout;
    bool useLiteral = (escape == "literal");
    bool useMultiline = (lines == "multiline");

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
    bool inMultilineBasic = false;
    bool inMultilineLiteral = false;
    size_t len = s.size();

    for (size_t i = 0; i < len; ++i) {
        char c = s[i];

        if (inMultilineBasic && c == '\\' && i + 1 < len) {
            result += c;
            result += s[++i];
            prevNewline = false;
            continue;
        }

        if (!inMultilineLiteral && i + 2 < len &&
            c == '"' && s[i+1] == '"' && s[i+2] == '"') {
            inMultilineBasic = !inMultilineBasic;
            result += c; result += s[i+1]; result += s[i+2];
            i += 2;
            prevNewline = false;
            continue;
        }

        if (!inMultilineBasic && i + 2 < len &&
            c == '\'' && s[i+1] == '\'' && s[i+2] == '\'') {
            inMultilineLiteral = !inMultilineLiteral;
            result += c; result += s[i+1]; result += s[i+2];
            i += 2;
            prevNewline = false;
            continue;
        }

        if (inMultilineBasic || inMultilineLiteral) {
            result += c;
            prevNewline = false;
            continue;
        }

        if (c == '\n') {
            if (prevNewline) continue;
            prevNewline = true;
        } else {
            prevNewline = false;
        }
        result += c;
    }
    return result;
}
