#pragma once

#include "mex.hpp"
#include <string>

std::string matlabStringToUtf8(
    matlab::data::ArrayFactory& factory,
    const matlab::data::MATLABString& ms);

matlab::data::Array makeString(
    matlab::data::ArrayFactory& factory,
    const std::string& utf8);

void throwMexError(
    matlab::engine::MATLABEngine& engine,
    matlab::data::ArrayFactory& factory,
    const std::string& id,
    const std::string& msg);

inline matlab::data::StructArray makeCompactStruct(
    matlab::data::ArrayFactory& factory,
    matlab::data::Array keys,
    matlab::data::Array values,
    matlab::data::Array nullIndices,
    matlab::data::Array datetimeIndices,
    matlab::data::Array quotedIndices,
    matlab::data::Array nodeStyle,
    matlab::data::Array keyStyles) {
    auto cs = factory.createStructArray({1, 1},
        {"Keys", "Values", "NullIndices", "DatetimeIndices", "QuotedIndices",
         "NodeStyle", "KeyStyles"});
    cs[0]["Keys"] = std::move(keys);
    cs[0]["Values"] = std::move(values);
    cs[0]["NullIndices"] = std::move(nullIndices);
    cs[0]["DatetimeIndices"] = std::move(datetimeIndices);
    cs[0]["QuotedIndices"] = std::move(quotedIndices);
    cs[0]["NodeStyle"] = std::move(nodeStyle);
    cs[0]["KeyStyles"] = std::move(keyStyles);
    return cs;
}
