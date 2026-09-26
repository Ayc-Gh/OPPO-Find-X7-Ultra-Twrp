# SPDX-License-Identifier: Apache-2.0
DEVICE_PATH := device/oppo/phy110

# Keep only the compatibility escape hatch currently required by the TWRP 16
# minimal manifest. Do not restore the older global BUILD_BROKEN workarounds.
ALLOW_MISSING_DEPENDENCIES := true

include $(DEVICE_PATH)/common/BoardConfigCommon.mk

# PHY110 hardware facts captured from PHY110_16.0.10.500(CN01), 2026-09-26.
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 104857600
BOARD_SUPER_PARTITION_SIZE := 17716740096
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := $(shell echo $$(($(BOARD_SUPER_PARTITION_SIZE) - 4194304)))

TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop

# Recovery-specific init property hook.
TARGET_INIT_VENDOR_LIB := //$(DEVICE_PATH):libinit_phy110
TARGET_RECOVERY_DEVICE_MODULES += libinit_phy110

# PHY110 display. Recovery intentionally uses 60 Hz for lower power/heat.
TW_BRIGHTNESS_PATH := /sys/class/backlight/panel0-backlight/brightness
TW_DEFAULT_BRIGHTNESS := 2048
TW_MAX_BRIGHTNESS := 4095
TW_FRAMERATE := 60
TW_SCREEN_BLANK_ON_BOOT := true

# Build-time placeholders are replaced at runtime with the SPL read from the
# mounted stock system/vendor partitions before crypto services are started.
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

TW_DEVICE_VERSION := OPPO-Find-X7-Ultra-PHY110
TARGET_RECOVERY_QCOM_RTC_FIX := true
