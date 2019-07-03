#import "RLYANCSV1Parser.h"
#import "RLYErrorFunctions.h"
#import "RLYFunctions.h"

@interface RLYANCSV1Parser ()
{
@private
    // date handling
    NSDate *_yearMonthDate;
    NSDateFormatter *_yearMonthFormatter;
    NSDateFormatter *_dateFormatter;
    
    // ANCS data
    NSArray<NSData*> *_appends;
}

@end

@implementation RLYANCSV1Parser

#pragma mark - Initialization
-(id)init
{
    return [self initWithYearMonthDate:nil];
}

-(instancetype)initWithYearMonthDate:(NSDate *)yearMonthDate
{
    self = [super init];
    
    if (self)
    {
        _yearMonthDate = yearMonthDate;
        
        _yearMonthFormatter = [NSDateFormatter new];
        _yearMonthFormatter.dateFormat = @"YYYYMM";
        
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"YYYYMMddHHmmss";
    }
    
    return self;
}

#pragma mark - ANCS Data
-(void)appendData:(NSData*)data
{
    // add the new data
    _appends = [_appends ?: @[] arrayByAddingObject:data];
    
    // check data headers
    if (_appends.count > 1)
    {
        // make sure we actually have a data header
        NSData *lastHeader = RLYScanANCSV1Header(_appends.lastObject);
        
        if (!lastHeader)
        {
            // send an error to the delegate
            NSError *error = RLYANCSV1Error(RLYANCSV1ErrorCodeInvalidHeader);
            [_delegate ANCSV1Parser:self failedToParseNotificationWithError:error];
            
            // restart the process on the next append
            _appends = @[];
            
            return;
        }
        
        // compare with the headers we're already tracking to make sure this is the same notification
        NSData *firstHeader = RLYScanANCSV1Header(_appends.firstObject);
        
        if (![firstHeader isEqualToData:lastHeader])
        {
            // send an error to the delegate
            NSError *error = RLYANCSV1Error(RLYANCSV1ErrorCodeDifferentHeader);
            [_delegate ANCSV1Parser:self failedToParseNotificationWithError:error];
            
            // restart the process, with the new notification as the first value
            _appends = @[data];
            
            return;
        }
    }
    
    // once we've collected 5 appends, parse them into a notification
    if (_appends.count == 5)
    {
        // convert from data to strings, dropping the initial header
        NSMutableArray<NSString*> *strings = [NSMutableArray arrayWithCapacity:5];
        NSMutableArray<NSData*> *subdatas = [NSMutableArray arrayWithCapacity:5];
        
        for (NSUInteger i = 0; i < 5; i++)
        {
            NSData *data = _appends[i];
            
            // find the header for the part
            NSData *header = RLYScanANCSV1Header(data);
            
            // take all data after the header as the message body
            NSData *subdata = [data subdataWithRange:NSMakeRange(header.length, data.length - header.length)];
            [subdatas addObject:subdata];
            
            // convert to a UTF-8 string
            [strings addObject:RLYFindValidUTF8Prefix(RLYSubdataToFirstNull(subdata))];
        }
        
        // parse ANCS date if available
        NSDate *date = nil;

        if (strings[4].length >= 8)
        {
            // trim excess length, where the flags are stored
            NSString *trimmed = [strings[4] substringToIndex:8];
            
            // add the year and month to the reported date
            NSString *yearMonth = [_yearMonthFormatter stringFromDate:_yearMonthDate ?: [NSDate date]];
            NSString *dateString = [yearMonth stringByAppendingString:trimmed];
            
            date = [_dateFormatter dateFromString:dateString];;
        }
        
        // include flags data if requested
        RLYANCSNotificationFlagsValue *flagsValue = nil;

        if (_includeFlags && subdatas[4].length > 8)
        {
            RLYANCSNotificationFlags flags = ((uint8_t*)subdatas[4].bytes)[8];
            flagsValue = [[RLYANCSNotificationFlagsValue alloc] initWithFlags:flags];
        }

        // create ANCS notification
        RLYANCSNotification *notification =
            [[RLYANCSNotification alloc] initWithVersion:RLYANCSNotificationVersion1
                                                category:RLYANCSCategoryFromNumericalString(strings[0])
                                   applicationIdentifier:[strings[1] stringByAppendingString:strings[2]]
                                                   title:strings[3]
                                                    date:date
                                                 message:strings[4]
                                              flagsValue:flagsValue];
        
        // send the notification to the delegate and clear for the next parse operation
        [_delegate ANCSV1Parser:self parsedNotification:notification];
        _appends = @[];
    }
}

@end
