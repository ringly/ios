#import "RLYActivityTrackingDate.h"
#import "RLYDefines+Internal.h"
#import "RLYErrorFunctions.h"

#define SET_ERROR_AND_RETURN_NIL(ERROR_CODE, USER_INFO) \
    RLY_SET_ERROR_AND_RETURN(RLYActivityTrackingDateError(ERROR_CODE, USER_INFO), nil)

@implementation RLYActivityTrackingDate

#pragma mark - Initialization
-(instancetype)initWithMinute:(RLYActivityTrackingMinute)minute
{
    self = [super init];

    if (self)
    {
        _minute = minute;
    }

    return self;
}

+(nullable instancetype)dateWithMinute:(RLYActivityTrackingMinute)minute error:(NSError**)error
{
    if (minute > RLYActivityTrackingMinuteMax)
    {
        SET_ERROR_AND_RETURN_NIL(RLYActivityTrackingDateErrorCodeIntervalGreaterThanMaximum, @{
            RLYActivityTrackingDateInvalidIntervalKey: @(minute)
        });
    }
    else if (minute < RLYActivityTrackingMinuteMin)
    {
        SET_ERROR_AND_RETURN_NIL(RLYActivityTrackingDateErrorCodeIntervalLessThanMinimum, @{
            RLYActivityTrackingDateInvalidIntervalKey: @(minute)
        });
    }
    else
    {
        return [[RLYActivityTrackingDate alloc] initWithMinute:minute];
    }
}

+(nullable instancetype)dateWithTimestamp:(time_t)timestamp error:(NSError**)error
{
    // convert to a timestamp
    if (timestamp >= RLYActivityTrackingDateReferenceTimestamp)
    {
        time_t relative = timestamp - RLYActivityTrackingDateReferenceTimestamp;
        time_t minutes = relative / 60;

        return [self dateWithMinute:(RLYActivityTrackingMinute)minutes error:error];
    }
    else
    {
        SET_ERROR_AND_RETURN_NIL(RLYActivityTrackingDateErrorCodeIntervalLessThanMinimum, @{
            RLYActivityTrackingDateInvalidTimestampKey: @(timestamp)
        });
    }
}

+(nullable instancetype)dateWithDate:(NSDate *)date error:(NSError**)error
{
    return [self dateWithTimestamp:(time_t)date.timeIntervalSince1970 error:error];
}

#pragma mark - Boundary Dates
+(instancetype)minimumDate
{
    return [self dateWithMinute:RLYActivityTrackingMinuteMin error:nil];
}

+(instancetype)maximumDate
{
    return [self dateWithMinute:RLYActivityTrackingMinuteMax error:nil];
}

#pragma mark - Representations
-(NSDate*)date
{
    return RLYActivityTrackingMinuteToNSDate(_minute);
}

-(time_t)timestamp
{
    return RLYActivityTrackingMinuteToTimestamp(_minute);
}

#pragma mark - Equality and Hashing
-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RLYActivityTrackingDate class]])
    {
        return [(RLYActivityTrackingDate*)object minute] == _minute;
    }
    else
    {
        return NO;
    }
}

-(NSUInteger)hash
{
    return _minute;
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"%d", _minute];
}

@end

#pragma mark - Intervals
RLYActivityTrackingMinute const RLYActivityTrackingMinuteMin = 1;
RLYActivityTrackingMinute const RLYActivityTrackingMinuteMax = 8388607;

time_t RLYActivityTrackingMinuteToTimestamp(RLYActivityTrackingMinute interval)
{
    return (time_t)interval * 60 + RLYActivityTrackingDateReferenceTimestamp;
}

NSDate *RLYActivityTrackingMinuteToNSDate(RLYActivityTrackingMinute interval)
{
    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)RLYActivityTrackingMinuteToTimestamp(interval)];
}

RLYActivityTrackingMinuteBytes
    RLYActivityTrackingMinuteBytesMake(uint8_t first, uint8_t second, uint8_t third)
{
    RLYActivityTrackingMinuteBytes bytes = { .first = first, .second = second, .third = third };
    return bytes;
}

RLYActivityTrackingMinuteBytes
    RLYActivityTrackingMinuteBytesFromMinute(RLYActivityTrackingMinute interval)
{
    RLYActivityTrackingMinuteBytes bytes = {
        .first = (uint8_t)interval,
        .second = (uint8_t)(interval >> 8),
        .third = (uint8_t)(interval >> 16)
    };

    return bytes;
}

RLYActivityTrackingMinute
    RLYActivityTrackingMinuteBytesToMinute(RLYActivityTrackingMinuteBytes bytes)
{
    return (RLYActivityTrackingMinute)bytes.first
         | ((RLYActivityTrackingMinute)bytes.second << 8)
         | ((RLYActivityTrackingMinute)bytes.third << 16);
}

#pragma mark - Timestamps
time_t const RLYActivityTrackingDateReferenceTimestamp = 1459972800;
