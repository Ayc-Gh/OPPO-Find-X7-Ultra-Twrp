#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
fail=0
ok() { printf 'PASS: %s\n' "$1"; }
bad() { printf 'FAIL: %s\n' "$1" >&2; fail=1; }
need() { grep -Fq -- "$2" "$ROOT/$1" && ok "$1 contains $2" || bad "$1 missing $2"; }
forbid() { if grep -RFn --exclude-dir=.git -- "$2" "$ROOT/$1" >/dev/null 2>&1; then bad "$1 contains forbidden $2"; else ok "$1 excludes $2"; fi; }
forbid_sources() { local pat=$1; if grep -Fn -- "$pat" "$ROOT/BoardConfig.mk" "$ROOT/device.mk" "$ROOT/system.prop" "$ROOT/recovery.fstab" "$ROOT/libinit/libinit_phy110.cpp" >/dev/null 2>&1 || grep -RFn -- "$pat" "$ROOT/recovery" >/dev/null 2>&1; then bad "source contains forbidden $pat"; else ok "source excludes $pat"; fi; }

need BoardConfig.mk 'BOARD_SUPER_PARTITION_SIZE := 17716740096'
need BoardConfig.mk 'BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(($(BOARD_SUPER_PARTITION_SIZE) - 4194304)))'
need BoardConfig.mk 'BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600'
need BoardConfig.mk 'TARGET_RECOVERY_DEVICE_MODULES += libinit_phy110'
need common/BoardConfigCommon.mk 'TARGET_COPY_OUT_VENDOR := vendor'
need common/BoardConfigCommon.mk 'TARGET_COPY_OUT_ODM := odm'
need common/BoardConfigCommon.mk 'TW_EXCLUDE_APEX := true'
need device.mk 'PRODUCT_TARGET_VNDK_VERSION := 34'
need recovery.fstab '/dev/block/by-name/metadata /metadata f2fs'
need recovery.fstab '/dev/block/bootdevice/by-name/persist /mnt/vendor/persist ext4'
need recovery/root/init.recovery.qcom.rc 'wait /sys/kernel/boot_adsp/boot 10'
need recovery/root/init.recovery.qcom.rc 'write /sys/kernel/boot_adsp/boot 1'
need recovery/root/init.recovery.qcom.rc 'wait /sys/kernel/boot_adsp/ssr 10'
need recovery/root/init.recovery.qcom.rc '/vendor/bin/hw/android.hardware.security.keymint-service-qti'
need recovery/root/init.recovery.qcom.rc '/odm/bin/hw/android.hardware.weaver-service.nxp'
need recovery/root/init.recovery.qcom.rc 'service phy110-qseecomd /vendor/bin/qseecomd'
need recovery/root/init.recovery.qcom.rc 'service phy110-keymint-qti /vendor/bin/hw/android.hardware.security.keymint-service-qti'
need recovery/root/init.recovery.wifi.rc 'service phy110-wpa-supplicant /vendor/bin/hw/wpa_supplicant'
forbid recovery/root/init.recovery.qcom.rc 'service vendor.qseecomd /vendor/bin/qseecomd'
forbid recovery/root/init.recovery.qcom.rc 'service vendor.keymint-qti /vendor/bin/hw/android.hardware.security.keymint-service-qti'
forbid recovery/root/init.recovery.wifi.rc 'service vendor.rmt_storage /vendor/bin/rmt_storage'
forbid recovery/root/init.recovery.wifi.rc 'service wpa_supplicant /vendor/bin/hw/wpa_supplicant'
forbid recovery/root/init.recovery.wifi.rc 'service cnss-daemon /vendor/bin/cnss-daemon'
need recovery/root/system/bin/load-phy110-modules.sh 'qca_cld3_kiwi_v2.ko'
need recovery/root/system/bin/load-phy110-modules.sh 'oplus_bsp_synaptics_tcm2.ko'
need libinit/libinit_phy110.cpp 'constexpr int kPhy110Project = 22111;'
need libinit/libinit_phy110.cpp 'ParseInt('

forbid_sources 'std::stoi'
forbid_sources '/dev/block/sdg1'
forbid_sources 'cpko.sh'
forbid recovery/root/init.recovery.usb.rc '/config/usb_gadget/g2'
forbid BoardConfig.mk 'TW_LOAD_VENDOR_MODULES'
forbid BoardConfig.mk 'TARGET_RECOVERY_DEVICE_MODULES  :='

if find "$ROOT/recovery" -type f \( -name '*.so' -o -name '*.ko' \) -print -quit | grep -q .; then
    bad 'device tree contains embedded .so/.ko blob'
else
    ok 'no embedded .so/.ko blobs'
fi

for s in "$ROOT"/recovery/root/system/bin/*.sh "$ROOT"/tests/*.sh; do
    bash -n "$s" || bad "shell syntax: $s"
done
ok 'shell syntax'

if grep -REn '^\s*wait /sys/' "$ROOT/recovery/root" | grep -Ev ' [0-9]+$' >/dev/null; then
    bad 'unbounded /sys wait in init rc'
else
    ok 'device-dependent init waits are bounded'
fi

exit "$fail"
