#pragma once

#include "util.hpp"
#include "toml.hpp"
#include "document_handler.hpp"

#include <sstream>
#include <string>

class ReadTomlImpl {
    std::shared_ptr<matlab::engine::MATLABEngine> engine;
    matlab::data::ArrayFactory factory;

public:
    explicit ReadTomlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

private:
    static bool isDatetimeType(toml::value_t t);
    static std::string datetimeToString(const toml::ordered_value& val);
    void emitTable(const toml::ordered_value& table,
                   DocumentHandler& handler);
    void emitValue(const toml::ordered_value& val,
                   DocumentHandler& handler);
    void emitArray(const toml::ordered_array& arr,
                   DocumentHandler& handler);
    void emitScalar(const toml::ordered_value& val,
                    DocumentHandler& handler);
};
