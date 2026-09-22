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
        auto results = engine->feval(
            u"matlab.io.config.internal.write.formatYAMLSequence",
            2, {data, factory.createScalar<double>(precision)});

        matlab::data::TypedArray<matlab::data::MATLABString> texts = results[0];
        matlab::data::TypedArray<bool> quoted = results[1];

        size_t numel = texts.getNumberOfElements();
        node |= seqFlags();
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            setNodeValue(item,
                matlabStringToUtf8(texts[i]),
                static_cast<bool>(quoted[i]));
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
