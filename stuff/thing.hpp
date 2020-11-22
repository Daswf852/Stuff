#pragma once

#include <string>
#include <vector>

class Thing {
  public:
    virtual ~Thing() = default;
    virtual int DoThings(const std::vector<std::string> &arguments) = 0;
};
