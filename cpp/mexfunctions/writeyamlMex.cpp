#define RYML_WITH_LEGACY_OPERATORS
#define RYML_SINGLE_HDR_DEFINE_NOW
#include "util.hpp"
#include "mexAdapter.hpp"
#include "ryml.hpp"

#include <fstream>

using matlab::data::ArrayType;

static void rymlErrorHandler(const char* msg, size_t len, ryml::Location,
                             void*) {
    throw std::runtime_error(std::string(msg, len));
}

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;

    ryml::Tree tree;
    bool flowArrays = false;
    bool sectionSpacing = true;
    int precision = 6;

public:
    MexFunction() {
        ryml::Callbacks cb = ryml::get_callbacks();
        cb.m_error = &rymlErrorHandler;
        ryml::set_callbacks(cb);
    }

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

    // --- Batch tree building ---

    void buildMap(ryml::NodeRef mapNode,
                  const matlab::data::Array& obj) {
        auto results = engine->feval(
            u"matlab.io.config.internal.write.formatYAMLMap",
            5, {obj, factory.createScalar<double>(precision)});

        matlab::data::TypedArray<matlab::data::MATLABString> keys = results[0];
        matlab::data::TypedArray<matlab::data::MATLABString> texts = results[1];
        matlab::data::TypedArray<bool> quoted = results[2];
        matlab::data::TypedArray<matlab::data::MATLABString> kinds = results[3];
        matlab::data::TypedArray<matlab::data::Array> values = results[4];

        size_t n = keys.getNumberOfElements();
        for (size_t i = 0; i < n; ++i) {
            std::string key = matlabStringToUtf8(factory, keys[i]);
            std::string kind = matlabStringToUtf8(factory, kinds[i]);

            ryml::NodeRef child = mapNode.append_child();
            child.set_key(toArena(key));

            if (kind == "scalar" || kind == "null") {
                setNodeValue(child,
                    matlabStringToUtf8(factory, texts[i]),
                    static_cast<bool>(quoted[i]));
            } else if (kind == "map") {
                child |= ryml::MAP;
                buildMap(child, values[i]);
            } else if (kind == "object_seq") {
                buildObjectSequence(child, values[i]);
            } else if (kind == "typed_seq") {
                buildTypedSequence(child, values[i]);
            } else if (kind == "cell_seq") {
                buildCellSequence(child, values[i]);
            }
        }
    }

    void buildObjectSequence(ryml::NodeRef node,
                             const matlab::data::Array& data) {
        matlab::data::TypedArray<matlab::data::Array> cells =
            engine->feval(u"num2cell", {data});
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
                matlabStringToUtf8(factory, texts[i]),
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

    // --- Fallback for individual values (cell elements only) ---

    void buildValue(ryml::NodeRef node,
                    const matlab::data::Array& val) {
        auto type = val.getType();
        size_t numel = val.getNumberOfElements();

        if (type == ArrayType::VALUE_OBJECT ||
            type == ArrayType::HANDLE_OBJECT_REF) {
            matlab::data::TypedArray<bool> r = engine->feval(u"isa",
                {val, factory.createCharArray(
                    "matlab.io.config.ConfigurationData")});
            if (r[0]) {
                if (numel == 0) {
                    node.set_val(toArena("null"));
                    return;
                }
                if (numel > 1) {
                    buildObjectSequence(node, val);
                    return;
                }
                node |= ryml::MAP;
                buildMap(node, val);
                return;
            }
            formatAndSetScalar(node, val);
            return;
        }

        if (numel == 0) {
            node.set_val(toArena("null"));
            return;
        }

        if (numel == 1) {
            formatAndSetScalar(node, val);
            return;
        }

        if (type == ArrayType::CELL) {
            buildCellSequence(node, val);
            return;
        }

        buildTypedSequence(node, val);
    }

    void formatAndSetScalar(ryml::NodeRef node,
                            const matlab::data::Array& val) {
        auto results = engine->feval(
            u"matlab.io.config.internal.write.formatYAMLScalar",
            2, {val, factory.createScalar<double>(precision)});
        matlab::data::TypedArray<matlab::data::MATLABString> t = results[0];
        matlab::data::TypedArray<bool> q = results[1];
        setNodeValue(node,
            matlabStringToUtf8(factory, t[0]),
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
