#include "readtoml_impl.hpp"
#include "readyaml_impl.hpp"
#include "writetoml_impl.hpp"
#include "writeyaml_impl.hpp"
#include "ryml_util.hpp"
#include "mexAdapter.hpp"

class MexFunction : public matlab::mex::Function {
    std::shared_ptr<matlab::engine::MATLABEngine> engine = getEngine();
    matlab::data::ArrayFactory factory;

    ReadTomlImpl readToml{engine};
    ReadYamlImpl readYaml{engine};
    WriteTomlImpl writeToml{engine};
    WriteYamlImpl writeYaml{engine};

public:
    MexFunction() { installRymlErrorHandlers(); }

    void operator()(matlab::mex::ArgumentList outputs,
                    matlab::mex::ArgumentList inputs) {
        if (inputs.empty()) {
            throwMexError(*engine, factory,
                "configMex:MissingCommand",
                "First argument must be a command string.");
            return;
        }

        matlab::data::TypedArray<matlab::data::MATLABString> cmdArr =
            inputs[0];
        std::string cmd = matlabStringToUtf8(cmdArr[0]);

        if (cmd == "readtoml") {
            readToml.execute(outputs, inputs);
        } else if (cmd == "readyaml") {
            readYaml.execute(outputs, inputs);
        } else if (cmd == "writetoml") {
            writeToml.execute(outputs, inputs);
        } else if (cmd == "writeyaml") {
            writeYaml.execute(outputs, inputs);
        } else {
            throwMexError(*engine, factory,
                "configMex:UnknownCommand",
                "Unknown command: " + cmd);
        }
    }
};
