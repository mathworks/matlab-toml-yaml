#include "util.hpp"
#include "cppmex/detail/mexExceptionImpl.hpp"

std::string matlabStringToUtf8(const matlab::data::MATLABString& ms) {
    if (!ms.has_value()) {
        return {};
    }
    const auto& str = *ms;
    if (str.empty()) {
        return {};
    }
    return matlab::engine::convertUTF16StringToUTF8String(str);
}

matlab::data::MATLABString utf8ToMATLABString(const std::string& utf8) {
    return matlab::data::MATLABString(matlab::engine::convertUTF8StringToUTF16String(utf8));
}

void throwMexError(
    matlab::engine::MATLABEngine& engine,
    matlab::data::ArrayFactory& factory,
    const std::string& id,
    const std::string& msg) {
    engine.feval(u"error", 0,
        {factory.createCharArray(id), factory.createCharArray(msg)});
}
