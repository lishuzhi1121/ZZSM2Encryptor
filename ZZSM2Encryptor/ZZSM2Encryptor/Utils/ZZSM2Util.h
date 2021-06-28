//
//  ZZSM2Util.h
//  ZZSM2Encryptor
//
//  Created by SandsLee on 2021/6/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZZSM2Util : NSObject

/// 转换16进制字符串为NSData
/// @param hexString 16进制字符串
+ (NSData *)dataByHexString:(NSString *)hexString;

/// 转换NSData为16进制字符串
/// @param data 二进制data
+ (NSString *)hexStringByData:(NSData *)data;

/// Base64编码
/// @param data 待编码的原始数据
+ (NSString *)stringByBase64EncodeData:(NSData *)data;

/// Base64解码
/// @param string Base64编码的字符串
+ (NSData *)dataByBase64DecodeString:(NSString *)string;

/// Base64解码
/// @param string Base64编码的字符串
+ (NSString *)stringByBase64DecodeString:(NSString *)string;

/// 16进制字符串根据长度补齐, 不够左边0补齐
/// @param input 待补齐的16进制字符串
/// @param num 目标总长度
+ (NSString *)leftPad:(NSString *)input num:(NSUInteger)num;

@end

NS_ASSUME_NONNULL_END
