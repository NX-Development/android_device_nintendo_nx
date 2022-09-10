# Copyright (C) 2022 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := $(call my-dir)

NX_VENDOR_PATH := ../../../../../vendor/nintendo

ATF_PATH   := $(BUILD_TOP)/external/switch-atf
COREBOOT_PATH := $(BUILD_TOP)/external/switch-coreboot

LINEAGE_TOOLS_PATH       := $(BUILD_TOP)/prebuilts/tools-lineage/$(HOST_PREBUILT_TAG)/bin
TARGET_KERNEL_CLANG_PATH ?= $(BUILD_TOP)/prebuilts/clang/host/$(HOST_PREBUILT_TAG)/$(LLVM_PREBUILTS_VERSION)
TARGET_SC7_GCC_PATH      ?= $(BUILD_TOP)/prebuilts/gcc/$(HOST_PREBUILT_TAG)/arm/arm-linux-androideabi-4.9

include $(CLEAR_VARS)
LOCAL_MODULE               := reboot_payload
LOCAL_SRC_FILES            := $(NX_VENDOR_PATH)/bootloader/hekate.bin
LOCAL_MODULE_SUFFIX        := .bin
LOCAL_MODULE_CLASS         := ETC
LOCAL_MODULE_PATH          := $(TARGET_OUT_VENDOR)/firmware/
LOCAL_MODULE_TAGS          := optional
LOCAL_MODULE_OWNER         := nvidia
include $(BUILD_NVIDIA_PREBUILT)

# ATF
include $(CLEAR_VARS)
LOCAL_MODULE        := bl31
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS  := EXECUTABLES
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_atf_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_atf_bin := $(_atf_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_atf_bin):
	@mkdir -p $(dir $@)
	$(hide) +$(KERNEL_MAKE_CMD) $(KERNEL_CROSS_COMPILE) TZDRAM_BASE=0xFFB00000 RESET_TO_BL31=1 \
		PROGRAMMABLE_RESET_ADDRESS=1 COLD_BOOT_SINGLE_CPU=1 CLANG_CCDIR=$(TARGET_KERNEL_CLANG_PATH)/bin/ \
		CC=$(TARGET_KERNEL_CLANG_PATH)/bin/clang -C $(ATF_PATH) BUILD_BASE=$(abspath $(_atf_intermediates)) \
		PLAT=tegra TARGET_SOC=t210 bl31
	@cp $(dir $@)/tegra/t210/release/bl31.bin $@

include $(BUILD_SYSTEM)/base_rules.mk
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/bl31.bin

# SC7
include $(CLEAR_VARS)
LOCAL_MODULE        := tegra_rebootstub
LOCAL_MODULE_SUFFIX := .fw
LOCAL_MODULE_CLASS  := EXECUTABLES
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_sc7_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_sc7_bin := $(_sc7_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_sc7_bin):
	@mkdir -p $(dir $@)
	@mkdir -p $(PRODUCT_OUT)/sc7/
	$(hide) +$(KERNEL_MAKE_CMD) $(KERNEL_CROSS_COMPILE) GCC_PREFIX="$(TARGET_SC7_GCC_PATH)/bin/arm-linux-androideabi-" CCFLAGS="-std=c99" -C $(COREBOOT_PATH)/src/soc/nvidia/tegra210/lp0/rebootstub/
	@cp $(COREBOOT_PATH)/src/soc/nvidia/tegra210/lp0/rebootstub/tegra_rebootstub.fw $(dir $@)

include $(BUILD_SYSTEM)/base_rules.mk
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/tegra_rebootstub.fw

include $(CLEAR_VARS)
LOCAL_MODULE        := tegra_sc7_entry
LOCAL_MODULE_SUFFIX := .fw
LOCAL_MODULE_CLASS  := EXECUTABLES
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_sc7_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_sc7_bin := $(_sc7_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_sc7_bin):
	@mkdir -p $(dir $@)
	@mkdir -p $(PRODUCT_OUT)/sc7/
	$(hide) +$(KERNEL_MAKE_CMD) $(KERNEL_CROSS_COMPILE) GCC_PREFIX="$(TARGET_SC7_GCC_PATH)/bin/arm-linux-androideabi-" CCFLAGS="-std=c99" -C $(COREBOOT_PATH)/src/soc/nvidia/tegra210/lp0/sc7_entry/
	@cp $(COREBOOT_PATH)/src/soc/nvidia/tegra210/lp0/sc7_entry/tegra_sc7_entry.fw $(dir $@)

include $(BUILD_SYSTEM)/base_rules.mk
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/tegra_sc7_entry.fw

include $(CLEAR_VARS)
LOCAL_MODULE        := tegra_sc7_exit
LOCAL_MODULE_SUFFIX := .fw
LOCAL_MODULE_CLASS  := EXECUTABLES
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_sc7_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_sc7_bin := $(_sc7_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_sc7_bin):
	@mkdir -p $(dir $@)
	@mkdir -p $(PRODUCT_OUT)/sc7/
	$(hide) +$(KERNEL_MAKE_CMD) $(KERNEL_CROSS_COMPILE) GCC_PREFIX="$(TARGET_SC7_GCC_PATH)/bin/arm-linux-androideabi-" CCFLAGS="-std=c99" -C $(COREBOOT_PATH)/src/soc/nvidia/tegra210/lp0/sc7_exit/
	@cp $(COREBOOT_PATH)/src/soc/nvidia/tegra210/lp0/sc7_exit/tegra_sc7_exit.fw $(dir $@)

include $(BUILD_SYSTEM)/base_rules.mk
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/tegra_sc7_exit.fw

# U-Boot
include $(CLEAR_VARS)
LOCAL_MODULE        := u-boot
LOCAL_SRC_FILES     := $(NX_VENDOR_PATH)/bootfiles/u-boot.bin
LOCAL_MODULE_SUFFIX := .bin
LOCAL_MODULE_CLASS  := EXECUTABLES
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)
include $(BUILD_PREBUILT)
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/u-boot.bin

# Uscript
include $(CLEAR_VARS)
LOCAL_MODULE        := boot.scr
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)

_uscript_input := $(abspath vendor/nintendo/bootfiles/android_boot.txt)
_uscript_intermediates := $(call intermediates-dir-for,$(LOCAL_MODULE_CLASS),$(LOCAL_MODULE))
_uscript_archive := $(_uscript_intermediates)/$(LOCAL_MODULE)$(LOCAL_MODULE_SUFFIX)

$(_uscript_archive):
	@mkdir -p $(dir $@)
	$(LINEAGE_TOOLS_PATH)/mkimage -A arm -T script -O linux -d $(_uscript_input) $(_uscript_intermediates)/boot.scr

include $(BUILD_SYSTEM)/base_rules.mk
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/boot.scr

# Config
include $(CLEAR_VARS)
LOCAL_MODULE        := 00-android
LOCAL_MODULE_SUFFIX := .ini
LOCAL_SRC_FILES     := $(NX_VENDOR_PATH)/config/00-android.ini
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)
include $(BUILD_PREBUILT)
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/00-android.ini

include $(CLEAR_VARS)
LOCAL_MODULE        := bootlogo_android
LOCAL_MODULE_SUFFIX := .bmp
LOCAL_SRC_FILES     := $(NX_VENDOR_PATH)/config/bootlogo_android.bmp
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)
include $(BUILD_PREBUILT)
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/bootlogo_android.bmp

include $(CLEAR_VARS)
LOCAL_MODULE        := icon_android_hue
LOCAL_MODULE_SUFFIX := .bmp
LOCAL_SRC_FILES     := $(NX_VENDOR_PATH)/config/icon_android_hue.bmp
LOCAL_MODULE_CLASS  := ETC
LOCAL_MODULE_PATH   := $(PRODUCT_OUT)
include $(BUILD_PREBUILT)
INSTALLED_RADIOIMAGE_TARGET += $(PRODUCT_OUT)/icon_android_hue.bmp
