#pragma once
#include <string>
namespace android::fs_mgr {
bool GetBootconfig(const std::string&, std::string*);
bool GetKernelCmdline(const std::string&, std::string*);
}
