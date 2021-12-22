//
//  ZZSM4Encryptor.h
//  ZZSM2Encryptor
//
//  Created by SandsLee on 2021/12/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 定义SM4分组加密工作方式
/// https://zh.wikipedia.org/wiki/分组密码工作模式
typedef NS_ENUM(NSUInteger, ZZSM4CryptMode) {
    ZZSM4CryptModeECB = 0,
    ZZSM4CryptModeCBC
};

/// 定义SM4分组加密填充模式
/// SM4分组加密明文一组大小必须为16个字节, 当明文长度不足时需要填充至一组16字节
typedef NS_ENUM(NSUInteger, ZZSM4CryptPadding) {
    ZZSM4CryptPaddingNone = 0,          // 无填充
    ZZSM4CryptPaddingZero,              // 用0填充
    ZZSM4CryptPaddingPKCS5,             // 用"需要填充的长度"填充
    ZZSM4CryptPaddingPKCS7,             // 同上
    ZZSM4CryptPaddingISO10126,          // 最后一位用"需要填充的长度"填充, 其他随机
    ZZSM4CryptPaddingANSIX923,          // 最后一位用"需要填充的长度"填充, 其他为0
    ZZSM4CryptPadding0x80               // 第一位填充"0x80", 其他为0
};

@interface ZZSM4Encryptor : NSObject

/// SM4 字符串加密
/// @param plainText 明文字符串
/// @param keyString 密钥字符串(keyString不可为空, 且必须是16个字节长度)
/// @param mode 工作方式
/// @param padding 填充方式
/// @param ivString 填充向量（当mode ==  ZZSM4CryptModeCBC 时, iv不可为空, 且必须是16个字节长度）
+ (NSData *)sm4EncryptText:(NSString *)plainText
                 keyString:(NSString *)keyString
                 cryptMode:(ZZSM4CryptMode)mode
              cryptPadding:(ZZSM4CryptPadding)padding
                optionalIV:(NSString *)ivString;

/// SM4 字符串解密
/// @param hexCipherText 16进制密文字符串
/// @param keyString 密钥字符串(keyString不可为空, 且必须是16个字节长度)
/// @param mode 工作方式
/// @param padding 填充方式
/// @param ivString 填充向量（当mode ==  ZZSM4CryptModeCBC 时, iv不可为空, 且必须是16个字节长度）
+ (NSData *)sm4DecryptText:(NSString *)hexCipherText
                 keyString:(NSString *)keyString
                 cryptMode:(ZZSM4CryptMode)mode
              cryptPadding:(ZZSM4CryptPadding)padding
                optionalIV:(NSString *)ivString;


/// SM4 加密
/// @param plainData 明文数据
/// @param key 密钥数据(key不可为空, 且必须是16个字节长度)
/// @param mode 工作方式
/// @param padding 填充方式
/// @param iv 填充向量（当mode ==  ZZSM4CryptModeCBC 时, iv不可为空, 且必须是16个字节长度）
+ (NSData *)sm4Encrypt:(NSData *)plainData
                   key:(NSData *)key
             cryptMode:(ZZSM4CryptMode)mode
          cryptPadding:(ZZSM4CryptPadding)padding
            optionalIV:(NSData *)iv;

/// SM4 解密
/// @param cipherData 密文数据
/// @param key 密钥数据(key不可为空, 且必须是16个字节长度)
/// @param mode 工作方式
/// @param padding 填充方式
/// @param iv 填充向量（当mode ==  ZZSM4CryptModeCBC 时, iv不可为空, 且必须是16个字节长度）
+ (NSData *)sm4Decrypt:(NSData *)cipherData
                   key:(NSData *)key
             cryptMode:(ZZSM4CryptMode)mode
          cryptPadding:(ZZSM4CryptPadding)padding
            optionalIV:(NSData *)iv;


@end

NS_ASSUME_NONNULL_END
