/* SPDX-License-Identifier: Apache-2.0 */
#include <android-base/logging.h>
#include <android-base/parseint.h>
#include <android-base/properties.h>
#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

#include <fs_mgr.h>
#include <cstring>
#include <string>
#include <unordered_map>
#include <utility>

using android::base::GetProperty;
using android::base::ParseInt;
using android::fs_mgr::GetKernelCmdline;

namespace {
constexpr int kPhy110Project = 22111;

const std::unordered_map<int, std::string> kRegionSuffix = {
    {27, "IN"}, {55, "RU"}, {68, "EEA"}, {151, ""}, {161, "NA"}, {167, ""}, {0, ""},
};

void OverrideProperty(const char* name, const std::string& value) {
    prop_info* pi = const_cast<prop_info*>(__system_property_find(name));
    if (pi != nullptr) {
        __system_property_update(pi, value.c_str(), value.size());
    } else {
        __system_property_add(name, strlen(name), value.c_str(), value.size());
    }
}

void SetPhy110Properties(const std::string& region_suffix) {
    const std::string product_name = std::string("PHY110") + region_suffix;
    const std::pair<const char*, std::string> props[] = {
        {"ro.product.brand", "OPPO"},
        {"ro.product.device", "OP565FL1"},
        {"ro.product.manufacturer", "OPPO"},
        {"ro.product.model", "PHY110"},
        {"ro.product.name", product_name},
        {"ro.product.system.device", "PHY110"},
        {"ro.product.system.model", "PHY110"},
        {"ro.product.system_ext.device", "PHY110"},
        {"ro.product.system_ext.model", "PHY110"},
        {"ro.product.product.device", "PHY110"},
        {"ro.product.product.model", "PHY110"},
        {"ro.product.vendor.device", "OP565FL1"},
        {"ro.product.vendor.model", "PHY110"},
        {"ro.product.odm.device", "OP565FL1"},
        {"ro.product.odm.model", "PHY110"},
        {"ro.twrp.device_version", "OPPO-Find-X7-Ultra-PHY110"},
        {"ro.twrp.y_offset", "116"},
        {"ro.twrp.h_offset", "-116"},
        {"vendor.display.enable_spr", "0"},
        {"ro.build.date.utc", "0"},
    };

    for (const auto& [key, value] : props) OverrideProperty(key, value);
}
}  // namespace

void vendor_load_properties() {
    int project = 0;
    if (!ParseInt(GetProperty("ro.boot.prjname", "0"), &project)) {
        LOG(WARNING) << "Invalid ro.boot.prjname; continuing with guarded PHY110 defaults";
    }

    if (project != 0 && project != kPhy110Project) {
        LOG(ERROR) << "This recovery targets PHY110 project 22111; detected project " << project;
        OverrideProperty("ro.twrp.unsupported_device", "1");
        return;
    }

    std::string region_raw = "0";
    GetKernelCmdline("oplus_region", &region_raw);
    int region = 0;
    if (!ParseInt(region_raw, &region)) {
        LOG(WARNING) << "Invalid oplus_region '" << region_raw << "'; using default";
        region = 0;
    }

    auto it = kRegionSuffix.find(region);
    if (it == kRegionSuffix.end()) {
        LOG(WARNING) << "Unknown oplus_region " << region << "; using default";
        it = kRegionSuffix.find(0);
    }

    SetPhy110Properties(it->second);
}
