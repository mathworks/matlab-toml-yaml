#pragma once

#include "util.hpp"
#include "ryml_util.hpp"
#include "document_handler.hpp"

#include <string>

class ReadYamlImpl {
    std::shared_ptr<matlab::engine::MATLABEngine> engine;
    matlab::data::ArrayFactory factory;

public:
    explicit ReadYamlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

private:
    static std::string toStdString(ryml::csubstr s);
    static bool tryParseBool(ryml::csubstr val, bool& result);
    static bool tryParseYAMLFloat(ryml::csubstr val, double& result);
    void emitNode(ryml::ConstNodeRef node, DocumentHandler& handler);
    void emitObject(ryml::ConstNodeRef node, DocumentHandler& handler);
    void emitSequence(ryml::ConstNodeRef node, DocumentHandler& handler);
    void emitScalar(ryml::ConstNodeRef node, DocumentHandler& handler);
};
