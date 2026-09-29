#include "writeyaml_impl.hpp"
#include "matlab_walker.hpp"

WriteYamlImpl::WriteYamlImpl(
        std::shared_ptr<matlab::engine::MATLABEngine> eng)
    : engine(std::move(eng)) {}

void WriteYamlImpl::execute(matlab::mex::ArgumentList outputs,
                            matlab::mex::ArgumentList inputs) {
    if (inputs.size() < 2) {
        throwMexError(*engine, factory,
            "writeyamlMex:InvalidInput",
            "Node tree data required.");
        return;
    }

    matlab::data::Array data = inputs[1];

    flowArrays = false;
    sectionSpacing = true;
    precision = 6;
    if (inputs.size() > 2) {
        parseOptions(inputs[2]);
    }

    tree.clear();
    tree.reserve(64);
    tree.reserve_arena(4096);

    stack.clear();
    hasPendingKey = false;

    MatlabWalker::walk(data, *this);

    std::string yaml =
        ryml::emitrs_yaml<std::string>(tree, tree.root_id());

    if (sectionSpacing) {
        yaml = insertSectionSpacing(yaml);
    }

    auto output = factory.createArray<uint8_t>(
        {1, yaml.size()});
    std::copy(yaml.begin(), yaml.end(),
        output.begin());
    outputs[0] = std::move(output);
}

void WriteYamlImpl::parseOptions(const matlab::data::Array& optsArr) {
    matlab::data::StructArray opts(optsArr);

    matlab::data::TypedArray<matlab::data::MATLABString> as =
        opts[0]["ArrayStyle"];
    flowArrays = (matlabStringToUtf8(as[0]) == "flow");

    matlab::data::TypedArray<matlab::data::MATLABString> ss =
        opts[0]["SectionSpacing"];
    sectionSpacing =
        (matlabStringToUtf8(ss[0]) == "loose");

    matlab::data::TypedArray<double> prec = opts[0]["Precision"];
    precision = static_cast<int>(prec[0]);
}

ryml::csubstr WriteYamlImpl::toArena(const std::string& s) {
    return tree.copy_to_arena(
        ryml::csubstr(s.data(), s.size()));
}

ryml::type_bits WriteYamlImpl::seqFlags() {
    return flowArrays
        ? (ryml::SEQ | ryml::FLOW_SL)
        : ryml::SEQ;
}

void WriteYamlImpl::setNodeValue(ryml::NodeRef node,
                                 const std::string& text, bool quoted) {
    ryml::csubstr arenaVal = toArena(text);
    if (quoted) {
        node.set_val(arenaVal, ryml::VAL_DQUO);
    } else {
        node.set_val(arenaVal);
    }
}

ryml::NodeRef WriteYamlImpl::allocChild() {
    ryml::NodeRef parent = stack.back();
    ryml::NodeRef child = parent.append_child();
    if (hasPendingKey) {
        child.set_key(toArena(pendingKey));
        hasPendingKey = false;
    }
    return child;
}

// ── DocumentHandler implementation ──────────────────────────────────

void WriteYamlImpl::startObject(size_t /*count*/) {
    ryml::NodeRef node;
    if (stack.empty()) {
        node = tree.rootref();
    } else {
        node = allocChild();
    }
    node |= ryml::MAP;
    stack.push_back(node);
}

void WriteYamlImpl::key(std::string_view k) {
    pendingKey.assign(k.data(), k.size());
    hasPendingKey = true;
}

void WriteYamlImpl::endObject() {
    stack.pop_back();
}

void WriteYamlImpl::startArray(size_t count) {
    ryml::NodeRef node;
    if (stack.empty()) {
        node = tree.rootref();
    } else {
        node = allocChild();
    }
    if (count == 0) {
        node |= (ryml::SEQ | ryml::FLOW_SL);
    } else {
        node |= seqFlags();
    }
    stack.push_back(node);
}

void WriteYamlImpl::endArray() {
    stack.pop_back();
}

void WriteYamlImpl::nullValue() {
    ryml::NodeRef child = allocChild();
    child.set_val(toArena("null"));
}

void WriteYamlImpl::boolValue(bool b) {
    ryml::NodeRef child = allocChild();
    setNodeValue(child, b ? "true" : "false", false);
}

void WriteYamlImpl::intValue(int64_t i) {
    ryml::NodeRef child = allocChild();
    setNodeValue(child, formatInt(i), false);
}

void WriteYamlImpl::uintValue(uint64_t u) {
    ryml::NodeRef child = allocChild();
    char buf[32];
    auto [ptr, ec] = std::to_chars(buf, buf + sizeof(buf), u);
    setNodeValue(child, std::string(buf, ptr), false);
}

void WriteYamlImpl::doubleValue(double d) {
    ryml::NodeRef child = allocChild();
    setNodeValue(child, formatDouble(d), false);
}

void WriteYamlImpl::stringValue(std::string_view s) {
    ryml::NodeRef child = allocChild();
    std::string text(s);
    setNodeValue(child, text, needsQuoting(text));
}

void WriteYamlImpl::datetimeValue(std::string_view iso) {
    ryml::NodeRef child = allocChild();
    std::string text(iso);
    setNodeValue(child, text, false);
}

// ── YAML formatting helpers (unchanged) ─────────────────────────────

bool WriteYamlImpl::needsQuoting(const std::string& s) {
    if (s.empty()) return true;

    char c0 = s[0];
    if (c0 == '!' || c0 == '#' || c0 == '&' || c0 == '*' ||
        c0 == '{' || c0 == '[' || c0 == '|' || c0 == '>' ||
        c0 == '@' || c0 == '`')
        return true;

    if (s.find(": ") != std::string::npos ||
        s.find(" #") != std::string::npos)
        return true;

    if (looksLikeBoolOrNull(s)) return true;
    if (looksLikeNumber(s)) return true;
    if (looksLikeDate(s)) return true;

    return false;
}

bool WriteYamlImpl::ciEquals(const std::string& s, const char* target) {
    size_t len = std::strlen(target);
    if (s.size() != len) return false;
    for (size_t i = 0; i < len; ++i) {
        if (std::tolower(static_cast<unsigned char>(s[i])) !=
            static_cast<unsigned char>(target[i]))
            return false;
    }
    return true;
}

bool WriteYamlImpl::looksLikeBoolOrNull(const std::string& s) {
    return ciEquals(s, "true") || ciEquals(s, "false") ||
           ciEquals(s, "null") || ciEquals(s, "yes") ||
           ciEquals(s, "no") || ciEquals(s, "on") ||
           ciEquals(s, "off") || s == "~";
}

bool WriteYamlImpl::looksLikeNumber(const std::string& s) {
    if (s.empty()) return false;

    if (s == ".inf" || s == ".Inf" || s == ".INF" ||
        s == "-.inf" || s == "-.Inf" || s == "-.INF" ||
        s == "+.inf" || s == "+.Inf" || s == "+.INF" ||
        s == ".nan" || s == ".NaN" || s == ".NAN")
        return true;

    if (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
        return s.find_first_not_of("0123456789abcdefABCDEF", 2)
            == std::string::npos;
    }
    if (s.size() > 2 && s[0] == '0' && (s[1] == 'o' || s[1] == 'O')) {
        return s.find_first_not_of("01234567", 2)
            == std::string::npos;
    }

    size_t pos = 0;
    if (pos < s.size() && (s[pos] == '+' || s[pos] == '-')) ++pos;
    bool hasDigit = false;
    bool hasDot = false;
    while (pos < s.size() &&
           (std::isdigit(static_cast<unsigned char>(s[pos])) ||
            s[pos] == '.')) {
        if (s[pos] == '.') {
            if (hasDot) return false;
            hasDot = true;
        } else {
            hasDigit = true;
        }
        ++pos;
    }
    if (!hasDigit) return false;
    if (pos < s.size() && (s[pos] == 'e' || s[pos] == 'E')) {
        ++pos;
        if (pos < s.size() && (s[pos] == '+' || s[pos] == '-')) ++pos;
        if (pos >= s.size() ||
            !std::isdigit(static_cast<unsigned char>(s[pos])))
            return false;
        while (pos < s.size() &&
               std::isdigit(static_cast<unsigned char>(s[pos])))
            ++pos;
    }
    return pos == s.size();
}

bool WriteYamlImpl::looksLikeDate(const std::string& s) {
    if (s.size() < 10) return false;
    return s[4] == '-' && s[7] == '-' &&
        std::isdigit(static_cast<unsigned char>(s[0])) &&
        std::isdigit(static_cast<unsigned char>(s[1])) &&
        std::isdigit(static_cast<unsigned char>(s[2])) &&
        std::isdigit(static_cast<unsigned char>(s[3])) &&
        std::isdigit(static_cast<unsigned char>(s[5])) &&
        std::isdigit(static_cast<unsigned char>(s[6])) &&
        std::isdigit(static_cast<unsigned char>(s[8])) &&
        std::isdigit(static_cast<unsigned char>(s[9]));
}

std::string WriteYamlImpl::formatDouble(double val) {
    if (std::isnan(val)) return ".nan";
    if (std::isinf(val)) return val > 0 ? ".inf" : "-.inf";
    if (val == std::floor(val) && std::abs(val) < (1LL << 53)) {
        char buf[32];
        auto [ptr, ec] = std::to_chars(buf, buf + sizeof(buf),
            static_cast<int64_t>(val));
        return std::string(buf, ptr);
    }
    char buf[64];
    std::snprintf(buf, sizeof(buf), "%.*g", precision, val);
    return buf;
}

std::string WriteYamlImpl::formatInt(int64_t val) {
    char buf[32];
    auto [ptr, ec] = std::to_chars(buf, buf + sizeof(buf), val);
    return std::string(buf, ptr);
}

std::string WriteYamlImpl::insertSectionSpacing(const std::string& yaml) {
    if (yaml.empty()) return yaml;

    std::string result;
    result.reserve(yaml.size() + 100);

    bool firstTopLevel = true;
    size_t i = 0;
    while (i < yaml.size()) {
        bool lineStart = (i == 0) || (yaml[i - 1] == '\n');
        if (lineStart && yaml[i] != ' ' && yaml[i] != '\n') {
            if (!firstTopLevel) {
                result += '\n';
            }
            firstTopLevel = false;
        }
        result += yaml[i];
        i++;
    }
    return result;
}
