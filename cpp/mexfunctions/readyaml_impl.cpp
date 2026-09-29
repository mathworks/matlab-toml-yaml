#include "readyaml_impl.hpp"
#include "matlab_builder.hpp"

ReadYamlImpl::ReadYamlImpl(
        std::shared_ptr<matlab::engine::MATLABEngine> eng)
    : engine(std::move(eng)) {}

void ReadYamlImpl::execute(matlab::mex::ArgumentList outputs,
                           matlab::mex::ArgumentList inputs) {
    if (inputs.size() < 3) {
        throwMexError(*engine, factory,
            "readyamlMex:InvalidInput",
            "File content and filename required.");
        return;
    }

    matlab::data::TypedArray<uint8_t> contentArr = inputs[1];
    std::string content(contentArr.begin(), contentArr.end());

    matlab::data::TypedArray<matlab::data::MATLABString> filenameArr =
        inputs[2];
    std::string filename = matlabStringToUtf8(filenameArr[0]);

    ryml::Tree tree = ryml::parse_in_arena(
        ryml::csubstr(filename.data(), filename.size()),
        ryml::csubstr(content.data(), content.size()));

    ryml::ConstNodeRef root = tree.rootref();

    MatlabBuilder builder;

    if (root.is_stream()) {
        if (root.num_children() > 0) {
            emitNode(root.first_child(), builder);
        } else {
            builder.startObject(0);
            builder.endObject();
        }
    } else {
        emitNode(root, builder);
    }

    outputs[0] = builder.result();
}

std::string ReadYamlImpl::toStdString(ryml::csubstr s) {
    return std::string(s.data(), s.size());
}

bool ReadYamlImpl::tryParseBool(ryml::csubstr val, bool& result) {
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

bool ReadYamlImpl::tryParseYAMLFloat(ryml::csubstr val, double& result) {
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

void ReadYamlImpl::emitNode(ryml::ConstNodeRef node,
                            DocumentHandler& handler) {
    if (node.is_map()) {
        emitObject(node, handler);
    } else if (node.is_seq()) {
        emitSequence(node, handler);
    } else if (node.has_val()) {
        emitScalar(node, handler);
    } else {
        handler.startObject(0);
        handler.endObject();
    }
}

void ReadYamlImpl::emitObject(ryml::ConstNodeRef node,
                              DocumentHandler& handler) {
    size_t n = node.num_children();
    handler.startObject(n);

    for (ryml::ConstNodeRef child : node.children()) {
        std::string keyStr = toStdString(child.key());
        handler.key(keyStr);

        if (child.is_map()) {
            emitObject(child, handler);
        } else if (child.is_seq()) {
            emitSequence(child, handler);
        } else if (child.has_val()) {
            if (child.val_is_null()) {
                handler.nullValue();
            } else {
                emitScalar(child, handler);
            }
        } else {
            handler.nullValue();
        }
    }

    handler.endObject();
}

void ReadYamlImpl::emitSequence(ryml::ConstNodeRef node,
                                DocumentHandler& handler) {
    size_t count = node.num_children();
    handler.startArray(count);
    for (ryml::ConstNodeRef child : node.children()) {
        emitNode(child, handler);
    }
    handler.endArray();
}

void ReadYamlImpl::emitScalar(ryml::ConstNodeRef node,
                              DocumentHandler& handler) {
    if (node.is_val_quoted()) {
        std::string text = toStdString(node.val());
        handler.stringValue(text);
        return;
    }

    ryml::csubstr val = node.val();

    bool b;
    if (tryParseBool(val, b)) {
        handler.boolValue(b);
        return;
    }

    double d;
    if (tryParseYAMLFloat(val, d)) {
        handler.doubleValue(d);
        return;
    }

    if (val.is_integer() || val.is_real()) {
        if (ryml::from_chars(val, &d)) {
            handler.doubleValue(d);
            return;
        }
    }

    std::string text = toStdString(val);
    handler.stringValue(text);
}
