#import "../PS.h"

NSString *PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.MoreAccurateVideoTime.plist";
CFStringRef PreferencesChangedNotification = CFSTR("com.PS.MoreAccurateVideoTime.prefs");

static int string;

%hook ElapsedTimeView

- (void)_update:(NSTimer *)update
{
	if (string <= 1) {
		%orig;
		return;
	}
	NSDate *startDate = MSHookIvar<NSDate *>(self, "__startTime");
	NSDate *currentDate = [NSDate date];
	NSTimeInterval interval = [currentDate timeIntervalSinceDate:startDate];
	NSDate *timerDate = [NSDate dateWithTimeIntervalSince1970:interval];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	NSString *format;
	switch (string) {
		case 2:
			format = @"HH:mm:ss.S";
			break;
		case 3:
			format = @"HH:mm:ss.SS";
			break;
		case 4:
			format = @"HH:mm:ss.SSS";
			break;
		default:
			format = @"HH:mm:ss";
			break;
	}
	dateFormatter.dateFormat = format;
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
	NSString *timeString = [dateFormatter stringFromDate:timerDate];
	[self _timeLabel].text = timeString;
	[dateFormatter release];
	//[self setNeedsLayout];
}

- (void)startTimer
{
	if (string <= 1) {
		%orig;
		return;
	}
	[MSHookIvar<NSDate *>(self, "__startTime") release];
	NSTimer *updateTimer = MSHookIvar<NSTimer *>(self, "__updateTimer");
	[updateTimer invalidate];
	[self _update:nil];
	
	MSHookIvar<NSDate *>(self, "__startTime") = [[NSDate alloc] init];
	[updateTimer invalidate];
	NSTimeInterval interval = (NSTimeInterval)pow(10, -string);
	[MSHookIvar<NSTimer *>(self, "__updateTimer") release];
	MSHookIvar<NSTimer *>(self, "__updateTimer") = [[NSTimer alloc] initWithFireDate:MSHookIvar<NSDate *>(self, "__startTime") interval:interval target:self selector:@selector(_update:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:MSHookIvar<NSTimer *>(self, "__updateTimer") forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:MSHookIvar<NSTimer *>(self, "__updateTimer") forMode:UITrackingRunLoopMode];
	[self _beginRecordingAnimation];
}

%end

static void MAVT()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	string = [dict[@"string"] intValue];
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	MAVT();
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, PreferencesChangedNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	MAVT();
	dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
	dlopen("/System/Library/PrivateFrameworks/CameraKit.framework/CameraKit", RTLD_LAZY);
	%init(ElapsedTimeView = isiOS9Up ? objc_getClass("CMKElapsedTimeView") : objc_getClass("CAMElapsedTimeView"));
	[pool drain];
}
