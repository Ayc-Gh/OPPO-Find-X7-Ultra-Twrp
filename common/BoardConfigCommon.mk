# SPDX-License-Identifier: Apache-2.0

# Architecture / platform
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo300

PRODUCT_PLATFORM := pineapple
TARGET_BOOTLOADER_BOARD_NAME := pineapple
TARGET_BOARD_PLATFORM := sm86xx
TARGET_BOARD_PLATFORM_GPU := qcom-adreno735
QCOM_BOARD_PLATFORMS += sm86xx

# A/B and dynamic partitions
AB_OTA_PARTITIONS := \
    boot \
    init_boot \
    vendor_boot \
    recovery \
    dtbo \
    odm \
    product \
    system \
    system_ext \
    system_dlkm \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_dlkm

AB_OTA_PARTITIONS += \
    my_bigball \
    my_carrier \
    my_company \
    my_engineering \
    my_heytap \
    my_manifest \
    my_preload \
    my_product \
    my_region \
    my_stock

BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    system system_dlkm system_ext product vendor vendor_dlkm odm
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST += \
    my_bigball my_carrier my_company my_engineering my_heytap \
    my_manifest my_preload my_product my_region my_stock

# Boot / recovery image
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_RAMDISK_USE_LZ4 := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

# Crypto / storage
BOARD_USES_METADATA_PARTITION := true
TARGET_USERIMAGES_USE_F2FS := true
TW_INCLUDE_CRYPTO := true
TW_USE_DMCTL := true

# Fastboot / AVB
BOARD_AVB_ENABLE := true
TW_INCLUDE_FASTBOOTD := true

# Recovery tooling
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true
TW_ENABLE_ALL_PARTITION_TOOLS := true
TW_INCLUDE_7ZA := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_RESETPROP := true
TW_INCLUDE_ZSTD := true
TW_USE_TOOLBOX := true

# Filesystems
RECOVERY_SDCARD_ON_DATA := true
TARGET_USES_MKE2FS := true
TW_ENABLE_FS_COMPRESSION := true
TW_INCLUDE_FUSE_EXFAT := true
TW_INCLUDE_FUSE_NTFS := true
TW_INCLUDE_NTFS_3G := true

# TWRP UI
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_USE_SERIALNO_PROPERTY_FOR_DEVICE_ID := true

# Let this tree own USB gadget setup.
TW_EXCLUDE_DEFAULT_USB_INIT := true
