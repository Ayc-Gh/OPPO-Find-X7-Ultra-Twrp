// Host behavior tests with mocked Android platform APIs, not an Android ABI test.
#include <cassert>
#include <map>
#include <string>
#include <sys/_system_properties.h>

std::map<std::string, prop_info> props;
std::map<std::string, std::string> bootconfig;
std::map<std::string, std::string> cmdline;

const prop_info* __system_property_find(const char* name) {
    auto it = props.find(name);
    return it == props.end() ? nullptr : &it->second;
}
int __system_property_update(prop_info* info, const char* value, unsigned int size) {
    info->value.assign(value, size);
    return 0;
}
int __system_property_add(const char* name, unsigned int name_size,
                          const char* value, unsigned int size) {
    props[std::string(name, name_size)].value.assign(value, size);
    return 0;
}
namespace android::base {
std::string GetProperty(const std::string& key, const std::string& fallback) {
    auto it = props.find(key);
    return it == props.end() ? fallback : it->second.value;
}
}
namespace android::fs_mgr {
bool Read(const std::map<std::string, std::string>& values,
          const std::string& key, std::string* output) {
    auto it = values.find(key);
    if (it == values.end()) return false;
    *output = it->second;
    return true;
}
bool GetBootconfig(const std::string& key, std::string* value) {
    return Read(bootconfig, key, value);
}
bool GetKernelCmdline(const std::string& key, std::string* value) {
    return Read(cmdline, key, value);
}
}

#include "../libinit/libinit_oplus_sm86xx.cpp"

void reset() {
    props.clear(); bootconfig.clear(); cmdline.clear();
}
void expect(bool supported) {
    vendor_load_properties();
    assert(props.at("ro.recovery.phy110.supported").value == (supported ? "1" : "0"));
    assert(props.at("ro.product.model").value == (supported ? "PHY110" : "SM86XX"));
}
int main() {
    reset(); bootconfig["androidboot.prjname"] = "22111"; expect(true);
    reset(); cmdline["androidboot.prjname"] = "22111"; expect(true);
    reset(); props["ro.boot.prjname"].value = "22111"; expect(true);
    reset(); bootconfig["androidboot.prjname"] = "22112";
    props["ro.boot.prjname"].value = "22111"; expect(false);
    for (const auto& value : {"", "invalid", "999999999999999999999999", "0", "22825"}) {
        reset(); bootconfig["androidboot.prjname"] = value; expect(false);
    }
    for (const auto& region : {"", "invalid", "99999999999999999999", "12345"}) {
        reset(); bootconfig["androidboot.prjname"] = "22111";
        bootconfig["oplus_region"] = region; expect(true);
    }
    std::cout << "libinit: 13 identity/region scenarios passed\n";
}
