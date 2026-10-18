TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LarrkMod

LarrkMod_FILES = src/fishhook.c src/LarrkConfig.mm src/LarrkGestureOverlay.mm src/LarrkModViewController.mm src/LarrkHooks.mm
LarrkMod_CFLAGS = -fobjc-arc -Isrc
LarrkMod_FRAMEWORKS = UIKit Foundation QuartzCore CoreGraphics AudioToolbox Security

include $(THEOS_MAKE_PATH)/tweak.mk
