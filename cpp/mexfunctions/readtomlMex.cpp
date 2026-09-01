#include "mex.hpp"
#include "mexAdapter.hpp"

class MexFunction : public matlab::mex::Function {
public:
    void operator()(matlab::mex::ArgumentList outputs, matlab::mex::ArgumentList inputs) {
        double multiplier = inputs[0][0];
        matlab::data::TypedArray<double> in = std::move(inputs[1]);
        arrayProduct(in, multiplier);
        outputs[0] = std::move(in);
    }

    void arrayProduct(matlab::data::TypedArray<double>& inMatrix, double multiplier) {
        for (auto& elem : inMatrix) {
            elem *= multiplier;
        }
    }
};
