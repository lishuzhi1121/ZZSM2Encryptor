//
//  ZZSM3Digest.h
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// SM3算法产生的哈希值大小（单位：字节）
extern int ZZSM3_HASH_SIZE;

@interface ZZSM3Digest : NSObject

/// 派生密钥
/// @param z 私钥数据
/// @param keylen 密钥长度
+ (NSData *)KDF:(NSData *)z keylen:(int)keylen;

/// SM3密码杂凑算法（哈希）
/// @param message 待哈希的字符串
+ (NSData *)hash:(NSString *)message;

/// SM3密码杂凑算法（哈希）
/// @param data 待哈希的二进制data
+ (NSData *)hashData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
