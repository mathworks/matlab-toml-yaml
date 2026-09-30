#include "matlab_builder.hpp"

void MatlabBuilder::pushValue(matlab::data::Array val) {
    if (stack.empty()) {
        root = std::move(val);
        return;
    }
    auto& frame = stack.back();
    if (auto* mf = std::get_if<MapFrame>(&frame)) {
        mf->values.push_back(std::move(val));
    } else if (auto* af = std::get_if<ArrayFrame>(&frame)) {
        af->elements.push_back(std::move(val));
    }
}

void MatlabBuilder::startObject(size_t count) {
    MapFrame mf;
    mf.keys.reserve(count);
    mf.values.reserve(count);
    stack.emplace_back(std::move(mf));
}

void MatlabBuilder::key(std::string_view k) {
    auto& mf = std::get<MapFrame>(stack.back());
    mf.keys.emplace_back(k);
}

void MatlabBuilder::endObject() {
    auto mf = std::get<MapFrame>(std::move(stack.back()));
    stack.pop_back();

    size_t n = mf.keys.size();
    auto keys = factory.createArray<matlab::data::MATLABString>({1, n});
    auto values = factory.createArray<matlab::data::Array>({1, n});

    for (size_t i = 0; i < n; ++i) {
        keys[0][i] = utf8ToMATLABString(mf.keys[i]);
        values[0][i] = std::move(mf.values[i]);
    }

    pushValue(makeTableNode(factory, std::move(keys), std::move(values)));
}

void MatlabBuilder::startArray(size_t count) {
    ArrayFrame af;
    af.elements.reserve(count);
    stack.emplace_back(std::move(af));
}

void MatlabBuilder::endArray() {
    using matlab::data::ArrayType;

    auto af = std::get<ArrayFrame>(std::move(stack.back()));
    stack.pop_back();

    if (af.elements.empty()) {
        pushValue(factory.createArray<double>({0, 0}));
        return;
    }

    size_t n = af.elements.size();

    auto firstType = af.elements[0].getType();
    bool homogeneous = true;
    for (size_t i = 0; i < n; ++i) {
        if (af.elements[i].getType() != firstType ||
            af.elements[i].getNumberOfElements() != 1) {
            homogeneous = false;
            break;
        }
    }

    if (homogeneous && n > 1) {
        if (firstType == ArrayType::DOUBLE) {
            auto arr = factory.createArray<double>({n, 1});
            for (size_t i = 0; i < n; ++i) {
                matlab::data::TypedArray<double> el = af.elements[i];
                arr[i][0] = el[0];
            }
            pushValue(std::move(arr));
            return;
        }
        if (firstType == ArrayType::LOGICAL) {
            auto arr = factory.createArray<bool>({n, 1});
            for (size_t i = 0; i < n; ++i) {
                matlab::data::TypedArray<bool> el = af.elements[i];
                arr[i][0] = static_cast<bool>(el[0]);
            }
            pushValue(std::move(arr));
            return;
        }
        if (firstType == ArrayType::MATLAB_STRING) {
            auto arr = factory.createArray<matlab::data::MATLABString>({n, 1});
            for (size_t i = 0; i < n; ++i) {
                matlab::data::TypedArray<matlab::data::MATLABString> el =
                    af.elements[i];
                matlab::data::MATLABString s = el[0];
                arr[i][0] = s;
            }
            pushValue(std::move(arr));
            return;
        }
    }

    auto out = factory.createArray<matlab::data::Array>({1, n});
    for (size_t i = 0; i < n; ++i) {
        out[0][i] = std::move(af.elements[i]);
    }
    pushValue(std::move(out));
}

void MatlabBuilder::nullValue() {
    pushValue(makeValueNode(factory,
        factory.createArray<double>({0, 0}), "missing"));
}

void MatlabBuilder::boolValue(bool b) {
    pushValue(factory.createScalar<bool>(b));
}

void MatlabBuilder::intValue(int64_t i) {
    pushValue(factory.createScalar<double>(static_cast<double>(i)));
}

void MatlabBuilder::uintValue(uint64_t u) {
    pushValue(factory.createScalar<double>(static_cast<double>(u)));
}

void MatlabBuilder::doubleValue(double d) {
    pushValue(factory.createScalar<double>(d));
}

void MatlabBuilder::stringValue(std::string_view s) {
    pushValue(factory.createScalar(
        utf8ToMATLABString(std::string(s))));
}

void MatlabBuilder::datetimeValue(std::string_view iso) {
    pushValue(makeValueNode(factory,
        factory.createScalar(utf8ToMATLABString(std::string(iso))),
        "datetime"));
}

matlab::data::Array MatlabBuilder::result() {
    return std::move(root);
}
