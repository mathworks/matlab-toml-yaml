#pragma once

#include "util.hpp"
#include "ryml_util.hpp"

#include <string>
#include <vector>

class ReadYamlImpl {
    std::shared_ptr<matlab::engine::MATLABEngine> engine;
    matlab::data::ArrayFactory factory;
    bool sequenceAsCell = false;

public:
    explicit ReadYamlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

private:
    static std::string toStdString(ryml::csubstr s);
    matlab::data::Array makeEmptyTableNode();
    static bool tryParseBool(ryml::csubstr val, bool& result);
    static bool tryParseYAMLFloat(ryml::csubstr val, double& result);
    matlab::data::Array convertTypedScalar(ryml::ConstNodeRef node);
    matlab::data::Array convertNode(ryml::ConstNodeRef node);
    matlab::data::Array convertMap(ryml::ConstNodeRef node);
    matlab::data::Array convertSequence(ryml::ConstNodeRef node);
    matlab::data::Array consolidateTypedScalars(
        ryml::ConstNodeRef node, size_t count);
    matlab::data::Array makeCellArray(
        const std::vector<matlab::data::Array>& elems, size_t count);
    matlab::data::Array convertScalar(ryml::ConstNodeRef node);
};
