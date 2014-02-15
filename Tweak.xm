#import <substrate.h>

#define isiOS7 (kCFCoreFoundationVersionNumber >= 800.00)
#define PREF_PATH @"/var/mobile/Library/Preferences/com.PS.MoreAccurateVideoTime.plist"
#define PreferencesChangedNotification "com.PS.MoreAccurateVideoTime.prefs"

static int string = 1;

@interface CAMElapsedTimeView
@property(readonly, assign, nonatomic) NSDate* _startTime;
@property(readonly, assign, nonatomic) NSTimer* _updateTimer;
@property(readonly, assign, nonatomic) UIImageView* _recordingImageView;
@property(readonly, assign, nonatomic) UILabel* _timeLabel;
- (void)resetTimer;
- (void)endTimer;
- (void)_endRecordingAnimation;
- (void)_beginRecordingAnimation;
- (void)_commonCAMElapsedTimeViewInitialization;
- (void)_update:(NSTimer *)update;
- (void)startTimer;
- (CGSize)sizeThatFits:(CGSize)fits;
- (void)layoutSubviews;
- (id)initWithCoder:(id)coder;
- (void)dealloc;
- (id)initWithFrame:(CGRect)frame;
@end

@interface PLCameraView : UIView
@property(readonly, assign, nonatomic) CAMElapsedTimeView* _elapsedTimeView;
@end

NSMutableArray *array = [NSMutableArray array];

%hook CAMElapsedTimeView

- (void)_update:(NSTimer *)update
{
	if (string <= 1) {
		%orig;
		return;
	}
	NSDate *startDate = MSHookIvar<NSDate *>(self, "__startTime");
	UILabel *timeLabel = MSHookIvar<UILabel*>(self, "__timeLabel");
	
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
	[dateFormatter setDateFormat:format];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
	
	NSString *timeString = [dateFormatter stringFromDate:timerDate];
	[timeLabel setText:timeString];
	
	[dateFormatter release];
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
	
	MSHookIvar<NSDate *>(self, "__startTime") = [[NSDate alloc] init];
	[updateTimer invalidate];
	float interval = pow(10, -string);
	NSTimer *timer= [[NSTimer alloc] initWithFireDate:MSHookIvar<NSDate *>(self, "__startTime") interval:interval target:self selector:@selector(_update:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[self _beginRecordingAnimation];
}

%end

static void MAVT()
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	string = [[dict objectForKey:@"string"] intValue];
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	system("killall Camera");
	MAVT();
}

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
	MAVT();
	%init;
	[pool drain];
}
