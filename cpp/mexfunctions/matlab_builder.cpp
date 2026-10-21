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
    auto firstDims = af.elements[0].getDimensions();
    size_t firstNumel = af.elements[0].getNumberOfElements();

    bool uniform = (n > 1);
    for (size_t i = 1; uniform && i < n; ++i) {
        if (af.elements[i].getType() != firstType ||
            af.elements[i].getDimensions() != firstDims) {
            uniform = false;
        }
    }

    if (uniform && firstNumel == 1) {
        switch (firstType) {
        case ArrayType::DOUBLE:
            consolidateTypedArray<double>(af.elements, n); return;
        case ArrayType::LOGICAL:
            consolidateTypedArray<bool>(af.elements, n); return;
        case ArrayType::INT64:
            consolidateTypedArray<int64_t>(af.elements, n); return;
        case ArrayType::UINT64:
            consolidateTypedArray<uint64_t>(af.elements, n); return;
        case ArrayType::MATLAB_STRING:
            consolidateTypedArray<matlab::data::MATLABString>(af.elements, n); return;
        default:
            break;
        }
    }

    if (uniform && firstNumel > 1) {
        switch (firstType) {
        case ArrayType::DOUBLE:
            reconstructNDArray<double>(af.elements, n, firstDims); return;
        case ArrayType::LOGICAL:
            reconstructNDArray<bool>(af.elements, n, firstDims); return;
        case ArrayType::INT64:
            reconstructNDArray<int64_t>(af.elements, n, firstDims); return;
        case ArrayType::UINT64:
            reconstructNDArray<uint64_t>(af.elements, n, firstDims); return;
        case ArrayType::MATLAB_STRING:
            reconstructNDArray<matlab::data::MATLABString>(af.elements, n, firstDims); return;
        default:
            break;
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
    constexpr int64_t limit = 1LL << 53;
    if (i > limit || i < -limit) {
        pushValue(factory.createScalar<int64_t>(i));
    } else {
        pushValue(factory.createScalar<double>(static_cast<double>(i)));
    }
}

void MatlabBuilder::uintValue(uint64_t u) {
    if (u > (1ULL << 53)) {
        pushValue(factory.createScalar<uint64_t>(u));
    } else {
        pushValue(factory.createScalar<double>(static_cast<double>(u)));
    }
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
