#define RYML_WITH_LEGACY_OPERATORS
#include "util.hpp"
#include "mexAdapter.hpp"
#include "ryml_util.hpp"

#include <vector>

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
                "CompactStruct data required.");
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
                      const std::string& text, bool quoted,
                      ryml::type_bits styleBits = 0) {
        ryml::csubstr arenaVal = toArena(text);
        if (styleBits) {
            node.set_val(arenaVal, styleBits);
        } else if (quoted) {
            node.set_val(arenaVal, ryml::VAL_DQUO);
        } else {
            node.set_val(arenaVal);
        }
    }

    // --- Index set helper ---

    static std::vector<bool> buildIndexSet(
            const matlab::data::Array& indices, size_t n) {
        std::vector<bool> flags(n + 1, false);
        if (indices.getNumberOfElements() > 0) {
            matlab::data::TypedArray<double> idx = indices;
            for (auto v : idx) {
                size_t i = static_cast<size_t>(v);
                if (i >= 1 && i <= n) flags[i] = true;
            }
        }
        return flags;
    }

    // --- Style helpers ---

    std::string getStyleString(const matlab::data::StructArray& style,
                               const std::string& field) {
        matlab::data::TypedArray<matlab::data::MATLABString> arr =
            style[0][field];
        return matlabStringToUtf8(factory, arr[0]);
    }

    static bool hasStyle(const matlab::data::Array& arr) {
        return arr.getType() == ArrayType::STRUCT &&
               arr.getNumberOfElements() > 0;
    }

    static ryml::type_bits scalarStyleBits(const std::string& style) {
        if (style == "single-quoted") return ryml::VAL_SQUO;
        if (style == "double-quoted") return ryml::VAL_DQUO;
        if (style == "literal")       return ryml::VAL_LITERAL;
        if (style == "folded")        return ryml::VAL_FOLDED;
        return 0;
    }

    ryml::type_bits effectiveSeqFlags(const std::string& containerStyle) {
        if (containerStyle == "flow")  return ryml::SEQ | ryml::FLOW_SL;
        if (containerStyle == "block") return ryml::SEQ;
        return seqFlags();
    }

    // --- Tree building from CompactStruct ---

    void buildMap(ryml::NodeRef mapNode,
                  const matlab::data::Array& csArr) {
        matlab::data::StructArray cs(csArr);

        matlab::data::TypedArray<matlab::data::MATLABString> keys =
            cs[0]["Keys"];
        matlab::data::TypedArray<matlab::data::Array> values =
            cs[0]["Values"];

        size_t n = keys.getNumberOfElements();
        auto isNull = buildIndexSet(cs[0]["NullIndices"], n);
        auto isQuoted = buildIndexSet(cs[0]["QuotedIndices"], n);

        matlab::data::Array nodeStyleArr = cs[0]["NodeStyle"];
        if (hasStyle(nodeStyleArr)) {
            matlab::data::StructArray ns(nodeStyleArr);
            if (getStyleString(ns, "ContainerStyle") == "flow") {
                mapNode |= ryml::FLOW_SL;
            }
        }

        matlab::data::TypedArray<matlab::data::Array> keyStylesArr =
            cs[0]["KeyStyles"];

        for (size_t i = 0; i < n; ++i) {
            std::string key = matlabStringToUtf8(keys[i]);

            ryml::NodeRef child = mapNode.append_child();
            child.set_key(toArena(key));

            if (isNull[i + 1]) {
                child.set_val(toArena("null"));
                continue;
            }

            std::string keyContainerStyle;
            ryml::type_bits keyScalarBits = 0;
            matlab::data::Array ksArr = keyStylesArr[i];
            if (hasStyle(ksArr)) {
                matlab::data::StructArray ks(ksArr);
                keyContainerStyle = getStyleString(ks, "ContainerStyle");
                keyScalarBits = scalarStyleBits(
                    getStyleString(ks, "ScalarStyle"));
            }

            matlab::data::Array val = values[i];
            auto type = val.getType();
            size_t numel = val.getNumberOfElements();

            if (type == ArrayType::STRUCT) {
                child |= ryml::MAP;
                buildMap(child, val);
            } else if (type == ArrayType::CELL) {
                matlab::data::TypedArray<matlab::data::Array> cells = val;
                ryml::type_bits flags =
                    effectiveSeqFlags(keyContainerStyle);
                if (numel > 0 &&
                    cells[0].getType() == ArrayType::STRUCT) {
                    buildObjectSequence(child, val, flags);
                } else {
                    buildCellSequence(child, val, flags);
                }
            } else if (type == ArrayType::MATLAB_STRING && numel == 1) {
                matlab::data::TypedArray<matlab::data::MATLABString>
                    strArr = val;
                setNodeValue(child,
                    matlabStringToUtf8(strArr[0]),
                    isQuoted[i + 1], keyScalarBits);
            } else if (numel > 1) {
                ryml::type_bits flags =
                    effectiveSeqFlags(keyContainerStyle);
                buildTypedSequence(child, val, flags);
            } else if (numel == 0) {
                child |= (ryml::SEQ | ryml::FLOW_SL);
            } else {
                formatAndSetScalar(child, val);
            }
        }
    }

    void buildObjectSequence(ryml::NodeRef node,
                             const matlab::data::Array& data,
                             ryml::type_bits flags) {
        matlab::data::TypedArray<matlab::data::Array> cells = data;
        size_t numel = cells.getNumberOfElements();
        node |= flags;
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            item |= ryml::MAP;
            buildMap(item, cells[i]);
        }
    }

    void buildTypedSequence(ryml::NodeRef node,
                            const matlab::data::Array& data,
                            ryml::type_bits flags) {
        auto results = engine->feval(
            u"matlab.io.config.internal.write.formatYAMLSequence",
            2, {data, factory.createScalar<double>(precision)});

        matlab::data::TypedArray<matlab::data::MATLABString> texts = results[0];
        matlab::data::TypedArray<bool> quoted = results[1];

        size_t numel = texts.getNumberOfElements();
        node |= flags;
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            setNodeValue(item,
                matlabStringToUtf8(texts[i]),
                static_cast<bool>(quoted[i]));
        }
    }

    void buildCellSequence(ryml::NodeRef node,
                           const matlab::data::Array& data,
                           ryml::type_bits flags) {
        matlab::data::TypedArray<matlab::data::Array> cells = data;
        size_t numel = cells.getNumberOfElements();
        node |= flags;
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            buildValue(item, cells[i]);
        }
    }

    // --- Fallback for individual values (cell elements only) ---

    void buildValue(ryml::NodeRef node,
                    const matlab::data::Array& val) {
        auto type = val.getType();
        size_t numel = val.getNumberOfElements();

        if (type == ArrayType::STRUCT) {
            if (numel == 0) {
                node.set_val(toArena("null"));
                return;
            }
            node |= ryml::MAP;
            buildMap(node, val);
            return;
        }

        if (numel == 0) {
            node |= (ryml::SEQ | ryml::FLOW_SL);
            return;
        }

        if (numel == 1) {
            formatAndSetScalar(node, val);
            return;
        }

        if (type == ArrayType::CELL) {
            matlab::data::TypedArray<matlab::data::Array> cells = val;
            if (cells[0].getType() == ArrayType::STRUCT) {
                buildObjectSequence(node, val, seqFlags());
            } else {
                buildCellSequence(node, val, seqFlags());
            }
            return;
        }

        buildTypedSequence(node, val, seqFlags());
    }

    void formatAndSetScalar(ryml::NodeRef node,
                            const matlab::data::Array& val) {
        auto results = engine->feval(
            u"matlab.io.config.internal.write.formatYAMLScalar",
            2, {val, factory.createScalar<double>(precision)});
        matlab::data::TypedArray<matlab::data::MATLABString> t = results[0];
        matlab::data::TypedArray<bool> q = results[1];
        setNodeValue(node,
            matlabStringToUtf8(t[0]),
            static_cast<bool>(q[0]));
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
