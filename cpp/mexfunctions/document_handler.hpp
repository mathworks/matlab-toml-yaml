#pragma once

#include <cstddef>
#include <cstdint>
#include <map>
#include <string>
#include <string_view>
#include <vector>

// Format metadata attached to a node or key. Fields hold only non-default
// values (e.g. "IntegerFormat" -> "hex"); Comments holds comment lines
// without the leading "#".
struct NodeMeta {
    std::map<std::string, std::string> fields;
    std::vector<std::string> comments;

    bool empty() const { return fields.empty() && comments.empty(); }

    std::string get(const std::string& name) const {
        auto it = fields.find(name);
        return it == fields.end() ? std::string() : it->second;
    }
};

class DocumentHandler {
public:
    virtual ~DocumentHandler() = default;

    virtual void startObject(size_t count) = 0;
    virtual void key(std::string_view k) = 0;
    virtual void endObject() = 0;

    virtual void startArray(size_t count) = 0;
    virtual void endArray() = 0;

    virtual void nullValue() = 0;
    virtual void boolValue(bool b) = 0;
    virtual void intValue(int64_t i) = 0;
    virtual void uintValue(uint64_t u) = 0;
    virtual void doubleValue(double d) = 0;
    virtual void stringValue(std::string_view s) = 0;
    virtual void datetimeValue(std::string_view iso) = 0;

    // Metadata for the next value (scalar, startObject, or startArray).
    virtual void metadata(const NodeMeta& /*m*/) {}
    // Metadata for the key most recently passed to key().
    virtual void keyMetadata(const NodeMeta& /*m*/) {}
};
