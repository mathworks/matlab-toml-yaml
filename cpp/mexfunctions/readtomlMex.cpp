#include "mex.hpp"
#include "mexAdapter.hpp"

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;

public:
    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        // Construct an empty TOMLData object via MATLAB
        matlab::data::Array tomlObj = engine->feval(
            u"matlab.io.config.TOMLData",
            std::vector<matlab::data::Array>{});

        outputs[0] = tomlObj;
    }
};
