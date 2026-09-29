#include "matlab_walker.hpp"

using matlab::data::ArrayType;

void MatlabWalker::walk(const matlab::data::Array& nodeTree,
                        DocumentHandler& handler) {
    walkValue(nodeTree, handler);
}

void MatlabWalker::walkValue(const matlab::data::Array& val,
                             DocumentHandler& handler) {
    auto type = val.getType();
    size_t numel = val.getNumberOfElements();

    if (type == ArrayType::STRUCT) {
        matlab::data::StructArray sa(val);
        if (structHasField(sa, "Keys")) {
            walkObject(val, handler);
            return;
        }
        if (structHasField(sa, "Data")) {
            walkValueNode(sa, handler);
            return;
        }
        if (numel == 0) {
            handler.nullValue();
            return;
        }
        walkObject(val, handler);
        return;
    }

    if (type == ArrayType::CELL) {
        matlab::data::TypedArray<matlab::data::Array> cells = val;
        if (numel == 0) {
            handler.startArray(0);
            handler.endArray();
            return;
        }
        handler.startArray(numel);
        for (size_t i = 0; i < numel; ++i) {
            walkValue(cells[i], handler);
        }
        handler.endArray();
        return;
    }

    if (numel > 1) {
        walkTypedArray(val, handler);
        return;
    }

    if (numel == 0) {
        handler.startArray(0);
        handler.endArray();
        return;
    }

    if (type == ArrayType::LOGICAL) {
        matlab::data::TypedArray<bool> arr = val;
        handler.boolValue(arr[0]);
    } else if (type == ArrayType::DOUBLE || type == ArrayType::SINGLE) {
        matlab::data::TypedArray<double> arr = val;
        double d = arr[0];
        if (!std::isnan(d) && !std::isinf(d) &&
            d == std::floor(d) &&
            std::abs(d) < static_cast<double>(1LL << 53)) {
            handler.intValue(static_cast<int64_t>(d));
        } else {
            handler.doubleValue(d);
        }
    } else if (type == ArrayType::UINT64) {
        matlab::data::TypedArray<uint64_t> arr = val;
        handler.uintValue(arr[0]);
    } else if (isIntegerType(type)) {
        handler.intValue(readIntScalar(val));
    } else if (type == ArrayType::MATLAB_STRING) {
        matlab::data::TypedArray<matlab::data::MATLABString> arr = val;
        std::string text = matlabStringToUtf8(arr[0]);
        handler.stringValue(text);
    }
}

void MatlabWalker::walkObject(const matlab::data::Array& nodeArr,
                              DocumentHandler& handler) {
    matlab::data::StructArray node(nodeArr);

    matlab::data::TypedArray<matlab::data::MATLABString> keys =
        node[0]["Keys"];
    matlab::data::TypedArray<matlab::data::Array> values =
        node[0]["Values"];

    size_t n = keys.getNumberOfElements();
    handler.startObject(n);

    for (size_t i = 0; i < n; ++i) {
        std::string keyStr = matlabStringToUtf8(keys[i]);
        handler.key(keyStr);
        walkValue(values[i], handler);
    }

    handler.endObject();
}

void MatlabWalker::walkValueNode(const matlab::data::StructArray& vn,
                                 DocumentHandler& handler) {
    if (structHasField(vn, "Type")) {
        matlab::data::TypedArray<matlab::data::MATLABString> typeArr =
            vn[0]["Type"];
        std::string nodeType = matlabStringToUtf8(typeArr[0]);

        if (nodeType == "missing") {
            handler.nullValue();
            return;
        }

        if (nodeType == "datetime") {
            matlab::data::Array data = vn[0]["Data"];
            if (data.getType() == ArrayType::MATLAB_STRING) {
                matlab::data::TypedArray<matlab::data::MATLABString>
                    strArr = data;
                std::string iso = matlabStringToUtf8(strArr[0]);
                handler.datetimeValue(iso);
            } else {
                walkValue(data, handler);
            }
            return;
        }
    }

    matlab::data::Array data = vn[0]["Data"];
    walkValue(data, handler);
}

void MatlabWalker::walkTypedArray(const matlab::data::Array& val,
                                  DocumentHandler& handler) {
    auto type = val.getType();
    size_t numel = val.getNumberOfElements();
    handler.startArray(numel);

    if (type == ArrayType::LOGICAL) {
        matlab::data::TypedArray<bool> arr = val;
        for (size_t i = 0; i < numel; ++i) {
            handler.boolValue(arr[i]);
        }
    } else if (type == ArrayType::DOUBLE || type == ArrayType::SINGLE) {
        matlab::data::TypedArray<double> arr = val;
        for (size_t i = 0; i < numel; ++i) {
            double d = arr[i];
            if (!std::isnan(d) && !std::isinf(d) &&
                d == std::floor(d) &&
                std::abs(d) < static_cast<double>(1LL << 53)) {
                handler.intValue(static_cast<int64_t>(d));
            } else {
                handler.doubleValue(d);
            }
        }
    } else if (type == ArrayType::UINT64) {
        matlab::data::TypedArray<uint64_t> arr = val;
        for (size_t i = 0; i < numel; ++i) {
            handler.uintValue(arr[i]);
        }
    } else if (isIntegerType(type)) {
        switch (type) {
        case ArrayType::INT8:   { matlab::data::TypedArray<int8_t>   a = val; for (auto v : a) handler.intValue(v); break; }
        case ArrayType::INT16:  { matlab::data::TypedArray<int16_t>  a = val; for (auto v : a) handler.intValue(v); break; }
        case ArrayType::INT32:  { matlab::data::TypedArray<int32_t>  a = val; for (auto v : a) handler.intValue(v); break; }
        case ArrayType::INT64:  { matlab::data::TypedArray<int64_t>  a = val; for (auto v : a) handler.intValue(v); break; }
        case ArrayType::UINT8:  { matlab::data::TypedArray<uint8_t>  a = val; for (auto v : a) handler.intValue(v); break; }
        case ArrayType::UINT16: { matlab::data::TypedArray<uint16_t> a = val; for (auto v : a) handler.intValue(v); break; }
        case ArrayType::UINT32: { matlab::data::TypedArray<uint32_t> a = val; for (auto v : a) handler.intValue(v); break; }
        default: break;
        }
    } else if (type == ArrayType::MATLAB_STRING) {
        matlab::data::TypedArray<matlab::data::MATLABString> arr = val;
        for (size_t i = 0; i < numel; ++i) {
            std::string text = matlabStringToUtf8(arr[i]);
            handler.stringValue(text);
        }
    }

    handler.endArray();
}

bool MatlabWalker::isIntegerType(matlab::data::ArrayType type) {
    return type == ArrayType::INT8  || type == ArrayType::INT16 ||
           type == ArrayType::INT32 || type == ArrayType::INT64 ||
           type == ArrayType::UINT8 || type == ArrayType::UINT16 ||
           type == ArrayType::UINT32;
}

int64_t MatlabWalker::readIntScalar(const matlab::data::Array& val) {
    switch (val.getType()) {
    case ArrayType::INT8:   { matlab::data::TypedArray<int8_t>   a = val; return a[0]; }
    case ArrayType::INT16:  { matlab::data::TypedArray<int16_t>  a = val; return a[0]; }
    case ArrayType::INT32:  { matlab::data::TypedArray<int32_t>  a = val; return a[0]; }
    case ArrayType::INT64:  { matlab::data::TypedArray<int64_t>  a = val; return a[0]; }
    case ArrayType::UINT8:  { matlab::data::TypedArray<uint8_t>  a = val; return a[0]; }
    case ArrayType::UINT16: { matlab::data::TypedArray<uint16_t> a = val; return a[0]; }
    case ArrayType::UINT32: { matlab::data::TypedArray<uint32_t> a = val; return a[0]; }
    default: return 0;
    }
}
