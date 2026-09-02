#define RYML_WITH_LEGACY_OPERATORS
#define RYML_SINGLE_HDR_DEFINE_NOW
#include "util.hpp"
#include "mexAdapter.hpp"
#include "ryml.hpp"

#include <fstream>

using matlab::data::ArrayType;

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;

    ryml::Tree tree;
    bool flowArrays = false;
    bool sectionSpacing = true;
    int precision = 6;

public:
    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.size() < 2) {
            throwMexError(*engine, factory,
                "writeyamlMex:InvalidInput",
                "Data and filename required.");
            return;
        }

        matlab::data::Array data = inputs[0];
        matlab::data::TypedArray<matlab::data::MATLABString> filenameArr =
            inputs[1];
        std::string filename = matlabStringToUtf8(factory, filenameArr[0]);

        flowArrays = false;
        sectionSpacing = true;
        precision = 6;
        if (inputs.size() > 2) {
            parseOptions(inputs[2]);
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

        std::ofstream ofs(filename, std::ios::binary);
        if (!ofs) {
            throwMexError(*engine, factory,
                "writeyamlMex:FileError",
                "Cannot open file for writing: " + filename);
            return;
        }
        ofs << yaml;
    }

private:

    // --- Option parsing ---

    void parseOptions(const matlab::data::Array& optsArr) {
        matlab::data::StructArray opts(optsArr);

        matlab::data::TypedArray<matlab::data::MATLABString> as =
            opts[0]["ArrayStyle"];
        flowArrays = (matlabStringToUtf8(factory, as[0]) == "flow");

        matlab::data::TypedArray<matlab::data::MATLABString> ss =
            opts[0]["SectionSpacing"];
        sectionSpacing =
            (matlabStringToUtf8(factory, ss[0]) == "loose");

        matlab::data::TypedArray<double> prec = opts[0]["Precision"];
        precision = static_cast<int>(prec[0]);
    }

    // --- MATLAB helpers ---

    bool isConfigurationData(const matlab::data::Array& val) {
        matlab::data::TypedArray<bool> r = engine->feval(u"isa",
            {val, factory.createCharArray(
                "matlab.io.config.ConfigurationData")});
        return r[0];
    }

    bool isDatetime(const matlab::data::Array& val) {
        matlab::data::TypedArray<bool> r = engine->feval(u"isa",
            {val, factory.createCharArray("datetime")});
        return r[0];
    }

    void formatScalar(const matlab::data::Array& val,
                      std::string& text, bool& quoted) {
        auto results = engine->feval(
            u"matlab.io.config.internal.formatYAMLScalar",
            2, {val, factory.createScalar<double>(precision)});
        matlab::data::TypedArray<matlab::data::MATLABString> t = results[0];
        text = matlabStringToUtf8(factory, t[0]);
        matlab::data::TypedArray<bool> q = results[1];
        quoted = q[0];
    }

    // --- Arena helper ---

    ryml::csubstr toArena(const std::string& s) {
        return tree.copy_to_arena(
            ryml::csubstr(s.data(), s.size()));
    }

    // --- Tree building ---

    void buildMap(ryml::NodeRef mapNode,
                  const matlab::data::Array& obj) {
        matlab::data::TypedArray<matlab::data::MATLABString> keyArray =
            engine->feval(u"keys", {obj});

        for (const auto& ms : keyArray) {
            std::string key = matlabStringToUtf8(factory, ms);
            matlab::data::Array val = engine->feval(u"getfield",
                {obj, factory.createCharArrayFromUTF8(key)});

            ryml::NodeRef child = mapNode.append_child();
            child.set_key(toArena(key));
            buildValue(child, val);
        }
    }

    void buildValue(ryml::NodeRef node,
                    const matlab::data::Array& val) {
        auto type = val.getType();
        size_t numel = val.getNumberOfElements();

        if (type == ArrayType::VALUE_OBJECT ||
            type == ArrayType::HANDLE_OBJECT_REF) {
            if (isConfigurationData(val)) {
                if (numel == 0) {
                    node.set_val(toArena("null"));
                    return;
                }
                if (numel > 1) {
                    buildObjectSequence(node, val, numel);
                    return;
                }
                node |= ryml::MAP;
                buildMap(node, val);
                return;
            }
            setFormattedScalar(node, val);
            return;
        }

        if (numel == 0) {
            node.set_val(toArena("null"));
            return;
        }

        if (numel == 1) {
            setFormattedScalar(node, val);
            return;
        }

        if (type == ArrayType::CELL) {
            buildCellSequence(node, val, numel);
            return;
        }

        buildTypedSequence(node, val, numel);
    }

    void setFormattedScalar(ryml::NodeRef node,
                            const matlab::data::Array& val) {
        std::string text;
        bool quoted;
        formatScalar(val, text, quoted);

        ryml::csubstr arenaVal = toArena(text);
        if (quoted) {
            node.set_val(arenaVal, ryml::VAL_DQUO);
        } else {
            node.set_val(arenaVal);
        }
    }

    // --- Sequence builders ---

    ryml::type_bits seqFlags() {
        return flowArrays
            ? (ryml::SEQ | ryml::FLOW_SL)
            : ryml::SEQ;
    }

    void buildObjectSequence(ryml::NodeRef node,
                             const matlab::data::Array& data,
                             size_t numel) {
        matlab::data::TypedArray<matlab::data::Array> cells =
            engine->feval(u"num2cell", {data});
        node |= seqFlags();
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            item |= ryml::MAP;
            buildMap(item, cells[i]);
        }
    }

    void buildTypedSequence(ryml::NodeRef node,
                            const matlab::data::Array& data,
                            size_t numel) {
        matlab::data::TypedArray<matlab::data::Array> cells =
            engine->feval(u"num2cell", {data});
        node |= seqFlags();
        for (size_t i = 0; i < numel; ++i) {
            ryml::NodeRef item = node.append_child();
            setFormattedScalar(item, cells[i]);
        }
    }

    void buildCellSequence(ryml::NodeRef node,
                           const matlab::data::Array& data,
                           size_t numel) {
        matlab::data::TypedArray<matlab::data::Array> cells = data;
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
