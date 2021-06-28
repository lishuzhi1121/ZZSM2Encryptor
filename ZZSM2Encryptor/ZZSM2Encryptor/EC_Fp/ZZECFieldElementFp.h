//
//  ZZECFieldElementFp.h
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import <Foundation/Foundation.h>


@class ZZBigInt;

NS_ASSUME_NONNULL_BEGIN

/// 椭圆曲线域元素
@interface ZZECFieldElementFp : NSObject

-(instancetype)init NS_UNAVAILABLE;

/// 构造椭圆曲线域元素
/// @param q 素数q, 大数
/// @param x 系数, 大数
- (instancetype)initWithQ:(ZZBigInt *)q x:(ZZBigInt *)x;

/// 判断两个元素是否相等
/// @param other 另一个元素对象
- (BOOL)equals:(ZZECFieldElementFp *)other;

/// 返回具体数值
- (ZZBigInt *)toBigInteger;

#pragma mark - 运算

/// 取反
- (ZZECFieldElementFp *)negate;

/// 相加
/// @param b 另一个元素
- (ZZECFieldElementFp *)add:(ZZECFieldElementFp *)b;

/// 相减
/// @param b 另一个元素
- (ZZECFieldElementFp *)subtract:(ZZECFieldElementFp *)b;

/// 相乘
/// @param b 另一个元素
- (ZZECFieldElementFp *)multiply:(ZZECFieldElementFp *)b;

/// 相除
/// @param b 另一个元素
- (ZZECFieldElementFp *)divide:(ZZECFieldElementFp *)b;

/// 平方
- (ZZECFieldElementFp *)square;

/// 平方根 -- 点压缩: (y^2) mod n = a mob n, 求y
- (ZZECFieldElementFp *)modsqrt;

@end

NS_ASSUME_NONNULL_END
