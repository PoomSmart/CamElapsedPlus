GO_EASY_ON_ME = 1
TARGET = iphone:9.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk

TWEAK_NAME = MoreAccurateVideoTime
MoreAccurateVideoTime_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp -R MAVTPS $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/MAVTPS$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)
