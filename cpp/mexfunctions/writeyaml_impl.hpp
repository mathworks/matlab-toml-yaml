#pragma once

#include "document_handler.hpp"
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

class WriteYamlImpl : public DocumentHandler {
    std::shared_ptr<matlab::engine::MATLABEngine> engine;
    matlab::data::ArrayFactory factory;

    ryml::Tree tree;
    bool flowArrays = false;
    bool sectionSpacing = true;
    int precision = 6;

    std::vector<ryml::NodeRef> stack;
    std::string pendingKey;
    bool hasPendingKey = false;

public:
    explicit WriteYamlImpl(std::shared_ptr<matlab::engine::MATLABEngine> eng);
    void execute(matlab::mex::ArgumentList outputs,
                 matlab::mex::ArgumentList inputs);

    void startObject(size_t count) override;
    void key(std::string_view k) override;
    void endObject() override;
    void startArray(size_t count) override;
    void endArray() override;
    void nullValue() override;
    void boolValue(bool b) override;
    void intValue(int64_t i) override;
    void uintValue(uint64_t u) override;
    void doubleValue(double d) override;
    void stringValue(std::string_view s) override;
    void datetimeValue(std::string_view iso) override;

private:
    void parseOptions(const matlab::data::Array& optsArr);
    ryml::csubstr toArena(const std::string& s);
    ryml::type_bits seqFlags();
    void setNodeValue(ryml::NodeRef node,
                      const std::string& text, bool quoted);
    ryml::NodeRef allocChild();

    static bool needsQuoting(const std::string& s);
    static bool ciEquals(const std::string& s, const char* target);
    static bool looksLikeBoolOrNull(const std::string& s);
    static bool looksLikeNumber(const std::string& s);
    static bool looksLikeDate(const std::string& s);
    std::string formatDouble(double val);
    std::string formatInt(int64_t val);

    static std::string insertSectionSpacing(const std::string& yaml);
};
