//
//  ZZSM2Cipher.h
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 公钥key
FOUNDATION_EXPORT NSString *const ZZSM2_PUBLIC_KEY;
/// 私钥key
FOUNDATION_EXPORT NSString *const ZZSM2_PRIVATE_KEY;

@interface ZZSM2Cipher : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// 自定义素数域椭圆曲线 y^2 = x^3 + ax + b , 基点G=(xG ,yG ), 其阶记为n
/// @param pHex 素数p, Hex字符串
/// @param aHex 系数a, Hex字符串
/// @param bHex 系数b, Hex字符串
/// @param gxHex 坐标xG, Hex字符串
/// @param gyHex 坐标yG, Hex字符串
/// @param nHex 阶n, Hex字符串
- (instancetype)initWithFpParamPHex:(NSString *)pHex
                               aHex:(NSString *)aHex
                               bHex:(NSString *)bHex
                              gxHex:(NSString *)gxHex
                              gyHex:(NSString *)gyHex
                               nHex:(NSString *)nHex;

#pragma mark - Fp(素数域)椭圆曲线 y^2 = x^3 + ax + b

/// 素数域192位椭圆曲线
+ (ZZSM2Cipher *)EC_Fp_192;

/// 素数域256位椭圆曲线（官方文档示例曲线）
+ (ZZSM2Cipher *)EC_Fp_256;

/// 素数域256位椭圆曲线（SM2椭圆曲线公钥密码算法推荐曲线）
+ (ZZSM2Cipher *)EC_Fp_SM2_256V1;

+ (ZZSM2Cipher *)EC_Fp_X9_62_256V1;

+ (ZZSM2Cipher *)EC_Fp_SECG_256K1;

#pragma mark - 随机生成公钥私钥

/// 随机生成公钥私钥, 公钥前缀04表示未压缩
/// @return @{ZZSM2_PUBLIC_KEY: @"04xxxxxxxx", ZZSM2_PRIVATE_KEY: @"xxxxxxxxx"}
- (NSDictionary<NSString *, NSString *> *)generateKeyPairHex;

@end

NS_ASSUME_NONNULL_END
