#pragma once

#include "util.hpp"
#include "toml.hpp"

#include <sstream>
#include <string>
#include <vector>

class ReadTomlImpl {
    std::shared_ptr<matlab::engine::MATLABEngine> engine;
    matlab::data::ArrayFactory factory;

public:
    explicit ReadTomlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

private:
    bool isDatetimeType(toml::value_t t);
    std::string datetimeToString(const toml::value& val);
    matlab::data::Array tableToNode(const toml::ordered_value& table);
    matlab::data::Array convertScalar(const toml::value& val);
    matlab::data::Array convertArray(const toml::ordered_array& arr);
};
