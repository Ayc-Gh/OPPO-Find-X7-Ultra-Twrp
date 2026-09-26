# OPPO Find X7 Ultra TWRP (PHY110)

A PHY110-specific TWRP 16 device tree rebuilt from current `TWRP-Test` upstream rather than layering more patches on the archived generic sm86xx tree.

## Target

- OPPO Find X7 Ultra `PHY110`
- OPlus device ID `OP565FL1`
- Project ID `22111`
- Android 16 ColorOS calibration build `PHY110_16.0.10.500(CN01)`
- Vendor / VNDK ABI baseline: API 34

This tree intentionally does **not** embed a dated copy of Qualcomm/OPlus proprietary userspace or kernel modules. In Recovery it mounts the installed stock `vendor`, `odm`, `vendor_dlkm`, and `system_dlkm` partitions and uses their matching KeyMint/Gatekeeper/QSEE/Weaver/Wi-Fi components. That keeps the vendor ABI and KO/KMI pairing aligned with the currently installed ColorOS build.

## Hardware facts baked into the tree

- `/metadata`: F2FS
- `super`: `17716740096` bytes
- dynamic group: `super - 4194304` = `17712545792` bytes
- `recovery`: `104857600` bytes
- touch: Synaptics TCM (`oplus_bsp_synaptics_tcm2.ko`)
- Wi-Fi: Qualcomm Kiwi v2 (`qca_cld3_kiwi_v2.ko`)
- ADSP: boot first, then SSR (required for stable OTG on this target)

## Build

The repository workflow builds against pinned upstream anchor commits and records a revision-locked manifest for every run. Local build outline:

```sh
repo init --depth=1 -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0
repo sync -c -j$(nproc)
git -C bootable/recovery checkout 640eae012e65e9058baf8a8480ea5f0e4850fd3c
git clone https://github.com/Ayc-Gh/OPPO-Find-X7-Ultra-Twrp.git device/oppo/phy110
source build/envsetup.sh
lunch twrp_phy110 bp2a eng
m recoveryimage
```

## Validation status

Host-side static and module-loader tests live under `tests/`. A CI build additionally validates image size and ramdisk content. Final boot, FBE credential decryption, touch, MTP, fastbootd, Wi-Fi association, OTG hotplug and backup/restore still require real-device Recovery testing.
