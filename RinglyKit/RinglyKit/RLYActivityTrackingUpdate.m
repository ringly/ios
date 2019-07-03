#import "RLYActivityTrackingUpdate.h"
#import "RLYActivityTrackingUpdate+Internal.h"
#import "RLYErrorFunctions.h"

@implementation RLYActivityTrackingUpdate

#pragma mark - Initialization
-(instancetype)initWithDate:(RLYActivityTrackingDate*)date
               walkingSteps:(RLYActivityTrackingSteps)walkingSteps
               runningSteps:(RLYActivityTrackingSteps)runningSteps
{
    self = [super init];

    if (self)
    {
        _date = date;
        _walkingSteps = walkingSteps;
        _runningSteps = runningSteps;
    }

    return self;
}

#pragma mark - Steps
-(NSInteger)steps
{
    return (NSInteger)_walkingSteps + (NSInteger)_runningSteps;
}

#pragma mark - Equality and Hashing
-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RLYActivityTrackingUpdate class]])
    {
        RLYActivityTrackingUpdate *other = (RLYActivityTrackingUpdate*)object;
        return other.walkingSteps == _walkingSteps && other.runningSteps == _runningSteps && [other.date isEqual:_date];
    }
    else
    {
        return NO;
    }
}

-(NSUInteger)hash
{
    return _date.hash ^ (NSUInteger)_walkingSteps ^ ((NSUInteger)_runningSteps << sizeof(_walkingSteps));
}

#pragma mark - Description
-(NSString*)description
{
    return [NSString stringWithFormat:@"(date = %@, walking = %d, running = %d)", _date, _walkingSteps, _runningSteps];
}

#pragma mark - Parsing Data
+(void)parseActivityTrackingCharacteristicData:(NSData *)data
                            withUpdateCallback:(nonnull void (^)(RLYActivityTrackingUpdate * _Nonnull))updateCallback
                                 errorCallback:(nonnull void (^)(NSError * _Nonnull))errorCallback
                            completionCallback:(nonnull void (^)())completionCallback
{
    // if the data is empty, this indicates the termination of data updates
    if (data.length == 0)
    {
        completionCallback();
        return;
    }

    // the data size must be a multiple of 5
    size_t const packetSize = 5;

    if (data.length % packetSize != 0)
    {
        errorCallback(RLYActivityTrackingUpdateError(RLYActivityTrackingUpdateErrorCodeIncorrectDataLength, @{
            RLYActivityTrackingUpdateInvalidDataErrorKey: data
        }));

        return;
    }

    // parse data packets
    size_t dataCount = data.length / packetSize;
    uint8_t *bytes = (uint8_t*)data.bytes;

    for (size_t i = 0; i < dataCount; i++)
    {
        size_t offset = i * packetSize;
        NSError *error = nil;
        RLYActivityTrackingUpdate *activityTrackingUpdate = [self updateAtOffset:offset ofBytes:bytes withError:&error];

        if (activityTrackingUpdate)
        {
            updateCallback(activityTrackingUpdate);
        }
        else if (error)
        {
            errorCallback(error);
        }
    }
}

+(RLYActivityTrackingUpdate*)updateAtOffset:(size_t)offset
                                    ofBytes:(uint8_t *)bytes
                                  withError:(NSError * _Nullable __autoreleasing *)error
{
    // determine the date associated with this data
    RLYActivityTrackingMinute interval = [self intervalAtOffset:offset ofBytes:bytes];

    // bail out early if the interval is 0, these are used for reset records
    if (interval == 0)
    {
        return nil;
    }

    NSError *dateError = nil;
    RLYActivityTrackingDate *date = [RLYActivityTrackingDate dateWithMinute:interval error:&dateError];

    // if the date operation wasn't out-of-bounds, create a data value
    if (date)
    {
        return [[RLYActivityTrackingUpdate alloc] initWithDate:date
                                                  walkingSteps:bytes[offset + 3]
                                                  runningSteps:bytes[offset + 4]];
    }
    else
    {
        if (error)
        {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
            userInfo[RLYActivityTrackingUpdateInvalidDataErrorKey] = [NSData dataWithBytes:bytes + offset length:5];

            if (dateError)
            {
                userInfo[NSUnderlyingErrorKey] = dateError;
            }

            *error = RLYActivityTrackingUpdateError(RLYActivityTrackingUpdateErrorCodeDateError, userInfo);
        }

        return nil;
    }
}

+(RLYActivityTrackingMinute)intervalAtOffset:(size_t)offset ofBytes:(uint8_t*)bytes
{
    return RLYActivityTrackingMinuteBytesToMinute(
        RLYActivityTrackingMinuteBytesMake(bytes[offset], bytes[offset + 1], bytes[offset + 2] & 0b01111111)
    );
}

@end
