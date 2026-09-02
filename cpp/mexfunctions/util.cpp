#include "util.hpp"

std::string matlabStringToUtf8(
    matlab::data::ArrayFactory& factory,
    const matlab::data::MATLABString& ms) {
    if (!ms.has_value()) {
        return {};
    }
    return factory.createCharArray(*ms).toUTF8();
}

matlab::data::Array makeString(
    matlab::data::ArrayFactory& factory,
    const std::string& utf8) {
    matlab::data::CharArray ca = factory.createCharArrayFromUTF8(utf8);
    std::u16string u16(ca.begin(), ca.end());
    auto arr = factory.createArray<matlab::data::MATLABString>({1, 1});
    arr[0] = matlab::data::MATLABString(std::move(u16));
    return arr;
}

void throwMexError(
    matlab::engine::MATLABEngine& engine,
    matlab::data::ArrayFactory& factory,
    const std::string& id,
    const std::string& msg) {
    engine.feval(u"error",
        {factory.createCharArray(id), factory.createCharArray(msg)});
}
