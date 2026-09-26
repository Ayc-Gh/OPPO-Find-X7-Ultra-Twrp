#!/system/bin/sh
# Resolve current stock kernel-module dependencies at runtime. No KO is baked
# into the recovery image, which keeps the recovery aligned with ColorOS OTAs.

LOG=${PHY110_LOG:-/tmp/recovery.log}
VENDOR_DIR=${PHY110_VENDOR_MODULE_DIR:-/vendor_dlkm/lib/modules}
SYSTEM_DIR=${PHY110_SYSTEM_MODULE_DIR:-/system_dlkm/lib/modules}
PROC_MODULES=${PHY110_PROC_MODULES:-/proc/modules}
DRY_RUN=${PHY110_DRY_RUN:-0}
WORK=${PHY110_WORK_DIR:-/tmp/phy110-modules}
MODE=${1:-base}

log() { echo "I:phy110-modules: $*" | tee -a "$LOG" >/dev/null; }
set_status() {
    [ "$DRY_RUN" = "1" ] || setprop "$1" "$2" 2>/dev/null || true
    log "$1=$2"
}

if [ "$DRY_RUN" != "1" ] && [ "$(getprop ro.twrp.fastbootd 2>/dev/null)" = "1" ]; then
    log "fastbootd detected; module loading skipped"
    exit 0
fi

mkdir -p "$WORK" || exit 1
INDEX="$WORK/index"
DEPFILES="$WORK/depfiles"
: > "$INDEX"
: > "$DEPFILES"

for d in "$VENDOR_DIR" "$SYSTEM_DIR"; do
    [ -d "$d" ] || continue
    find "$d" -type f -name '*.ko' 2>/dev/null | while IFS= read -r p; do
        printf '%s\t%s\n' "$(basename "$p")" "$p"
    done >> "$INDEX"
    find "$d" -type f -name modules.dep 2>/dev/null >> "$DEPFILES"
done

module_path() { awk -F '\t' -v n="$1" '$1==n {print $2; exit}' "$INDEX"; }
module_loaded() {
    local loaded_name
    loaded_name=$(basename "$1" .ko | tr '-' '_')
    [ -r "$PROC_MODULES" ] && awk -v n="$loaded_name" '$1==n {found=1} END{exit !found}' "$PROC_MODULES"
}
module_deps() {
    local dep_name depfile line
    dep_name=$1
    while IFS= read -r depfile; do
        [ -r "$depfile" ] || continue
        line=$(grep "/$dep_name:" "$depfile" 2>/dev/null | head -n 1)
        [ -n "$line" ] || line=$(grep "^$dep_name:" "$depfile" 2>/dev/null | head -n 1)
        [ -n "$line" ] || continue
        printf '%s\n' "${line#*:}" | tr ' ' '\n' | sed '/^$/d;s#^.*/##'
        return 0
    done < "$DEPFILES"
    return 0
}

load_one() {
    local n dep p
    n=$1
    module_loaded "$n" && { log "$n already loaded"; return 0; }
    grep -Fxq "$n" "$WORK/done" 2>/dev/null && return 0
    if grep -Fxq "$n" "$WORK/visiting" 2>/dev/null; then
        log "dependency cycle at $n"
        return 1
    fi
    echo "$n" >> "$WORK/visiting"
    for dep in $(module_deps "$n"); do
        load_one "$dep" || return 1
    done
    p=$(module_path "$n")
    if [ -z "$p" ]; then
        log "module not found: $n"
        return 1
    fi
    if [ "$DRY_RUN" = "1" ]; then
        log "DRY-RUN insmod $p"
    elif ! insmod "$p" 2>>"$LOG"; then
        module_loaded "$n" || { log "insmod failed: $n"; return 1; }
    fi
    echo "$n" >> "$WORK/done"
    log "loaded $n"
    return 0
}

: > "$WORK/done"
: > "$WORK/visiting"

case "$MODE" in
    base)
        set_status twrp.phy110.base_modules loading
        failures=0
        for target in \
            oplus_bsp_synaptics_tcm2.ko \
            adsp_loader_dlkm.ko \
            oplus_chg_v2.ko \
            qseecom_proxy.ko \
            smcinvoke_dlkm.ko \
            stm_st54se_gpio.ko \
            nxp-nci.ko; do
            load_one "$target" || failures=$((failures + 1))
        done
        if [ "$failures" -eq 0 ]; then
            set_status twrp.phy110.base_modules ready
        else
            set_status twrp.phy110.base_modules degraded
            log "$failures optional/base target(s) failed"
        fi
        ;;
    wifi)
        set_status twrp.wifi.modules loading
        load_one rfkill.ko || log "rfkill not loadable; it may be built-in"
        for node in /sys/devices/platform/soc/b0000000.qcom,cnss-kiwi/fs_ready /sys/devices/platform/soc/*cnss*/fs_ready; do
            [ -e "$node" ] || continue
            [ "$DRY_RUN" = "1" ] || echo 1 > "$node" 2>/dev/null || true
            break
        done
        if ! load_one qca_cld3_kiwi_v2.ko; then
            set_status twrp.wifi.modules failed
            exit 1
        fi
        if [ "$DRY_RUN" = "1" ]; then
            set_status twrp.wifi.modules ready
            exit 0
        fi
        i=0
        while [ "$i" -lt 15 ]; do
            [ -e /sys/class/net/wlan0 ] && { set_status twrp.wifi.modules ready; exit 0; }
            sleep 1
            i=$((i + 1))
        done
        log "wlan0 did not appear within 15 seconds"
        set_status twrp.wifi.modules failed
        exit 1
        ;;
    *)
        log "unknown mode: $MODE"
        exit 2
        ;;
esac
