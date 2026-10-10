#!/sbin/sh

# No vendor overlay from another model is applied in this PHY110-only fork.
if [ "$(getprop ro.recovery.phy110.supported)" != "1" ]; then
    printf '%s\n' 'I:variant-script: unsupported project, skipping' >> /tmp/recovery.log
    exit 1
fi

# Release existing vendor mounts without force/lazy unmounting.
if grep -q ' /vendor ' /proc/mounts; then
    umount /vendor || exit 1
fi
USB_PRODUCT=/config/usb_gadget/g1/strings/0x409/product
if [ -w "$USB_PRODUCT" ]; then
    printf '%s' 'OPPO-Find-X7-Ultra' > "$USB_PRODUCT"
fi
setprop twrp.variant.files_copied 1
