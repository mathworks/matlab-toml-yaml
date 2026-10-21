#pragma once

#include "document_handler.hpp"
#include "util.hpp"

#include <string>
#include <variant>
#include <vector>

class MatlabBuilder : public DocumentHandler {
public:
    MatlabBuilder() = default;

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

    matlab::data::Array result();

private:
    matlab::data::ArrayFactory factory;

    struct MapFrame {
        std::vector<std::string> keys;
        std::vector<matlab::data::Array> values;
    };

    struct ArrayFrame {
        std::vector<matlab::data::Array> elements;
    };

    using Frame = std::variant<MapFrame, ArrayFrame>;
    std::vector<Frame> stack;
    matlab::data::Array root;

    void pushValue(matlab::data::Array val);

    template<typename T>
    void consolidateTypedArray(
            const std::vector<matlab::data::Array>& elements, size_t n) {
        auto arr = factory.createArray<T>({n, 1});
        for (size_t i = 0; i < n; ++i) {
            matlab::data::TypedArray<T> el = elements[i];
            T val = *el.begin();
            arr[i][0] = val;
        }
        pushValue(std::move(arr));
    }

    template<typename T>
    void reconstructNDArray(
            const std::vector<matlab::data::Array>& elements,
            size_t n,
            const matlab::data::ArrayDimensions& elemDims) {
        size_t elemNumel = 1;
        for (auto d : elemDims) elemNumel *= d;

        matlab::data::ArrayDimensions outDims;
        outDims.push_back(n);
        for (auto d : elemDims) outDims.push_back(d);
        while (outDims.size() > 2 && outDims.back() == 1)
            outDims.pop_back();

        std::vector<std::vector<T>> flatElements;
        flatElements.reserve(n);
        for (size_t i = 0; i < n; ++i) {
            matlab::data::TypedArray<T> typed = elements[i];
            std::vector<T> flat;
            flat.reserve(elemNumel);
            for (auto eit = typed.begin(); eit != typed.end(); ++eit) {
                T val = *eit;
                flat.push_back(std::move(val));
            }
            flatElements.push_back(std::move(flat));
        }

        auto arr = factory.createArray<T>(outDims);
        size_t totalNumel = n * elemNumel;
        auto it = arr.begin();
        for (size_t linearIdx = 0; linearIdx < totalNumel; ++linearIdx) {
            size_t i = linearIdx % n;
            size_t j = linearIdx / n;
            T val = flatElements[i][j];
            *it = val;
            ++it;
        }
        pushValue(std::move(arr));
    }
};
