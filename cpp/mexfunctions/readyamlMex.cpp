#define RYML_SINGLE_HDR_DEFINE_NOW
#include "util.hpp"
#include "mexAdapter.hpp"
#include "ryml.hpp"

#include <fstream>
#include <sstream>

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;
    bool sequenceAsCell = false;
    std::string datetimeType;

public:
    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.size() < 1) {
            throwMexError(*engine, factory,
                "readyamlMex:InvalidInput", "Filename required.");
            return;
        }

        matlab::data::TypedArray<matlab::data::MATLABString> filenameArr =
            inputs[0];
        std::string filename = matlabStringToUtf8(factory, filenameArr[0]);

        sequenceAsCell = false;
        datetimeType = "string";
        if (inputs.size() > 1) {
            matlab::data::StructArray opts(inputs[1]);

            matlab::data::TypedArray<matlab::data::MATLABString> seqRule =
                opts[0]["SequenceRule"];
            sequenceAsCell =
                (matlabStringToUtf8(factory, seqRule[0]) == "cell");

            matlab::data::TypedArray<matlab::data::MATLABString> dtType =
                opts[0]["DatetimeType"];
            datetimeType = matlabStringToUtf8(factory, dtType[0]);
        }

        std::ifstream ifs(filename, std::ios::binary);
        if (!ifs) {
            throwMexError(*engine, factory,
                "readyamlMex:FileError",
                "Cannot open file: " + filename);
            return;
        }
        std::ostringstream ss;
        ss << ifs.rdbuf();
        std::string content = ss.str();

        ryml::Tree tree;
        try {
            tree = ryml::parse_in_arena(
                ryml::csubstr(filename.data(), filename.size()),
                ryml::csubstr(content.data(), content.size()));
        } catch (const std::exception& e) {
            throwMexError(*engine, factory,
                "readyamlMex:ParseError", e.what());
            return;
        }

        ryml::ConstNodeRef root = tree.rootref();

        if (root.is_stream()) {
            if (root.num_children() > 0) {
                outputs[0] = convertNode(root.first_child());
            } else {
                outputs[0] = makeEmptyYAMLData();
            }
        } else {
            outputs[0] = convertNode(root);
        }
    }

private:
    static std::string toStdString(ryml::csubstr s) {
        return std::string(s.data(), s.size());
    }

    matlab::data::Array makeEmptyYAMLData() {
        return engine->feval(u"matlab.io.config.YAMLData",
                              std::vector<matlab::data::Array>{});
    }

    matlab::data::Array convertNode(ryml::ConstNodeRef node) {
        if (node.is_map()) {
            return convertMap(node);
        }
        if (node.is_seq()) {
            return convertSequence(node);
        }
        if (node.has_val()) {
            return convertScalar(node);
        }
        return factory.createArray<double>({0, 0});
    }

    matlab::data::Array convertMap(ryml::ConstNodeRef node) {
        auto obj = makeEmptyYAMLData();

        for (ryml::ConstNodeRef child : node.children()) {
            std::string key = toStdString(child.key());
            matlab::data::Array val = convertNode(child);
            obj = engine->feval(u"setfield",
                {obj, factory.createCharArrayFromUTF8(key), val});
        }
        return obj;
    }

    matlab::data::Array convertSequence(ryml::ConstNodeRef node) {
        size_t count = node.num_children();
        if (count == 0) {
            return factory.createArray<double>({0, 0});
        }

        std::vector<matlab::data::Array> elems;
        elems.reserve(count);
        for (ryml::ConstNodeRef child : node.children()) {
            elems.push_back(convertNode(child));
        }

        if (sequenceAsCell) {
            return makeCellArray(elems, count);
        }

        bool allMaps = true;
        bool allScalar = true;
        for (ryml::ConstNodeRef child : node.children()) {
            if (!child.is_map()) allMaps = false;
            if (child.is_map() || child.is_seq()) allScalar = false;
        }

        if (allMaps) {
            return engine->feval(u"vertcat", elems);
        }

        if (allScalar) {
            return consolidateScalars(elems, count);
        }

        return makeCellArray(elems, count);
    }

    matlab::data::Array makeCellArray(
            const std::vector<matlab::data::Array>& elems, size_t count) {
        auto out = factory.createArray<matlab::data::Array>({1, count});
        for (size_t i = 0; i < count; ++i) {
            out[0][i] = elems[i];
        }
        return out;
    }

    matlab::data::Array consolidateScalars(
            const std::vector<matlab::data::Array>& elems, size_t count) {
        bool allNumeric = true;
        bool allString = true;
        bool allLogical = true;

        for (const auto& e : elems) {
            auto t = e.getType();
            if (t != matlab::data::ArrayType::DOUBLE) allNumeric = false;
            if (t != matlab::data::ArrayType::MATLAB_STRING) allString = false;
            if (t != matlab::data::ArrayType::LOGICAL) allLogical = false;
        }

        if (allNumeric) {
            auto arr = factory.createArray<double>({count, 1});
            for (size_t i = 0; i < count; ++i) {
                matlab::data::TypedArray<double> v = elems[i];
                arr[i][0] = v[0];
            }
            return arr;
        }
        if (allLogical) {
            auto arr = factory.createArray<bool>({count, 1});
            for (size_t i = 0; i < count; ++i) {
                matlab::data::TypedArray<bool> v = elems[i];
                arr[i][0] = static_cast<bool>(v[0]);
            }
            return arr;
        }
        if (allString) {
            auto arr = factory.createArray<matlab::data::MATLABString>(
                {count, 1});
            for (size_t i = 0; i < count; ++i) {
                matlab::data::TypedArray<matlab::data::MATLABString> v =
                    elems[i];
                arr[i][0] = v[0];
            }
            return arr;
        }

        return makeCellArray(elems, count);
    }

    matlab::data::Array convertScalar(ryml::ConstNodeRef node) {
        if (node.val_is_null()) {
            return factory.createArray<double>({0, 0});
        }

        std::string s = toStdString(node.val());
        bool isQuoted = node.is_val_quoted();

        return engine->feval(
            u"matlab.io.config.internal.parseYAMLScalar",
            {makeString(factory, s),
             factory.createScalar<bool>(isQuoted),
             makeString(factory, datetimeType)});
    }
};
