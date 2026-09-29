#pragma once

#include "util.hpp"
#include "ryml_util.hpp"

#include <cmath>
#include <cstdio>
#include <cstdint>
#include <charconv>
#include <cstring>
#include <cctype>
#include <string>
#include <vector>

class WriteYamlImpl {
    std::shared_ptr<matlab::engine::MATLABEngine> engine;
    matlab::data::ArrayFactory factory;

    ryml::Tree tree;
    bool flowArrays = false;
    bool sectionSpacing = true;
    int precision = 6;

public:
    explicit WriteYamlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

private:
    void parseOptions(const matlab::data::Array& optsArr);
    ryml::csubstr toArena(const std::string& s);
    ryml::type_bits seqFlags();
    void setNodeValue(ryml::NodeRef node,
                      const std::string& text, bool quoted);

    static bool needsQuoting(const std::string& s);
    static bool ciEquals(const std::string& s, const char* target);
    static bool looksLikeBoolOrNull(const std::string& s);
    static bool looksLikeNumber(const std::string& s);
    static bool looksLikeDate(const std::string& s);
    std::string formatDouble(double val);
    static bool isIntegerType(matlab::data::ArrayType type);
    static int64_t readIntScalar(const matlab::data::Array& val);
    static std::vector<int64_t> readIntArray(const matlab::data::Array& val);
    std::string formatInt(int64_t val);
    void formatAndSetScalar(ryml::NodeRef node,
                            const matlab::data::Array& val);

    void buildMap(ryml::NodeRef mapNode,
                  const matlab::data::Array& nodeArr);
    void buildValue(ryml::NodeRef node,
                    const matlab::data::Array& val);
    void buildValueNode(ryml::NodeRef node,
                        const matlab::data::StructArray& vn);
    void buildObjectSequence(ryml::NodeRef node,
                             const matlab::data::Array& data);
    void buildTypedSequence(ryml::NodeRef node,
                            const matlab::data::Array& data);
    void buildCellSequence(ryml::NodeRef node,
                           const matlab::data::Array& data);

    static std::string insertSectionSpacing(const std::string& yaml);
};
