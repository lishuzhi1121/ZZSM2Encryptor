//
//  ZZSM2Util.m
//  ZZSM2Encryptor
//
//  Created by SandsLee on 2021/6/28.
//

#import "ZZSM2Util.h"

@implementation ZZSM2Util

+ (NSData *)dataByHexString:(NSString *)hexString {
    if (![hexString isKindOfClass:[NSString class]] || hexString.length == 0) {
        return nil;
    }
    
    char byte = 0;
    NSString *upperString = hexString.uppercaseString;
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i < upperString.length; i++) {
        NSInteger value = (NSInteger)[upperString characterAtIndex:i];
        if (value >= '0' && value <= '9') {
            if (i % 2 == 0) {
                byte = ((value - '0') << 4) & 0xf0;
                if (i == upperString.length - 1) {
                    [data appendBytes:(const void *)&byte length:1];
                }
            } else {
                byte |= (value - '0') & 0x0f;
                [data appendBytes:(const void *)&byte length:1];
            }
        } else if (value >= 'A' && value <= 'F') {
            if (i % 2 == 0) {
                byte = ((value - 'A' + 10) << 4) & 0xf0;
                if (i == upperString.length - 1) {
                    [data appendBytes:(const void *)&byte length:1];
                }
            } else {
                byte |= (value - 'A' + 10) & 0x0f;
                [data appendBytes:(const void *)&byte length:1];
            }
        } else {
            data = nil;
            break;
        }
    }
    
    return [data copy];
}

+ (NSString *)hexStringByData:(NSData *)data {
    if (![data isKindOfClass:[NSData class]]) {
        return nil;
    }
    
    NSMutableString *hexString = [NSMutableString string];
    const char *buff = [data bytes];
    for (int i = 0; i < [data length]; i++) {
        [hexString appendFormat:@"%02X", (buff[i] & 0xff)];
    }
    
    return [hexString copy];
}

+ (NSString *)stringByBase64EncodeData:(NSData *)data {
    if (![data isKindOfClass:[NSData class]]) {
        return nil;
    }
    
    return [data base64EncodedStringWithOptions:0];
}

+ (NSData *)dataByBase64DecodeString:(NSString *)string {
    if (![string isKindOfClass:[NSString class]] || string.length == 0) {
        return nil;
    }
    
    return [[NSData alloc] initWithBase64EncodedString:string
                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

+ (NSString *)stringByBase64DecodeString:(NSString *)string {
    NSData *data = [self dataByBase64DecodeString:string];
    if ([data isKindOfClass:[NSData class]] && data.length > 0) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

+ (NSString *)leftPad:(NSString *)input num:(NSUInteger)num {
    if (![input isKindOfClass:[NSString class]] || input.length == 0) {
        return nil;
    }
    @autoreleasepool {
        if (input.length >= num) {
            return input;
        }
        
        NSMutableString *s = [NSMutableString string];
        NSUInteger len = num - input.length;
        for (int i = 0; i < len; i++) {
            if (i+4 < len) {
                [s appendFormat:@"0000"];
                i += 4;
                continue;
            } else if (i+3 < len) {
                [s appendFormat:@"000"];
                i += 3;
                continue;
            } else if (i+2 < len) {
                [s appendFormat:@"00"];
                i += 2;
                continue;
            } else {
                [s appendFormat:@"0"];
                i += 1;
                continue;
            }
        }
        
        return [s stringByAppendingString:input];
    }
}


@end
