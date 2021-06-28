//
//  ZZECPointFp.h
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import <Foundation/Foundation.h>

@class ZZBigInt;
@class ZZECFieldElementFp;
@class ZZECCurveFp;

NS_ASSUME_NONNULL_BEGIN

/// 椭圆曲线上的点
@interface ZZECPointFp : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// 构造椭圆曲线上的点
/// @param curve 椭圆曲线对象
/// @param x 椭圆曲线域元素x
/// @param y 椭圆曲线域元素y
/// @param z 大数z
- (instancetype)initWithCurve:(ZZECCurveFp *)curve
                            x:(nullable ZZECFieldElementFp *)x
                            y:(nullable ZZECFieldElementFp *)y
                            z:(nullable ZZBigInt *)z;

/// 椭圆曲线上的X坐标值
- (ZZECFieldElementFp *)getX;

/// 椭圆曲线上的Y坐标值
- (ZZECFieldElementFp *)getY;

/// Point 在椭圆上的对称点
- (ZZECPointFp *)negate;

/// 相同点(twice) 不同点：两点连成线与椭圆相交另一点的对称点
/// @param b 另一点
- (ZZECPointFp *)add:(ZZECPointFp *)b;

/// Point 的切线与椭圆相交另一点的对称点
- (ZZECPointFp *)twice;

/// 倍点计算 k*G
/// @param k k值
- (ZZECPointFp *)multiply:(ZZBigInt *)k;

/// 判断是否是无穷远点
- (BOOL)isInfinity;

@end

NS_ASSUME_NONNULL_END
