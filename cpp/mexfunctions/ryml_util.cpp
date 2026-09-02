#define RYML_SINGLE_HDR_DEFINE_NOW
#include "ryml_util.hpp"

#include <stdexcept>
#include <string>

[[noreturn]] static void errorBasic(ryml::csubstr msg,
    ryml::ErrorDataBasic const&, void*) {
    throw std::runtime_error(std::string(msg.data(), msg.size()));
}
[[noreturn]] static void errorParse(ryml::csubstr msg,
    ryml::ErrorDataParse const&, void*) {
    throw std::runtime_error(std::string(msg.data(), msg.size()));
}
[[noreturn]] static void errorVisit(ryml::csubstr msg,
    ryml::ErrorDataVisit const&, void*) {
    throw std::runtime_error(std::string(msg.data(), msg.size()));
}

void installRymlErrorHandlers() {
    ryml::Callbacks cb = ryml::get_callbacks();
    cb.set_error_basic(&errorBasic);
    cb.set_error_parse(&errorParse);
    cb.set_error_visit(&errorVisit);
    ryml::set_callbacks(cb);
}
