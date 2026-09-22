#define RYML_WITH_LEGACY_OPERATORS
#include "util.hpp"
#include "mexAdapter.hpp"
#include "ryml_util.hpp"

#include <vector>
#include <cmath>
#include <cstdio>
#include <cstdint>
#include <charconv>
#include <cstring>
#include <cctype>

using matlab::data::ArrayType;

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;

    ryml::Tree tree;
    bool flowArrays = false;
    bool sectionSpacing = true;
    int precision = 6;

public:
    MexFunction() { installRymlErrorHandlers(); }

    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.size() < 1) {
            throwMexError(*engine, factory,
                "writeyamlMex:InvalidInput",
                "Node tree data required.");
            return;
        }

        matlab::data::Array data = inputs[0];

        flowArrays = false;
        sectionSpacing = true;
        precision = 6;
        if (inputs.size() > 1) {
            parseOptions(inputs[1]);
        }

        tree.clear();
        tree.reserve(64);
        tree.reserve_arena(4096);

        ryml::NodeRef root = tree.rootref();
        root |= ryml::MAP;
        buildMap(root, data);

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

private:

    // --- Option parsing ---

    void parseOptions(const matlab::data::Array& optsArr) {
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

    // --- Arena helper ---

    ryml::csubstr toArena(const std::string& s) {
        return tree.copy_to_arena(
            ryml::csubstr(s.data(), s.size()));
    }

    ryml::type_bits seqFlags() {
        return flowArrays
            ? (ryml::SEQ | ryml::FLOW_SL)
            : ryml::SEQ;
    }

    void setNodeValue(ryml::NodeRef node,
                      const std::string& text, bool quoted) {
        ryml::csubstr arenaVal = toArena(text);
        if (quoted) {
            node.set_val(arenaVal, ryml::VAL_DQUO);
        } else {
            node.set_val(arenaVal);
        }
    }

    // --- Scalar formatting ---

    static bool needsQuoting(const std::string& s) {
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

    static bool ciEquals(const std::string& s, const char* target) {
        size_t len = std::strlen(target);
        if (s.size() != len) return false;
        for (size_t i = 0; i < len; ++i) {
            if (std::tolower(static_cast<unsigned char>(s[i])) !=
                static_cast<unsigned char>(target[i]))
                return false;
        }
        return true;
    }

    static bool looksLikeBoolOrNull(const std::string& s) {
        return ciEquals(s, "true") || ciEquals(s, "false") ||
               ciEquals(s, "null") || ciEquals(s, "yes") ||
               ciEquals(s, "no") || ciEquals(s, "on") ||
               ciEquals(s, "off") || s == "~";
    }

    static bool looksLikeNumber(const std::string& s) {
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

    static bool looksLikeDate(const std::string& s) {
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

    std::string formatDouble(double val) {
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

    static bool isIntegerType(ArrayType type) {
        return type == ArrayType::INT8 || type == ArrayType::INT16 ||
               type == ArrayType::INT32 || type == ArrayType::INT64 ||
               type == ArrayType::UINT8 || type == ArrayType::UINT16 ||
               type == ArrayType::UINT32 || type == ArrayType::UINT64;
    }

    static int64_t readIntScalar(const matlab::data::Array& val) {
        switch (val.getType()) {
        case ArrayType::INT8:   { matlab::data::TypedArray<int8_t>   a = val; return a[0]; }
        case ArrayType::INT16:  { matlab::data::TypedArray<int16_t>  a = val; return a[0]; }
        case ArrayType::INT32:  { matlab::data::TypedArray<int32_t>  a = val; return a[0]; }
        case ArrayType::INT64:  { matlab::data::TypedArray<int64_t>  a = val; return a[0]; }
        case ArrayType::UINT8:  { matlab::data::TypedArray<uint8_t>  a = val; return a[0]; }
        case ArrayType::UINT16: { matlab::data::TypedArray<uint16_t> a = val; return a[0]; }
        case ArrayType::UINT32: { matlab::data::TypedArray<uint32_t> a = val; return a[0]; }
        case ArrayType::UINT64: { matlab::data::TypedArray<uint64_t> a = val; return static_cast<int64_t>(a[0]); }
        default: return 0;
        }
    }

    static std::vector<int64_t> readIntArray(
            const matlab::data::Array& val) {
        size_t n = val.getNumberOfElements();
        std::vector<int64_t> out(n);
        switch (val.getType()) {
        case ArrayType::INT8:   { matlab::data::TypedArray<int8_t>   a = val; for (size_t i = 0; i < n; ++i) out[i] = a[i]; break; }
        case ArrayType::INT16:  { matlab::data::TypedArray<int16_t>  a = val; for (size_t i = 0; i < n; ++i) out[i] = a[i]; break; }
        case ArrayType::INT32:  { matlab::data::TypedArray<int32_t>  a = val; for (size_t i = 0; i < n; ++i) out[i] = a[i]; break; }
        case ArrayType::INT64:  { matlab::data::TypedArray<int64_t>  a = val; for (size_t i = 0; i < n; ++i) out[i] = a[i]; break; }
        case ArrayType::UINT8:  { matlab::data::TypedArray<uint8_t>  a = val; for (size_t i = 0; i < n; ++i) out[i] = a[i]; break; }
        case ArrayType::UINT16: { matlab::data::TypedArray<uint16_t> a = val; for (size_t i = 0; i < n; ++i) out[i] = a[i]; break; }
        case ArrayType::UINT32: { matlab::data::TypedArray<uint32_t> a = val; for (size_t i = 0; i < n; ++i) out[i] = a[i]; break; }
        case ArrayType::UINT64: { matlab::data::TypedArray<uint64_t> a = val; for (size_t i = 0; i < n; ++i) out[i] = static_cast<int64_t>(a[i]); break; }
        default: break;
        }
        return out;
    }

    std::string formatInt(int64_t val) {
        char buf[32];
        auto [ptr, ec] = std::to_chars(buf, buf + sizeof(buf), val);
        return std::string(buf, ptr);
    }

    void formatAndSetScalar(ryml::NodeRef node,
                            const matlab::data::Array& val) {
        auto type = val.getType();

        if (type == ArrayType::LOGICAL) {
            matlab::data::TypedArray<bool> arr = val;
            setNodeValue(node, arr[0] ? "true" : "false", false);
            return;
        }

        if (type == ArrayType::DOUBLE || type == ArrayType::SINGLE) {
            matlab::data::TypedArray<double> arr = val;
            setNodeValue(node, formatDouble(arr[0]), false);
            return;
        }

        if (isIntegerType(type)) {
            setNodeValue(node, formatInt(readIntScalar(val)), false);
            return;
        }

        if (type == ArrayType::MATLAB_STRING) {
            matlab::data::TypedArray<matlab::data::MATLABString> arr = val;
            std::string text = matlabStringToUtf8(arr[0]);
            setNodeValue(node, text, needsQuoting(text));
            return;
        }

        throwMexError(*engine, factory,
            "writeyamlMex:UnsupportedType",
            "Unsupported scalar type in node tree.");
    }

    // --- Tree building from node tree ---

    void buildMap(ryml::NodeRef mapNode,
                  const matlab::data::Array& nodeArr) {
        matlab::data::StructArray node(nodeArr);

        matlab::data::TypedArray<matlab::data::MATLABString> keys =
            node[0]["Keys"];
        matlab::data::TypedArray<matlab::data::Array> values =
            node[0]["Values"];

        size_t n = keys.getNumberOfElements();

        for (size_t i = 0; i < n; ++i) {
            std::string key = matlabStringToUtf8(keys[i]);

            ryml::NodeRef child = mapNode.append_child();
            child.set_key(toArena(key));

            buildValue(child, values[i]);
        }
    }

    void buildValue(ryml::NodeRef node,
                    const matlab::data::Array& val) {
        auto type = val.getType();
        size_t numel = val.getNumberOfElements();

        if (type == ArrayType::STRUCT) {
            matlab::data::StructArray sa(val);
            if (structHasField(sa, "Keys")) {
                node |= ryml::MAP;
                buildMap(node, val);
                return;
            }
            if (structHasField(sa, "Data")) {
                buildValueNode(node, sa);
                return;
            }
            if (numel == 0) {
                node.set_val(toArena("null"));
                return;
            }
            node |= ryml::MAP;
            buildMap(node, val);
            return;
        }

        if (type == ArrayType::CELL) {
            matlab::data::TypedArray<matlab::data::Array> cells = val;
            if (numel > 0 &&
                cells[0].getType() == ArrayType::STRUCT) {
                matlab::data::Array firstArr = cells[0];
                matlab::data::StructArray firstSa(firstArr);
                if (structHasField(firstSa, "Keys")) {
                    buildObjectSequence(node, val);
                    return;
                }
            }
            if (numel == 0) {
                node |= (ryml::SEQ | ryml::FLOW_SL);
                return;
            }
            buildCellSequence(node, val);
            return;
        }

        if (numel > 1) {
            buildTypedSequence(node, val);
            return;
        }

        if (numel == 0) {
            node |= (ryml::SEQ | ryml::FLOW_SL);
            return;
        }

        formatAndSetScalar(node, val);
    }

    // --- ValueNode handling ---

    void buildValueNode(ryml::NodeRef node,
                        const matlab::data::StructArray& vn) {
        if (structHasField(vn, "Type")) {
            matlab::data::TypedArray<matlab::data::MATLABString> typeArr =
                vn[0]["Type"];
            std::string nodeType = matlabStringToUtf8(typeArr[0]);

            if (nodeType == "missing") {
                node.set_val(toArena("null"));
                return;
            }

            if (nodeType == "datetime") {
                matlab::data::Array data = vn[0]["Data"];
                if (data.getType() == ArrayType::MATLAB_STRING) {
                    matlab::data::TypedArray<matlab::data::MATLABString>
                        strArr = data;
                    setNodeValue(node,
                        matlabStringToUtf8(strArr[0]), false);
                } else {
                    formatAndSetScalar(node, data);
                }
                return;
            }
        }

        matlab::data::Array data = vn[0]["Data"];
        buildValue(node, data);
    }

    // --- Sequence builders ---

    void buildObjectSequence(ryml::NodeRef node,
                             const matlab::data::Array& data) {
        matlab::data::TypedArray<matlab::data::Array> cells = data;
        size_t numel = cells.getNumberOfElements();
        node |= seqFlags();
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            item |= ryml::MAP;
            buildMap(item, cells[i]);
        }
    }

    void buildTypedSequence(ryml::NodeRef node,
                            const matlab::data::Array& data) {
        auto type = data.getType();
        size_t numel = data.getNumberOfElements();
        node |= seqFlags();

        if (type == ArrayType::LOGICAL) {
            matlab::data::TypedArray<bool> arr = data;
            for (size_t i = 0; i < numel; ++i) {
                ryml::NodeRef item = node.append_child();
                setNodeValue(item, arr[i] ? "true" : "false", false);
            }
        } else if (type == ArrayType::DOUBLE ||
                   type == ArrayType::SINGLE) {
            matlab::data::TypedArray<double> arr = data;
            for (size_t i = 0; i < numel; ++i) {
                ryml::NodeRef item = node.append_child();
                setNodeValue(item, formatDouble(arr[i]), false);
            }
        } else if (isIntegerType(type)) {
            auto vals = readIntArray(data);
            for (size_t i = 0; i < numel; ++i) {
                ryml::NodeRef item = node.append_child();
                setNodeValue(item, formatInt(vals[i]), false);
            }
        } else if (type == ArrayType::MATLAB_STRING) {
            matlab::data::TypedArray<matlab::data::MATLABString> arr = data;
            for (size_t i = 0; i < numel; ++i) {
                ryml::NodeRef item = node.append_child();
                std::string text = matlabStringToUtf8(arr[i]);
                setNodeValue(item, text, needsQuoting(text));
            }
        } else {
            throwMexError(*engine, factory,
                "writeyamlMex:UnsupportedType",
                "Unsupported array element type in node tree.");
        }
    }

    void buildCellSequence(ryml::NodeRef node,
                           const matlab::data::Array& data) {
        matlab::data::TypedArray<matlab::data::Array> cells = data;
        size_t numel = cells.getNumberOfElements();
        node |= seqFlags();
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            buildValue(item, cells[i]);
        }
    }

    // --- Post-processing ---

    static std::string insertSectionSpacing(const std::string& yaml) {
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
};
