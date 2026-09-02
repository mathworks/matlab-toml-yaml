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
