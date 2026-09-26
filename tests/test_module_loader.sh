#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
FIX="$ROOT/tests/fixtures"
LOADER="$ROOT/recovery/root/system/bin/load-phy110-modules.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

V="$TMP/vendor/lib/modules"
S="$TMP/system/lib/modules"
mkdir -p "$V/kernel/test" "$S/kernel/test"
cp "$FIX/vendor_dlkm/lib/modules/modules.dep" "$V/modules.dep"
cp "$FIX/system_dlkm/lib/modules/modules.dep" "$S/modules.dep"
: > "$TMP/proc_modules"

for dep in "$V/modules.dep" "$S/modules.dep"; do
    sed 's/:/ /' "$dep" | tr ' ' '\n' | sed '/^$/d;s#^.*/##' | sort -u | while read -r ko; do
        case "$ko" in
          *.ko)
            if grep -q "system_dlkm" <<< "$dep"; then
              : > "$S/kernel/test/$ko"
            else
              : > "$V/kernel/test/$ko"
            fi
            ;;
        esac
    done
done

run_mode() {
    local mode=$1
    PHY110_DRY_RUN=1 \
    PHY110_VENDOR_MODULE_DIR="$V" \
    PHY110_SYSTEM_MODULE_DIR="$S" \
    PHY110_PROC_MODULES="$TMP/proc_modules" \
    PHY110_WORK_DIR="$TMP/work-$mode" \
    PHY110_LOG="$TMP/$mode.log" \
    sh "$LOADER" "$mode"
}
run_mode base
run_mode wifi
grep -q 'DRY-RUN insmod .*oplus_bsp_synaptics_tcm2.ko' "$TMP/base.log"
grep -q 'DRY-RUN insmod .*smcinvoke_dlkm.ko' "$TMP/base.log"
grep -q 'DRY-RUN insmod .*qca_cld3_kiwi_v2.ko' "$TMP/wifi.log"
grep -q 'twrp.wifi.modules=ready' "$TMP/wifi.log"
cnss_line=$(grep -n 'DRY-RUN insmod .*cnss2.ko' "$TMP/wifi.log" | head -1 | cut -d: -f1)
kiwi_line=$(grep -n 'DRY-RUN insmod .*qca_cld3_kiwi_v2.ko' "$TMP/wifi.log" | head -1 | cut -d: -f1)
[ "$cnss_line" -lt "$kiwi_line" ]
echo 'PASS: module-loader dynamic dry-run'
