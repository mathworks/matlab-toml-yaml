#include "matlab_builder.hpp"

void MatlabBuilder::pushValue(matlab::data::Array val) {
    if (!arrayMeta.empty()) {
        auto node = factory.createStructArray({1, 1}, {"Elements", "Metadata"});
        node[0]["Elements"] = std::move(val);
        node[0]["Metadata"] = metaToStruct(factory, arrayMeta);
        val = std::move(node);
        arrayMeta = NodeMeta();
    } else if (!pendingMeta.empty()) {
        auto metaStruct = metaToStruct(factory, pendingMeta);
        if (val.getType() == matlab::data::ArrayType::STRUCT &&
            structHasField(matlab::data::StructArray(val), "Data")) {
            val = withField(factory, matlab::data::StructArray(val),
                "Metadata", std::move(metaStruct));
        } else {
            auto node = factory.createStructArray({1, 1}, {"Data", "Metadata"});
            node[0]["Data"] = std::move(val);
            node[0]["Metadata"] = std::move(metaStruct);
            val = std::move(node);
        }
        pendingMeta = NodeMeta();
    }
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
    mf.meta = std::move(pendingMeta);
    pendingMeta = NodeMeta();
    stack.emplace_back(std::move(mf));
}

void MatlabBuilder::key(std::string_view k) {
    auto& mf = std::get<MapFrame>(stack.back());
    mf.keys.emplace_back(k);
    mf.keyMeta.emplace_back();
}

void MatlabBuilder::metadata(const NodeMeta& m) {
    pendingMeta = m;
}

void MatlabBuilder::keyMetadata(const NodeMeta& m) {
    auto& mf = std::get<MapFrame>(stack.back());
    if (!mf.keyMeta.empty()) mf.keyMeta.back() = m;
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

    auto node = makeTableNode(factory, std::move(keys), std::move(values));

    bool anyKeyMeta = false;
    for (const auto& km : mf.keyMeta) anyKeyMeta = anyKeyMeta || !km.empty();
    if (anyKeyMeta) {
        auto keyMeta = factory.createArray<matlab::data::Array>({1, n});
        for (size_t i = 0; i < n; ++i) {
            keyMeta[0][i] = metaToStruct(factory, mf.keyMeta[i]);
        }
        node = withField(factory, node, "KeyMetadata", std::move(keyMeta));
    }
    if (!mf.meta.empty()) {
        node = withField(factory, node, "TableMetadata",
            metaToStruct(factory, mf.meta));
    }
    pushValue(std::move(node));
}

// Nested arrays that differ only by a shared style (e.g. rows of a
// matrix written as flow sequences) are unwrapped so they can still be
// consolidated into one typed array. The shared row style is dropped.
void MatlabBuilder::unwrapUniformArrayNodes(
        std::vector<matlab::data::Array>& elements) {
    if (elements.size() < 2) return;
    NodeMeta first;
    for (size_t i = 0; i < elements.size(); ++i) {
        if (elements[i].getType() != matlab::data::ArrayType::STRUCT) return;
        matlab::data::StructArray sa(elements[i]);
        if (!structHasField(sa, "Elements")) return;
        NodeMeta m = structToMeta(sa[0]["Metadata"]);
        if (i == 0) {
            first = m;
        } else if (m.fields != first.fields || m.comments != first.comments) {
            return;
        }
    }
    for (auto& el : elements) {
        matlab::data::StructArray sa(el);
        matlab::data::Array inner = sa[0]["Elements"];
        el = inner;
    }
}

void MatlabBuilder::startArray(size_t count) {
    ArrayFrame af;
    af.elements.reserve(count);
    af.meta = std::move(pendingMeta);
    pendingMeta = NodeMeta();
    stack.emplace_back(std::move(af));
}

void MatlabBuilder::endArray() {
    using matlab::data::ArrayType;

    auto af = std::get<ArrayFrame>(std::move(stack.back()));
    stack.pop_back();
    arrayMeta = std::move(af.meta);

    if (af.elements.empty()) {
        pushValue(factory.createArray<double>({0, 0}));
        return;
    }

    size_t n = af.elements.size();
    unwrapUniformArrayNodes(af.elements);
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

    auto out = factory.createArray<matlab::data::Array>({n, 1});
    for (size_t i = 0; i < n; ++i) {
        out[i][0] = std::move(af.elements[i]);
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
