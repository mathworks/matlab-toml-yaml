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
        std::string filename = matlabStringToUtf8(factory, filenameArr[0]);

        sequenceAsCell = false;
        if (inputs.size() > 2) {
            matlab::data::StructArray opts(inputs[2]);

            matlab::data::TypedArray<matlab::data::MATLABString> seqRule =
                opts[0]["SequenceRule"];
            sequenceAsCell =
                (matlabStringToUtf8(factory, seqRule[0]) == "cell");
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

    matlab::data::Array makeEmptyCompactStruct() {
        auto keys = factory.createArray<matlab::data::MATLABString>({1, 0});
        auto values = factory.createArray<matlab::data::Array>({1, 0});
        auto empty = factory.createArray<double>({1, 0});

        return makeCompactStruct(factory, keys, values, empty, empty, empty);
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
        std::vector<double> nullIdx, quotedIdx;

        size_t i = 0;
        for (ryml::ConstNodeRef child : node.children()) {
            keys[0][i] = matlab::data::MATLABString(
                factory.createCharArrayFromUTF8(
                    toStdString(child.key())).toUTF16());

            if (child.is_map()) {
                values[0][i] = convertMap(child);
            } else if (child.is_seq()) {
                values[0][i] = convertSequence(child);
            } else if (child.has_val()) {
                if (child.val_is_null()) {
                    nullIdx.push_back(static_cast<double>(i + 1));
                    values[0][i] = factory.createArray<double>({0, 0});
                } else {
                    std::string s = toStdString(child.val());
                    values[0][i] = makeString(factory, s);
                    if (child.is_val_quoted()) {
                        quotedIdx.push_back(static_cast<double>(i + 1));
                    }
                }
            } else {
                nullIdx.push_back(static_cast<double>(i + 1));
                values[0][i] = factory.createArray<double>({0, 0});
            }
            ++i;
        }

        auto nullArr = toDoubleArray(nullIdx);
        auto quotedArr = toDoubleArray(quotedIdx);
        auto emptyArr = factory.createArray<double>({1, 0});

        return makeCompactStruct(factory, keys, values, nullArr, emptyArr, quotedArr);
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
            return factory.createArray<double>({0, 0});
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
            return factory.createArray<double>({0, 0});
        }
        return makeString(factory, toStdString(node.val()));
    }
};
