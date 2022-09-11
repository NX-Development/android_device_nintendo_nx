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

ifeq ($(TARGET_PREBUILT_KERNEL),)
INSTALLED_KERNEL_TARGET := $(PRODUCT_OUT)/kernel
INSTALLED_RECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/recovery.img

INSTALLED_DTBIMAGE_TARGET := $(PRODUCT_OUT)/install/nx.dtb.img

$(INSTALLED_DTBIMAGE_TARGET): $(INSTALLED_KERNEL_TARGET) | mkdtimg
	echo -e ${CL_GRN}"Building nx DTImage"${CL_RST}
	@mkdir -p $(PRODUCT_OUT)/install
	$(HOST_OUT_EXECUTABLES)/mkdtimg create $@ --id=7888 --page_size=0x1000 \
		$(KERNEL_OUT)/arch/arm64/boot/dts/$(DTB_SUBFOLDER)/tegra210-icosa.dtb --custom0=0x0

ALL_DEFAULT_INSTALLED_MODULES += $(INSTALLED_DTBIMAGE_TARGET)
endif
