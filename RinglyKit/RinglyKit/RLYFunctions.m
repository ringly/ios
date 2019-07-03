#import "RLYFunctions.h"
#import "RLYRecoveryPeripheral+Internal.h"

BOOL RLYAny(id<NSFastEnumeration> enumerable, BOOL(^block)(id object))
{
    for (id object in enumerable)
    {
        if (block(object)) return YES;
    }
    
    return NO;
}

id RLYFirstMatching(id<NSFastEnumeration> enumerable, BOOL(^block)(id object))
{
    for (id object in enumerable)
    {
        if (block && block(object))
        {
            return object;
        }
    }
    
    return nil;
}

NSDictionary *RLYMapToDictionary(NSArray *array, void(^block)(id object, id<NSCopying> *key, id *value))
{
    NSUInteger count = array.count;
    
    if (count > 0)
    {
        __autoreleasing id* keys = (__autoreleasing id*)calloc(count, sizeof(id));
        __autoreleasing id* objects = (__autoreleasing id*)calloc(count, sizeof(id));
        
        NSUInteger i = 0;
        for (id object in array)
        {
            block(object, keys + i, objects + i);
            i++;
        }
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys count:count];
        free(keys);
        free(objects);
        return dictionary;
    }
    else return @{};
}

#pragma mark - CBPeripheral
BOOL RLYCBPeripheralIsRingly(CBPeripheral *peripheral)
{
    NSString *name = peripheral.name;
    NSUUID *identifier = peripheral.identifier;
    
    return name && identifier && [name rangeOfString:@"Ringly" options:NSCaseInsensitiveSearch].location != NSNotFound;
}

BOOL RLYSupportsNotifyOrIndicate(CBCharacteristicProperties properties)
{
    return (properties & CBCharacteristicPropertyIndicate) != 0
        || (properties & CBCharacteristicPropertyNotify) != 0;
}

BOOL RLYRequiresEncryptionForNotifyOrIndicate(CBCharacteristicProperties properties)
{
    return (properties & CBCharacteristicPropertyIndicateEncryptionRequired) != 0
        || (properties & CBCharacteristicPropertyNotifyEncryptionRequired) != 0;
}

#pragma mark - String Data
NSString *RLYStringFittingInUTF8Bytes(NSString *string, size_t size)
{
    while ([string lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > size && string.length > 0)
    {
        NSRange range = [string rangeOfComposedCharacterSequenceAtIndex:string.length - 1];
        string = [string substringToIndex:range.location];
    }
    
    return string;
}

#pragma mark - Version Numbers
NSArray<NSString*> *RLYVersionNumberComponents(NSString *versionNumber)
{
    NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@".-+"];
    return [versionNumber componentsSeparatedByCharactersInSet:set];
}

NSComparisonResult RLYCompareVersionNumbers(NSString *first, NSString *second)
{
    NSArray *numbers1 = RLYVersionNumberComponents(first);
    NSArray *numbers2 = RLYVersionNumberComponents(second);
    
    NSUInteger count1 = numbers1.count, count2 = numbers2.count;
    
    for (NSUInteger i = 0; i < MIN(count1, count2); i++)
    {
        NSComparisonResult result = [numbers1[i] compare:numbers2[i] options:NSNumericSearch];
        
        if (result != NSOrderedSame)
        {
            return result;
        }
    }
    
    if (count1 == count2)
    {
        return NSOrderedSame;
    }
    else if (count1 < count2)
    {
        return NSOrderedAscending;
    }
    else
    {
        return NSOrderedDescending;
    }
}

#pragma mark - ANCS Version 1
NSData *RLYScanANCSV1Header(NSData *data)
{
    for (NSUInteger i = 0; i < data.length; i++)
    {
        if (((uint8_t*)data.bytes)[i] == ',')
        {
            return [data subdataWithRange:NSMakeRange(0, i + 1)];
        }
    }
    
    return nil;
}

#pragma mark - Data String Parsing
NSData *RLYSubdataToFirstNull(NSData *data)
{
    for (NSUInteger i = 0; i < data.length; i++)
    {
        if (((uint8_t*)data.bytes)[i] == '\0')
        {
            return [data subdataWithRange:NSMakeRange(0, i)];
        }
    }
    
    return data;
}

NSString *RLYFindValidUTF8Prefix(NSData *data)
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (string)
    {
        return string;
    }
    else
    {
        NSData *subdata = [data subdataWithRange:NSMakeRange(0, data.length - 1)];
        return RLYFindValidUTF8Prefix(subdata);
    }
}

NSString *RLYFindValidUTF8Suffix(NSData *data)
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (string)
    {
        return string;
    }
    else
    {
        NSData *subdata = [data subdataWithRange:NSMakeRange(1, data.length - 1)];
        return RLYFindValidUTF8Suffix(subdata);
    }
}

#pragma mark - Data
BOOL RLYAllBytesMatch(NSData *data, uint8_t value)
{
    NSUInteger length = data.length;
    uint8_t *bytes = (uint8_t*)data.bytes;
    
    for (NSUInteger i = 0; i < length; i++)
    {
        if (bytes[i] != value)
        {
            return NO;
        }
    }
    
    return YES;
}

NSData *RLYDataForReadingFlashLog(uint16_t length, uint32_t address)
{
    uint16_t lengthLittle = CFSwapInt16HostToLittle(length);
    uint32_t addressLittle = CFSwapInt32HostToLittle(address);

    uint8_t bytes[8] = {
        0,
        9,
        (uint8_t)lengthLittle,
        (uint8_t)(lengthLittle >> 8),
        (uint8_t)addressLittle,
        (uint8_t)(addressLittle >> 8),
        (uint8_t)(addressLittle >> 16),
        (uint8_t)(addressLittle >> 24)
    };

    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

#pragma mark - Messages
void RLYParseConfirmationMessage(NSData *message,
                                 void(^confirmed)(),
                                 void(^deleted)(),
                                 void(^cleared)())
{
    uint8_t *messageBytes = (uint8_t*)message.bytes;
    
    if (messageBytes[0] == 0xff && messageBytes[1] == '\0')
    {
        deleted();
    }
    else if (RLYAllBytesMatch(message, 0xff))
    {
        cleared();
    }
    else
    {
        confirmed();
    }
}

#pragma mark - Breakpoints
void RLYBreakpointIf(BOOL condition)
{
    if (condition)
    {
        RLYBreakpoint();
    }
}

void RLYBreakpoint(void) {}
