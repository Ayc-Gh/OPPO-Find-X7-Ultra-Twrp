#!/sbin/sh

# Run only inside recovery; read active-slot SPL without modifying filesystems.
SCRIPTNAME="override-spl.sh"
TEMP_ROOT="/tmp/phy110-spl.$$"
MOUNTED_DIR=""

log() {
    printf 'I:%s: %s\n' "$SCRIPTNAME" "$1" >> /tmp/recovery.log
}

cleanup() {
    if [ -n "$MOUNTED_DIR" ]; then
        if ! umount "$MOUNTED_DIR"; then
            log "Unmount failed; keeping mounted directory intact: $MOUNTED_DIR"
            return 1
        fi
        MOUNTED_DIR=""
    fi
    # No recursive removal, even on error.
    rmdir "$TEMP_ROOT/vendor" "$TEMP_ROOT/system" "$TEMP_ROOT" 2>/dev/null
    return 0
}

trap 'cleanup' EXIT
trap 'exit 1' HUP INT TERM

if [ "$(getprop ro.twrp.fastbootd)" = "1" ]; then
    log "Skipping SPL preparation in fastbootd"
    exit 0
fi
setprop crypto.ready 0 || exit 1
if [ "$(getprop ro.recovery.phy110.supported)" != "1" ]; then
    log "Refusing SPL preparation on an unverified PHY110 project"
    exit 1
fi

SLOT=$(getprop ro.boot.slot_suffix)
case "$SLOT" in
    _a|_b) ;;
    *) log "Missing or invalid slot"; exit 1 ;;
esac

mkdir -m 0700 "$TEMP_ROOT" || exit 1
mkdir -m 0700 "$TEMP_ROOT/vendor" "$TEMP_ROOT/system" || exit 1

read_spl() {
    SPL_DEVICE="$1"
    SPL_MOUNT="$2"
    SPL_KEY="$3"
    READ_SPL=""
    if [ ! -b "$SPL_DEVICE" ]; then
        log "Logical block device not available: $SPL_DEVICE"
        return 1
    fi
    if ! mount -t erofs -o ro,nodev,nosuid,noexec "$SPL_DEVICE" "$SPL_MOUNT"; then
        # ro alone can replay an ext4 journal; noload prevents that.
        if ! mount -t ext4 -o ro,noload,nodev,nosuid,noexec "$SPL_DEVICE" "$SPL_MOUNT"; then
            log "Read-only mount failed: $SPL_DEVICE"
            return 1
        fi
    fi
    MOUNTED_DIR="$SPL_MOUNT"
    for PROP_FILE in "$SPL_MOUNT/build.prop" "$SPL_MOUNT/etc/build.prop" \
        "$SPL_MOUNT/system/build.prop" "$SPL_MOUNT/system/etc/build.prop"; do
        [ -f "$PROP_FILE" ] || continue
        READ_SPL=$(awk -F= -v key="$SPL_KEY" '$1 == key {print $2; exit}' "$PROP_FILE")
        [ -n "$READ_SPL" ] && break
    done
    if ! umount "$SPL_MOUNT"; then
        log "Unmount failed: $SPL_MOUNT"
        return 1
    fi
    MOUNTED_DIR=""
    if ! printf '%s\n' "$READ_SPL" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$'; then
        log "Missing or malformed security patch date: $SPL_KEY"
        return 1
    fi
}

read_spl "/dev/block/mapper/vendor$SLOT" "$TEMP_ROOT/vendor" \
    ro.vendor.build.security_patch || exit 1
VENDOR_SPL="$READ_SPL"
read_spl "/dev/block/mapper/system$SLOT" "$TEMP_ROOT/system" \
    ro.build.version.security_patch || exit 1
SYSTEM_SPL="$READ_SPL"

# Both reads and unmounts must succeed before publishing crypto readiness.
resetprop ro.vendor.build.security_patch "$VENDOR_SPL" || exit 1
resetprop ro.build.version.security_patch "$SYSTEM_SPL" || exit 1
setprop crypto.ready 1 || exit 1
log "SPL preparation complete for $SLOT: system=$SYSTEM_SPL vendor=$VENDOR_SPL"
