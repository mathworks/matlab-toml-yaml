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

    matlab::data::Array makeEmptyCompactStruct() {
        auto keys = factory.createArray<matlab::data::MATLABString>({1, 0});
        auto values = factory.createArray<matlab::data::Array>({1, 0});
        auto empty = factory.createArray<double>({1, 0});

        return makeCompactStruct(factory, keys, values, empty, empty, empty);
    }

    // --- YAML 1.1 boolean detection ---

    static bool tryParseBool(ryml::csubstr val, bool& result) {
        if (val == "true"  || val == "True"  || val == "TRUE" ||
            val == "yes"   || val == "Yes"   || val == "YES" ||
            val == "on"    || val == "On"    || val == "ON") {
            result = true;
            return true;
        }
        if (val == "false" || val == "False" || val == "FALSE" ||
            val == "no"    || val == "No"    || val == "NO" ||
            val == "off"   || val == "Off"   || val == "OFF") {
            result = false;
            return true;
        }
        return false;
    }

    // --- YAML special float values (.inf, .nan) ---

    static bool tryParseYAMLFloat(ryml::csubstr val, double& result) {
        if (val == ".inf" || val == ".Inf" || val == ".INF") {
            result = std::numeric_limits<double>::infinity();
            return true;
        }
        if (val == "-.inf" || val == "-.Inf" || val == "-.INF") {
            result = -std::numeric_limits<double>::infinity();
            return true;
        }
        if (val == "+.inf" || val == "+.Inf" || val == "+.INF") {
            result = std::numeric_limits<double>::infinity();
            return true;
        }
        if (val == ".nan" || val == ".NaN" || val == ".NAN") {
            result = std::numeric_limits<double>::quiet_NaN();
            return true;
        }
        return false;
    }

    // --- Typed scalar conversion ---

    matlab::data::Array convertTypedScalar(ryml::ConstNodeRef node) {
        if (node.is_val_quoted()) {
            return factory.createScalar(
                utf8ToMATLABString(toStdString(node.val())));
        }

        ryml::csubstr val = node.val();

        bool b;
        if (tryParseBool(val, b)) {
            return factory.createScalar<bool>(b);
        }

        double d;
        if (tryParseYAMLFloat(val, d)) {
            return factory.createScalar<double>(d);
        }

        if (val.is_integer() || val.is_real()) {
            if (ryml::from_chars(val, &d)) {
                return factory.createScalar<double>(d);
            }
        }

        return factory.createScalar(
            utf8ToMATLABString(toStdString(val)));
    }

    // --- Node conversion ---

    matlab::data::Array convertNode(ryml::ConstNodeRef node) {
        if (node.is_map()) {
            return convertMap(node);
        }
        if (node.is_seq()) {
            return convertSequence(node);
        }
        if (node.has_val()) {
            return convertTypedScalar(node);
        }
        return makeEmptyCompactStruct();
    }

    matlab::data::Array convertMap(ryml::ConstNodeRef node) {
        size_t n = node.num_children();

        auto keys = factory.createArray<matlab::data::MATLABString>({1, n});
        auto values = factory.createArray<matlab::data::Array>({1, n});
        std::vector<double> nullIdx;

        size_t i = 0;
        for (ryml::ConstNodeRef child : node.children()) {
            keys[0][i] = utf8ToMATLABString(toStdString(child.key()));

            if (child.is_map()) {
                values[0][i] = convertMap(child);
            } else if (child.is_seq()) {
                values[0][i] = convertSequence(child);
            } else if (child.has_val()) {
                if (child.val_is_null()) {
                    nullIdx.push_back(static_cast<double>(i + 1));
                    values[0][i] = factory.createArray<double>({0, 0});
                } else {
                    values[0][i] = convertTypedScalar(child);
                }
            } else {
                nullIdx.push_back(static_cast<double>(i + 1));
                values[0][i] = factory.createArray<double>({0, 0});
            }
            ++i;
        }

        auto nullArr = toDoubleArray(nullIdx);
        auto emptyArr = factory.createArray<double>({1, 0});

        return makeCompactStruct(factory, keys, values, nullArr, emptyArr, emptyArr);
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

        if (allScalar && !sequenceAsCell) {
            return consolidateTypedScalars(node, count);
        }

        std::vector<matlab::data::Array> elems;
        elems.reserve(count);
        for (ryml::ConstNodeRef child : node.children()) {
            elems.push_back(convertNode(child));
        }

        if (sequenceAsCell) {
            return makeCellArray(elems, count);
        }

        return makeCellArray(elems, count);
    }

    // --- Sequence consolidation with type detection ---

    matlab::data::Array consolidateTypedScalars(
            ryml::ConstNodeRef node, size_t count) {
        // Try all-numeric
        std::vector<double> nums;
        nums.reserve(count);
        bool allNumeric = true;
        for (ryml::ConstNodeRef child : node.children()) {
            if (child.is_val_quoted() || child.val_is_null()) {
                allNumeric = false;
                break;
            }
            ryml::csubstr val = child.val();
            double d;
            if (tryParseYAMLFloat(val, d)) {
                nums.push_back(d);
            } else if (val.is_integer() || val.is_real()) {
                if (ryml::from_chars(val, &d)) {
                    nums.push_back(d);
                } else {
                    allNumeric = false;
                    break;
                }
            } else {
                allNumeric = false;
                break;
            }
        }
        if (allNumeric) {
            auto out = factory.createArray<double>({count, 1});
            for (size_t i = 0; i < count; ++i) {
                out[i][0] = nums[i];
            }
            return out;
        }

        // Try all-boolean
        std::vector<bool> bools;
        bools.reserve(count);
        bool allBool = true;
        for (ryml::ConstNodeRef child : node.children()) {
            if (child.is_val_quoted()) {
                allBool = false;
                break;
            }
            bool b;
            if (tryParseBool(child.val(), b)) {
                bools.push_back(b);
            } else {
                allBool = false;
                break;
            }
        }
        if (allBool) {
            auto out = factory.createArray<bool>({count, 1});
            for (size_t i = 0; i < count; ++i) {
                out[i][0] = bools[i];
            }
            return out;
        }

        // Try all-string (all quoted, or none parsed as bool/numeric)
        bool allString = true;
        for (ryml::ConstNodeRef child : node.children()) {
            if (child.val_is_null()) {
                allString = false;
                break;
            }
        }
        if (allString) {
            auto out = factory.createArray<matlab::data::MATLABString>(
                {count, 1});
            size_t i = 0;
            for (ryml::ConstNodeRef child : node.children()) {
                out[i][0] = utf8ToMATLABString(toStdString(child.val()));
                ++i;
            }
            return out;
        }

        // Mixed: cell array of individually typed values
        std::vector<matlab::data::Array> elems;
        elems.reserve(count);
        for (ryml::ConstNodeRef child : node.children()) {
            if (child.val_is_null()) {
                elems.push_back(factory.createArray<double>({0, 0}));
            } else {
                elems.push_back(convertTypedScalar(child));
            }
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

    matlab::data::Array convertScalar(ryml::ConstNodeRef node) {
        if (node.val_is_null()) {
            return factory.createArray<double>({0, 0});
        }
        return factory.createScalar(utf8ToMATLABString(toStdString(node.val())));
    }
};
