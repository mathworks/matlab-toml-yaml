#pragma once

#include "mex.hpp"
#include <string>

// MATLABString is a typedef to optional<u16string>.
std::string matlabStringToUtf8(const matlab::data::MATLABString& ms);

matlab::data::MATLABString utf8ToMATLABString(const std::string& utf8);

void throwMexError(
    matlab::engine::MATLABEngine& engine,
    matlab::data::ArrayFactory& factory,
    const std::string& id,
    const std::string& msg);

inline matlab::data::StructArray makeTableNode(
    matlab::data::ArrayFactory& factory,
    matlab::data::Array keys,
    matlab::data::Array values) {
    auto node = factory.createStructArray({1, 1}, {"Keys", "Values"});
    node[0]["Keys"] = std::move(keys);
    node[0]["Values"] = std::move(values);
    return node;
}

inline matlab::data::StructArray makeValueNode(
    matlab::data::ArrayFactory& factory,
    matlab::data::Array data,
    const std::string& type) {
    auto node = factory.createStructArray({1, 1}, {"Data", "Type"});
    node[0]["Data"] = std::move(data);
    node[0]["Type"] = factory.createScalar(utf8ToMATLABString(type));
    return node;
}

inline bool structHasField(
    const matlab::data::StructArray& sa,
    const std::string& name) {
    matlab::data::MATLABFieldIdentifier target(name);
    for (const auto& f : sa.getFieldNames()) {
        if (f == target) return true;
    }
    return false;
}
