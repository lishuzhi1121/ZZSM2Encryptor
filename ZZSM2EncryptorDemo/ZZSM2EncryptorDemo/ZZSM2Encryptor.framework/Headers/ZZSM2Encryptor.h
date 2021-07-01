//
//  ZZSM2Encryptor.h
//  ZZSM2Encryptor
//
//  Created by SandsLee on 2021/6/28.
//

#import <Foundation/Foundation.h>
#import <ZZSM2Encryptor/ZZSM2Cipher.h>
#import <ZZSM2Encryptor/ZZSM2Util.h>

NS_ASSUME_NONNULL_BEGIN

/// SM2加密时的密文输出模式
typedef NS_ENUM(NSUInteger, ZZSM2CipherMode) {
    ZZSM2CipherModeC1C2C3 = 0,  // C = C1 || C2 || C3
    ZZSM2CipherModeC1C3C2,      // C = C1 || C3 || C2
};

/// 国密SM2加解密工具类
@interface ZZSM2Encryptor : NSObject

#pragma mark - SM2密钥生成

/// 随机生成公钥私钥
/// 默认生成与SM2椭圆曲线公钥密码算法推荐曲线对应的密钥
/// 公钥前缀04表示未压缩, 使用时要去除
/// @return @{@"publicKey": @"04xxxxxxxx", @"privateKey": @"xxxxxxxxx"}
+ (NSDictionary *)generateSM2KeyPairHex;

/// 随机生成公钥私钥
/// 公钥前缀04表示未压缩, 使用时要去除
/// @param cipher 椭圆曲线相关系数(p,a,b,Gx,Gy,n)
/// @return @{@"publicKey": @"04xxxxxxxx", @"privateKey": @"xxxxxxxxx"}
+ (NSDictionary *)generateSM2KeyPairHexByCipher:(ZZSM2Cipher *)cipher;

#pragma mark - SM2加解密

/// SM2 加密, 默认SM2椭圆曲线公钥密码算法推荐曲线, 默认输出模式 C1 || C2 || C3
/// @param plainData 明文的二进制数据
/// @param publicKey 公钥字符串（注意: 密钥字符串要与SM2椭圆曲线公钥密码算法推荐曲线对应）
+ (NSData *)sm2Encrypt:(NSData *)plainData publicKey:(NSString *)publicKey;

/// SM2 解密, 默认SM2椭圆曲线公钥密码算法推荐曲线, 默认输出模式 C1 || C2 || C3
/// @param cipherData 密文的二进制数据
/// @param privateKey 私钥字符串（注意: 密钥字符串要与SM2椭圆曲线公钥密码算法推荐曲线对应）
+ (NSData *)sm2Decrypt:(NSData *)cipherData privateKey:(NSString *)privateKey;


/// SM2 加密
/// @param plainData 明文的二进制数据
/// @param publicKey 公钥字符串（注意: 密钥字符串要与椭圆曲线对应）
/// @param cipher 椭圆曲线相关系数(p,a,b,Gx,Gy,n)
/// @param mode 密文输出模式 C1 || C2 || C3 或者 C1 || C3 || C2
+ (NSData *)sm2Encrypt:(NSData *)plainData
             publicKey:(NSString *)publicKey
                cipher:(ZZSM2Cipher *)cipher
                  mode:(ZZSM2CipherMode)mode;

/// SM2 解密
/// @param cipherData 密文的二进制数据
/// @param privateKey 私钥字符串（注意: 密钥字符串要与椭圆曲线对应）
/// @param cipher 椭圆曲线相关系数(p,a,b,Gx,Gy,n)
/// @param mode 密文输出模式 C1 || C2 || C3 或者 C1 || C3 || C2
+ (NSData *)sm2Decrypt:(NSData *)cipherData
            privateKey:(NSString *)privateKey
                cipher:(ZZSM2Cipher *)cipher
                  mode:(ZZSM2CipherMode)mode;

#pragma mark - SM2数字签名

/// SM2数字签名
/// @param srcData 待签名的二进制数据
/// @param userId 签名用户身份标识
/// @param privateKey 私钥字符串
/// @param cipher 椭圆曲线相关系数(p,a,b,Gx,Gy,n)
/// @return SM2数字签名校验值
+ (NSData *)sm2Sign:(NSData *)srcData
             userId:(NSString *)userId
         privateKey:(NSString *)privateKey
             cipher:(ZZSM2Cipher *)cipher;

/// SM2验证签名
/// @param srcData 待验签的二进制数据
/// @param userId 签名用户身份标识
/// @param publicKey 公钥字符串
/// @param cipher 椭圆曲线相关系数(p,a,b,Gx,Gy,n)
/// @param sign 签名校验值
/// @return SM2签名验证结果 YES: 成功, NO: 失败
+ (BOOL)sm2Verify:(NSData *)srcData
           userId:(NSString *)userId
        publicKey:(NSString *)publicKey
           cipher:(ZZSM2Cipher *)cipher
             sign:(NSData *)sign;

#pragma mark - SM3哈希

/// 生成 SM3 摘要
/// @param message 信息字符串
+ (NSData *)sm3HashWithString:(NSString *)message;

/// 生成 SM3 摘要
/// @param data 信息数据
+ (NSData *)sm3HashWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
