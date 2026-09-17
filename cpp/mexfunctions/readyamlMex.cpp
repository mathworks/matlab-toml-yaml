#include "util.hpp"
#include "mexAdapter.hpp"
#include "ryml_util.hpp"

#include <vector>

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;
    bool sequenceAsCell = false;

public:
    MexFunction() { installRymlErrorHandlers(); }

    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.size() < 2) {
            throwMexError(*engine, factory,
                "readyamlMex:InvalidInput",
                "File content and filename required.");
            return;
        }

        matlab::data::TypedArray<uint8_t> contentArr = inputs[0];
        std::string content(contentArr.begin(), contentArr.end());

        matlab::data::TypedArray<matlab::data::MATLABString> filenameArr =
            inputs[1];
        std::string filename = matlabStringToUtf8(filenameArr[0]);

        sequenceAsCell = false;
        if (inputs.size() > 2) {
            matlab::data::StructArray opts(inputs[2]);

            matlab::data::TypedArray<matlab::data::MATLABString> seqRule =
                opts[0]["SequenceRule"];
            sequenceAsCell =
                (matlabStringToUtf8(seqRule[0]) == "cell");
        }

        ryml::Tree tree = ryml::parse_in_arena(
            ryml::csubstr(filename.data(), filename.size()),
            ryml::csubstr(content.data(), content.size()));

        ryml::ConstNodeRef root = tree.rootref();

        if (root.is_stream()) {
            if (root.num_children() > 0) {
                outputs[0] = convertNode(root.first_child());
            } else {
                outputs[0] = makeEmptyCompactStruct();
            }
        } else {
            outputs[0] = convertNode(root);
        }
    }

private:
    static std::string toStdString(ryml::csubstr s) {
        return std::string(s.data(), s.size());
    }

    matlab::data::Array emptyArray() {
        return factory.createArray<double>({0, 0});
    }

    // --- Style struct helpers ---

    static bool isFlowContainer(ryml::ConstNodeRef node) {
        return (node.type().m_bits & ryml::CONTAINER_STYLE_FLOW) != 0;
    }

    static std::string valScalarStyle(ryml::ConstNodeRef node) {
        auto bits = node.type().m_bits;
        if (bits & ryml::VAL_SQUO)    return "single-quoted";
        if (bits & ryml::VAL_DQUO)    return "double-quoted";
        if (bits & ryml::VAL_LITERAL)  return "literal";
        if (bits & ryml::VAL_FOLDED)   return "folded";
        return "";
    }

    matlab::data::Array makeYAMLStyleStruct(
            const std::string& containerStyle,
            const std::string& scalarStyle,
            bool isArray) {
        auto s = factory.createStructArray({1, 1},
            {"ContainerStyle", "ScalarStyle", "IsArray"});
        s[0]["ContainerStyle"] = factory.createScalar(utf8ToMATLABString(containerStyle));
        s[0]["ScalarStyle"] = factory.createScalar(utf8ToMATLABString(scalarStyle));
        s[0]["IsArray"] = factory.createScalar<bool>(isArray);
        return s;
    }

    // --- Compact struct ---

    matlab::data::Array makeEmptyCompactStruct() {
        auto keys = factory.createArray<matlab::data::MATLABString>({1, 0});
        auto values = factory.createArray<matlab::data::Array>({1, 0});
        auto empty = factory.createArray<double>({1, 0});
        auto emptyKS = factory.createArray<matlab::data::Array>({1, 0});

        return makeCompactStruct(factory, keys, values, empty, empty, empty,
                                 emptyArray(), emptyKS);
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
        return makeEmptyCompactStruct();
    }

    matlab::data::Array convertMap(ryml::ConstNodeRef node) {
        size_t n = node.num_children();

        auto keys = factory.createArray<matlab::data::MATLABString>({1, n});
        auto values = factory.createArray<matlab::data::Array>({1, n});
        auto keyStyles = factory.createArray<matlab::data::Array>({1, n});
        std::vector<double> nullIdx, quotedIdx;

        size_t i = 0;
        for (ryml::ConstNodeRef child : node.children()) {
            keys[0][i] = utf8ToMATLABString(toStdString(child.key()));

            if (child.is_map()) {
                values[0][i] = convertMap(child);
            } else if (child.is_seq()) {
                values[0][i] = convertSequence(child);
                if (isFlowContainer(child)) {
                    keyStyles[0][i] = makeYAMLStyleStruct(
                        "flow", "auto", true);
                }
            } else if (child.has_val()) {
                if (child.val_is_null()) {
                    nullIdx.push_back(static_cast<double>(i + 1));
                    values[0][i] = emptyArray();
                } else {
                    std::string s = toStdString(child.val());
                    values[0][i] = factory.createScalar(utf8ToMATLABString(s));
                    if (child.is_val_quoted()) {
                        quotedIdx.push_back(static_cast<double>(i + 1));
                    }
                    std::string style = valScalarStyle(child);
                    if (!style.empty()) {
                        keyStyles[0][i] = makeYAMLStyleStruct(
                            "block", style, false);
                    }
                }
            } else {
                nullIdx.push_back(static_cast<double>(i + 1));
                values[0][i] = emptyArray();
            }
            ++i;
        }

        auto nullArr = toDoubleArray(nullIdx);
        auto quotedArr = toDoubleArray(quotedIdx);
        auto emptyArr = factory.createArray<double>({1, 0});

        matlab::data::Array nodeStyle = emptyArray();
        if (isFlowContainer(node)) {
            nodeStyle = makeYAMLStyleStruct("flow", "auto", false);
        }

        return makeCompactStruct(factory, keys, values, nullArr, emptyArr,
                                 quotedArr, nodeStyle, keyStyles);
    }

    matlab::data::Array toDoubleArray(const std::vector<double>& vec) {
        if (vec.empty()) {
            return factory.createArray<double>({1, 0});
        }
        auto arr = factory.createArray<double>({1, vec.size()});
        for (size_t i = 0; i < vec.size(); ++i) {
            arr[0][i] = vec[i];
        }
        return arr;
    }

    matlab::data::Array convertSequence(ryml::ConstNodeRef node) {
        size_t count = node.num_children();
        if (count == 0) {
            return emptyArray();
        }

        bool allMaps = true;
        bool allScalar = true;
        for (ryml::ConstNodeRef child : node.children()) {
            if (!child.is_map()) allMaps = false;
            if (child.is_map() || child.is_seq()) allScalar = false;
        }

        if (allMaps && !sequenceAsCell) {
            auto out = factory.createArray<matlab::data::Array>({1, count});
            size_t i = 0;
            for (ryml::ConstNodeRef child : node.children()) {
                out[0][i] = convertMap(child);
                ++i;
            }
            return out;
        }

        std::vector<matlab::data::Array> elems;
        elems.reserve(count);
        for (ryml::ConstNodeRef child : node.children()) {
            elems.push_back(convertNode(child));
        }

        if (sequenceAsCell) {
            return makeCellArray(elems, count);
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
        bool allString = true;
        for (const auto& e : elems) {
            if (e.getType() != matlab::data::ArrayType::MATLAB_STRING)
                allString = false;
        }

        if (allString) {
            auto arr = factory.createArray<matlab::data::MATLABString>(
                {count, 1});
            for (size_t i = 0; i < count; ++i) {
                matlab::data::TypedArray<matlab::data::MATLABString> v =
                    elems[i];
                matlab::data::MATLABString val = v[0];
                arr[i][0] = val;
            }
            return arr;
        }

        return makeCellArray(elems, count);
    }

    matlab::data::Array convertScalar(ryml::ConstNodeRef node) {
        if (node.val_is_null()) {
            return emptyArray();
        }
        return factory.createScalar(utf8ToMATLABString(toStdString(node.val())));
    }
};
