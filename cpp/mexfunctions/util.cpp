#include "util.hpp"
#include "cppmex/detail/mexExceptionImpl.hpp"

std::string matlabStringToUtf8(const matlab::data::MATLABString& ms) {
    if (!ms.has_value()) {
        return {};
    }
    const auto& str = *ms;
    if (str.empty()) {
        return {};
    }
    return matlab::engine::convertUTF16StringToUTF8String(str);
}

matlab::data::MATLABString utf8ToMATLABString(const std::string& utf8) {
    return matlab::data::MATLABString(matlab::engine::convertUTF8StringToUTF16String(utf8));
}

void throwMexError(
    matlab::engine::MATLABEngine& engine,
    matlab::data::ArrayFactory& factory,
    const std::string& id,
    const std::string& msg) {
    engine.feval(u"error", 0,
        {factory.createCharArray(id), factory.createCharArray("%s"),
         factory.createCharArray(msg)});
}

matlab::data::Array metaToStruct(
        matlab::data::ArrayFactory& factory, const NodeMeta& meta) {
    if (meta.empty()) {
        return factory.createArray<double>({0, 0});
    }
    std::vector<std::string> names;
    for (const auto& kv : meta.fields) names.push_back(kv.first);
    if (!meta.comments.empty()) names.push_back("Comments");

    auto sa = factory.createStructArray({1, 1}, names);
    for (const auto& kv : meta.fields) {
        sa[0][kv.first] = factory.createScalar(utf8ToMATLABString(kv.second));
    }
    if (!meta.comments.empty()) {
        auto c = factory.createArray<matlab::data::MATLABString>(
            {meta.comments.size(), 1});
        for (size_t i = 0; i < meta.comments.size(); ++i) {
            c[i][0] = utf8ToMATLABString(meta.comments[i]);
        }
        sa[0]["Comments"] = std::move(c);
    }
    return sa;
}

NodeMeta structToMeta(const matlab::data::Array& arr) {
    NodeMeta meta;
    if (arr.getType() != matlab::data::ArrayType::STRUCT ||
        arr.getNumberOfElements() != 1) {
        return meta;
    }
    matlab::data::StructArray sa(arr);
    for (const auto& f : sa.getFieldNames()) {
        std::string name(f);
        matlab::data::Array v = sa[0][name];
        if (v.getType() != matlab::data::ArrayType::MATLAB_STRING) continue;
        matlab::data::TypedArray<matlab::data::MATLABString> s = v;
        if (name == "Comments") {
            for (auto it = s.begin(); it != s.end(); ++it) {
                matlab::data::MATLABString ms = *it;
                meta.comments.push_back(matlabStringToUtf8(ms));
            }
        } else if (s.getNumberOfElements() == 1) {
            meta.fields[name] = matlabStringToUtf8(s[0]);
        }
    }
    return meta;
}

matlab::data::StructArray withField(
        matlab::data::ArrayFactory& factory,
        const matlab::data::StructArray& sa,
        const std::string& name,
        matlab::data::Array value) {
    std::vector<std::string> names;
    for (const auto& f : sa.getFieldNames()) names.emplace_back(f);
    bool exists = false;
    for (const auto& n : names) exists = exists || (n == name);
    if (!exists) names.push_back(name);

    auto out = factory.createStructArray({1, 1}, names);
    for (const auto& n : names) {
        if (n == name) {
            out[0][n] = std::move(value);
        } else {
            matlab::data::Array v = sa[0][n];
            out[0][n] = v;
        }
    }
    return out;
}
