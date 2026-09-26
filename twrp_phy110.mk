# SPDX-License-Identifier: Apache-2.0
DEVICE_PATH := device/oppo/phy110

$(call inherit-product, $(DEVICE_PATH)/device.mk)

PRODUCT_DEVICE := phy110
PRODUCT_NAME := twrp_phy110
PRODUCT_BRAND := OPPO
PRODUCT_MODEL := PHY110
PRODUCT_MANUFACTURER := OPPO

TW_STATUS_ICONS_ALIGN := center
TW_Y_OFFSET := 116
TW_H_OFFSET := -116
