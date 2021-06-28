//
//  ZZSM2Cipher+Private.h
//  ZZSM2Encryptor
//
//  Created by SandsLee on 2021/6/28.
//

#import <ZZSM2Encryptor/ZZSM2Cipher.h>

NS_ASSUME_NONNULL_BEGIN

@class ZZBigInt;
@class ZZECPointFp;
@class ZZECCurveFp;

@interface ZZSM2Cipher ()

/// 椭圆曲线对象
@property (nonatomic, strong) ZZECCurveFp *curve;

/// 大素数p的16进制字符串
@property (nonatomic, copy) NSString *pHex;

/// 系数a的16进制字符串
@property (nonatomic, copy) NSString *aHex;

/// 系数b的16进制字符串
@property (nonatomic, copy) NSString *bHex;

/// 坐标xG, Hex字符串
@property (nonatomic, copy) NSString *gxHex;

/// 坐标yG, Hex字符串
@property (nonatomic, copy) NSString *gyHex;

/// 阶 n
@property (nonatomic, strong) ZZBigInt *n;

/// 阶 n 的16进制字符串
@property (nonatomic, copy) NSString *nHex;

#pragma mark - Private

/// 获取椭圆曲线点的长度
- (NSUInteger)getPointLen;

/// 随机一个大数K
- (ZZBigInt *)randomBigIntegerK;

/// 倍点 k*G
/// @param k 大数k
- (ZZECPointFp *)kG:(ZZBigInt *)k;

/// 倍点
/// @param k 大数k
/// @param pPoint 点对象
- (ZZECPointFp *)kP:(ZZBigInt *)k PPoint:(ZZECPointFp *)pPoint;

/// 倍点
/// @param k 大数k
/// @param pPointHex 点对应的16进制字符串
- (ZZECPointFp *)kP:(ZZBigInt *)k PPointHex:(NSString *)pPointHex;

@end

NS_ASSUME_NONNULL_END
