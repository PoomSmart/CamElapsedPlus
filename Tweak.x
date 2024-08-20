#import <PSHeader/CameraApp/CAMElapsedTimeView.h>
#import <PSHeader/CameraMacros.h>
#import <PSHeader/Misc.h>

int string;

%hook CAMElapsedTimeView

- (void)_updateText {
    if (string <= 1) {
        %orig;
        return;
    }
    NSDate *startDate = [self valueForKey:@"__startTime"];
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
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0.0];
    NSString *timeString = [dateFormatter stringFromDate:timerDate];
    [self _timeLabel].text = timeString;
}

- (void)startTimer {
    if (string <= 1) {
        %orig;
        return;
    }
    NSTimer *updateTimer = [self valueForKey:@"__updateTimer"];
    [updateTimer invalidate];
    NSDate *startTime = [[NSDate alloc] init];
    [self setValue:startTime forKey:@"__startTime"];
    NSTimeInterval interval = (NSTimeInterval)pow(10, -string);
    NSTimer *newUpdateTimer = [[NSTimer alloc] initWithFireDate:startTime interval:interval target:self selector:@selector(_updateForTimer:) userInfo:nil repeats:YES];
    [self setValue:newUpdateTimer  forKey:@"__updateTimer"];
    [[NSRunLoop currentRunLoop] addTimer:newUpdateTimer forMode:(NSRunLoopMode)kCFRunLoopDefaultMode];
    [[NSRunLoop currentRunLoop] addTimer:newUpdateTimer forMode:UITrackingRunLoopMode];
}

%end

%ctor {
    string = [[NSUserDefaults standardUserDefaults] integerForKey:@"MAVT_FormatType"];
    openCamera10();
    %init;
}
