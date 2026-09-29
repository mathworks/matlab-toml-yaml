#pragma once

#include "document_handler.hpp"
#include "util.hpp"

#include <cmath>
#include <cstdint>

class MatlabWalker {
public:
    static void walk(const matlab::data::Array& nodeTree,
                     DocumentHandler& handler);

private:
    static void walkValue(const matlab::data::Array& val,
                          DocumentHandler& handler);
    static void walkObject(const matlab::data::Array& nodeArr,
                           DocumentHandler& handler);
    static void walkValueNode(const matlab::data::StructArray& vn,
                              DocumentHandler& handler);
    static void walkTypedArray(const matlab::data::Array& val,
                               DocumentHandler& handler);
    static bool isIntegerType(matlab::data::ArrayType type);
    static int64_t readIntScalar(const matlab::data::Array& val);
};
