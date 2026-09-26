#!/system/bin/sh
# Use the mounted stock ColorOS vendor/system as the ABI source of truth.
# This avoids baking stale KeyMint/Gatekeeper/QSEE/Wi-Fi userspace into recovery.

LOG=/tmp/recovery.log
log() { echo "I:phy110-stock: $*" | tee -a "$LOG" >/dev/null; }

find_prop() {
    key=$1
    shift
    for f in "$@"; do
        [ -f "$f" ] || continue
        value=$(grep -m1 "^${key}=" "$f" 2>/dev/null | cut -d= -f2-)
        [ -n "$value" ] && { printf '%s\n' "$value"; return 0; }
    done
    return 1
}

for p in /vendor /odm /vendor_dlkm /system_dlkm /metadata /mnt/vendor/persist; do
    if ! grep -q " $p " /proc/mounts 2>/dev/null; then
        log "$p is not mounted"
    fi
done

vendor_spl=$(find_prop ro.vendor.build.security_patch /vendor/build.prop /vendor/default.prop)
system_spl=$(find_prop ro.build.version.security_patch /system/build.prop /system/system/build.prop /system/etc/build.prop)

if [ -n "$vendor_spl" ]; then
    resetprop ro.vendor.build.security_patch "$vendor_spl"
    log "vendor SPL -> $vendor_spl"
else
    log "vendor SPL not found"
fi

if [ -n "$system_spl" ]; then
    resetprop ro.build.version.security_patch "$system_spl"
    log "system SPL -> $system_spl"
else
    log "system SPL not found"
fi

# Runtime vendor ABI facts verified on the target device.
resetprop ro.product.first_api_level 34
resetprop ro.board.first_api_level 34
resetprop ro.board.api_level 34
resetprop ro.vendor.api_level 34
resetprop ro.vndk.version 34
setprop crypto.ready 1

# Publish which stock components are actually available before init starts them.
for pair in \
    qseecomd:/vendor/bin/qseecomd \
    qseecom_aidl:/vendor/bin/hw/vendor.qti.hardware.qseecom@1.0-service \
    keymint:/vendor/bin/hw/android.hardware.security.keymint-service-qti \
    gatekeeper:/vendor/bin/hw/android.hardware.gatekeeper-service-qti \
    weaver:/odm/bin/hw/android.hardware.weaver-service.nxp; do
    name=${pair%%:*}
    path=${pair#*:}
    if [ -x "$path" ]; then
        setprop "twrp.phy110.stock.$name" present
    else
        setprop "twrp.phy110.stock.$name" missing
        log "missing stock component: $path"
    fi
done
