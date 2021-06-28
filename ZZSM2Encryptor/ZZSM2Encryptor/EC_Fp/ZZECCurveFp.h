//
//  ZZECCurveFp.h
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import <Foundation/Foundation.h>

@class ZZBigInt;
@class ZZECFieldElementFp;
@class ZZECPointFp;

NS_ASSUME_NONNULL_BEGIN

/// 椭圆曲线 y^2 = x^3 + ax + b
@interface ZZECCurveFp : NSObject

@property (nonatomic, strong, readonly) ZZBigInt *q;
@property (nonatomic, strong, readonly) ZZECFieldElementFp *a;
@property (nonatomic, assign, readonly) NSUInteger pointLen;
@property (nonatomic, strong, readonly) ZZECPointFp *infinity;



- (instancetype)init NS_UNAVAILABLE;

/// 构造椭圆曲线
/// @param q 素数q
/// @param a 系数a
/// @param b 系数b
/// @param len 坐标点(x, y)的长度
- (instancetype)initWithQ:(ZZBigInt *)q
                        a:(ZZBigInt *)a
                        b:(ZZBigInt *)b
                 pointLen:(NSUInteger)len;

/// 大数3
+ (ZZBigInt *)Three;

/// 生成椭圆曲线域元素
/// @param x 大数
- (ZZECFieldElementFp *)fromBigInteger:(ZZBigInt *)x;

#pragma mark - 椭圆曲线点的压缩与解压缩

/// 坐标点压缩成16进制字符串
/// @param point 坐标点对象
/// @param compressed 是否压缩
- (NSString *)encodePoint:(ZZECPointFp *)point compressed:(BOOL)compressed;

/// 16进制字符串解压缩为坐标点
/// @param s 16进制字符串
- (ZZECPointFp *)decodePointHex:(NSString *)s;

/// 椭圆曲线描述字符串
- (NSString *)toString;

@end

NS_ASSUME_NONNULL_END
