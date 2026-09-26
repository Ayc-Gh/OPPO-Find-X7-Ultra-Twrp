# SPDX-License-Identifier: Apache-2.0
DEVICE_PATH := device/oppo/phy110

$(call inherit-product, $(DEVICE_PATH)/common/device-common.mk)

# Find X7 Ultra shipped on the Android 14 / API 34 vendor ABI baseline.
BOARD_SHIPPING_API_LEVEL := 34
PRODUCT_SHIPPING_API_LEVEL := 34
PRODUCT_TARGET_VNDK_VERSION := 34

PRODUCT_SOONG_NAMESPACES += $(DEVICE_PATH)
