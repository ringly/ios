#import "RLYANCSV2Parser.h"
#import "RLYDefines+Internal.h"
#import "RLYErrorFunctions.h"

typedef NS_ENUM(uint8_t, RLYANCSV2NotificationAttribute)
{
    RLYANCSV2NotificationAttributeApplicationIdentifier = 0,
    RLYANCSV2NotificationAttributeTitle = 1,
    RLYANCSV2NotificationAttributeSubtitle = 2,
    RLYANCSV2NotificationAttributeMessage = 3,
    RLYANCSV2NotificationAttributeMessageSize = 4,
    RLYANCSV2NotificationAttributeDate = 5,
    RLYANCSV2NotificationAttributePositiveAction = 6,
    RLYANCSV2NotificationAttributeNegativeAction = 7
};

typedef NS_ENUM(uint8_t, RLYANCSV2ApplicationAttribute)
{
    RLYANCSV2NotificationAttributeDisplayName = 0
};

@implementation RLYANCSV2Parser

#define ANCSV2_SET_ERROR_AND_RETURN_NIL(errorCode, data) \
    RLY_SET_ERROR_AND_RETURN(RLYANCSV2Error(errorCode, data), nil)

#pragma mark - Parsing
+(nullable NSDictionary<NSNumber*, NSString*>*)consumeAttributeDictionaryFromBytes:(const uint8_t*)bytes
                                                                            offset:(size_t*)offset
                                                                        dataLength:(size_t)dataLength
                                                                    attributeCount:(NSUInteger)count
                                                                      originalData:(NSData*)originalData
                                                                             error:(NSError**)error
{
    NSMutableDictionary<NSNumber*, NSString*> *attributes = [NSMutableDictionary dictionaryWithCapacity:count];
    
    for (NSUInteger i = 0; i < count; i++)
    {
        // read the attribute id
        if (dataLength <= *offset + 1)
        {
            ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeIncorrectDataSize, originalData);
        }
        
        uint8_t attributeIdentifier = bytes[*offset];
        *offset += 1;
        
        // read the attribute length
        if (dataLength <= *offset + 2)
        {
            ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeIncorrectDataSize, originalData);
        }
        
        uint16_t attributeLength = *(uint16_t*)(bytes + *offset);
        *offset += 2;
        
        // read the attribute
        if (dataLength <= *offset + attributeLength)
        {
            ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeIncorrectDataSize, originalData);
        }
        
        NSString *attributeValue = [[NSString alloc] initWithBytes:bytes + *offset
                                                            length:attributeLength
                                                          encoding:NSUTF8StringEncoding];
        *offset += attributeLength;
        
        // update dictionary
        attributes[@(attributeIdentifier)] = attributeValue;
    }
    
    return attributes;
}

+(nullable RLYANCSNotification*)parseData:(NSData*)data
      withNotificationAttributeCount:(const NSUInteger)notificationAttributeCount
           applicationAttributeCount:(const NSUInteger)applicationAttributeCount
                               error:(NSError**)error
{
    // case data's bytes to an 8-bit pointer type
    const uint8_t *bytes = (const uint8_t*)data.bytes;
    
    // check that there are *any* bytes
    size_t length = data.length;
    
    if (length == 0)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeIncorrectDataSize, data);
    }
    
    // check that the notification attributes command identifier is correct
    size_t offset = 0;
    
    if (bytes[offset] != 0)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeInvalidNotificationAttributesCommandIdentifier, data);
    }
    
    offset += 1;
    
    // read the notification uid
    if (length <= offset + 4)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeIncorrectDataSize, data);
    }
    
    __unused uint32_t notificationIdentifier = *(uint32_t*)(bytes + offset);
    offset += 4;
    
    // read the notification attributes
    NSDictionary<NSNumber*, NSString*> *notificationAttributes =
        [RLYANCSV2Parser consumeAttributeDictionaryFromBytes:bytes
                                                      offset:&offset
                                                  dataLength:length
                                              attributeCount:notificationAttributeCount
                                                originalData:data
                                                       error:error];
    
    if (!notificationAttributes)
    {
        return nil;
    }
    
    // check that the application attributes command identifier is correct
    if (length <= offset)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeIncorrectDataSize, data);
    }
    
    if (bytes[offset] != 1)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeInvalidApplicationAttributesCommandIdentifier, data);
    }
    
    offset++;
    
    // read the application identifier
    size_t applicationIdentifierLength = 0;
    
    while (bytes[offset + applicationIdentifierLength] != '\0' && offset + applicationIdentifierLength < length)
    {
        applicationIdentifierLength++;
    }
    
    if (length <= offset + applicationIdentifierLength)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeIncorrectDataSize, data);
    }
    
    NSString *applicationIdentifier = [[NSString alloc] initWithBytes:bytes + offset
                                                               length:applicationIdentifierLength
                                                             encoding:NSUTF8StringEncoding];
    
    offset += applicationIdentifierLength + 1;
    
    // read the application attributes
    NSDictionary<NSNumber*, NSString*> *applicationAttributes =
        [RLYANCSV2Parser consumeAttributeDictionaryFromBytes:bytes
                                                      offset:&offset
                                                  dataLength:length
                                              attributeCount:applicationAttributeCount
                                                originalData:data
                                                       error:error];
    
    if (!applicationAttributes)
    {
        return nil;
    }
    
    // unpack required notification attributes
    NSString *title = notificationAttributes[@(RLYANCSV2NotificationAttributeTitle)];
    
    if (!title)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeMissingTitle, data);
    }
    
    NSString *dateString = notificationAttributes[@(RLYANCSV2NotificationAttributeDate)];
    
    if (!dateString)
    {
        ANCSV2_SET_ERROR_AND_RETURN_NIL(RLYANCSV2ErrorCodeMissingDate, data);
    }
    
    // unpack nullable notification attribute message
    NSString *message = notificationAttributes[@(RLYANCSV2NotificationAttributeMessage)];
    
    // create ANCS notification
    return [[RLYANCSNotification alloc] initWithVersion:RLYANCSNotificationVersion2
                                               category:RLYANCSCategoryOther // TODO
                                  applicationIdentifier:applicationIdentifier
                                                  title:title
                                                   date:[[self ANCSV2DateFormatter] dateFromString:dateString]
                                                message:message
                                             flagsValue:nil];
}

#pragma mark - Date Formatter
+(NSDateFormatter*)ANCSV2DateFormatter
{
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.dateFormat = @"yyyyMMdd'T'HHmmSS";
    });
    
    return formatter;
}

@end
