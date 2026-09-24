ARCHS = arm64
INSTALL_TARGET_PROCESSES = YouTubeMusic
TARGET = iphone:clang:16.5:13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = YTMGlass
$(TWEAK_NAME)_FILES = $(shell find Sources \( -name '*.x' -o -name '*.xm' -o -name '*.m' \))
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation
$(TWEAK_NAME)_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk
