//
//  ZZBigInt.h
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 大数对象
@interface ZZBigInt : NSObject

/// 初始化大数对象(默认填充0)
/// @return 大数对象
- (instancetype)init;

/// 初始化大数对象
/// @param value 整型数据
/// @return 大数对象
- (instancetype)initWithInt:(NSInteger)value;

/// 初始化大数对象
/// @param value 大数对象
/// @return 大数对象
- (instancetype)initWithBigInteger:(ZZBigInt *)value;

/// 初始化大数对象
/// @param valueString 数值字符串
/// @return 大数对象
- (instancetype)initWithString:(NSString *)valueString;

/// 初始化大数对象
/// @param valueString 数值字符串
/// @param radix 数值进制
/// @return 大数对象
- (instancetype)initWithString:(NSString *)valueString radix:(int)radix;

/// 初始化大数对象
/// @param bits 大素数位数
/// @return 大数对象
- (instancetype)initWithRandomPremeBits:(int)bits;

/// 初始化大数对象
/// @param bits 位数
/// @return 大数对象
- (instancetype)initWithRandomBits:(int)bits;

/// 初始化大数对象
/// @param bytes 字节流
/// @param size 字节长度
/// @return 大数对象
- (instancetype)initWithBytes:(const void *)bytes size:(int)size;

/// 初始化大数对象
/// @param bytes 无符号字节流
/// @param size 字节长度
/// @return 大数对象
- (instancetype)initWithUnsignedBytes:(const void *)bytes size:(int)size;

#pragma mark - 特殊大数对象 0,1

/// 获取大数对象 0
/// @return 大数对象
+ (ZZBigInt *)zero;

/// 获取大数对象 1
/// @return 大数对象
+ (ZZBigInt *)one;

#pragma mark - 大数运算

#pragma mark - 加

/// 大数相加运算
/// @param value 大数对象
- (ZZBigInt *)addByBigInt:(ZZBigInt *)value;

/// 大数相加运算
/// @param value 整数
- (ZZBigInt *)addByInt:(NSInteger)value;

#pragma mark - 减

/// 大数相减运算
/// @param value 大数对象
- (ZZBigInt *)subByBigInt:(ZZBigInt *)value;

/// 大数相减运算
/// @param value 整数
- (ZZBigInt *)subByInt:(NSInteger)value;

#pragma mark - 乘

/// 大数相乘运算
/// @param value 大数对象
- (ZZBigInt *)multiplyByBigInt:(ZZBigInt *)value;

/// 大数相乘运算
/// @param value 整数
- (ZZBigInt *)multiplyByInt:(NSInteger)value;

#pragma mark - 除

/// 大数相除运算
/// @param value 大数对象
- (ZZBigInt *)divideByBigInt:(ZZBigInt *)value;

/// 大数相除运算
/// @param value 整数
- (ZZBigInt *)divideByInt:(NSInteger)value;

#pragma mark - 求余

/// 大数求余运算
/// @param value 大数对象
- (ZZBigInt *)remainderByBigInt:(ZZBigInt *)value;

/// 大数求余运算
/// @param value 整数
- (ZZBigInt *)remainderByInt:(NSInteger)value;

#pragma mark - 幂运算

/// 大数幂运算
/// @param exponent 指数
- (ZZBigInt *)pow:(NSUInteger)exponent;

#pragma mark - 幂运算求余

/// 大数幂运算求余
/// @param exponent 指数
/// @param value 模数
- (ZZBigInt *)pow:(ZZBigInt *)exponent mod:(ZZBigInt *)value;

#pragma mark - 平方

/// 大数平方运算
- (ZZBigInt *)square;

#pragma mark - 平方根

/// 大数平方根运算
- (ZZBigInt *)sqrt;

#pragma mark - 求反

/// 大数求反运算
- (ZZBigInt *)negate;

#pragma mark - 绝对值

/// 大数绝对值
- (ZZBigInt *)abs;

#pragma mark - 异或

/// 大数按位异或
/// @param value 大数
- (ZZBigInt *)bitwiseXorByBigInt:(ZZBigInt *)value;

/// 大数按位异或
/// @param value 整数
- (ZZBigInt *)bitwiseXorByInt:(NSInteger)value;

#pragma mark - 或

/// 大数按位或
/// @param value 大数
- (ZZBigInt *)bitwiseOrByBigInt:(ZZBigInt *)value;

/// 大数按位或
/// @param value 整数
- (ZZBigInt *)bitwiseOrByInt:(NSInteger)value;

#pragma mark - 与

/// 大数按位与
/// @param value 大数
- (ZZBigInt *)bitwiseAndByBigInt:(ZZBigInt *)value;

/// 大数按位与
/// @param value 整数
- (ZZBigInt *)bitwiseAndByInt:(NSInteger)value;

#pragma mark - 左移

/// 大数左移运算
/// @param num 左移位数
- (ZZBigInt *)shiftLeft:(int)num;

#pragma mark - 右移

/// 大数右移运算
/// @param num 右移位数
- (ZZBigInt *)shiftRight:(int)num;

#pragma mark - 最大公约数

/// 大数与大数的最大公约数
/// @param value 大数
- (ZZBigInt *)gcdByBigInt:(ZZBigInt *)value;

/// 大数与整数的最大公约数
/// @param value 整数
- (ZZBigInt *)gcdByInt:(NSInteger)value;

#pragma mark - 余逆

/// 大数求余逆
/// @param n 阶数
- (ZZBigInt *)modInverseByBigInt:(ZZBigInt *)n;

/// 大数求余逆
/// @param n 阶数
- (ZZBigInt *)modInverseByInt:(NSInteger)n;

#pragma mark - 余

/// 大数求余
/// @param n 阶数
- (ZZBigInt *)modByBigInt:(ZZBigInt *)n;

/// 大数求余
/// @param n 阶数
- (ZZBigInt *)modByInt:(NSInteger)n;

#pragma mark - 其他运算

/// 大数比较
/// @param value 大数
- (NSComparisonResult)compare:(ZZBigInt *)value;

/// 转为字符串
- (NSString *)toString;

/// 转为字符串
/// @param radix 进制
- (NSString *)toString:(int)radix;

/// 获取大数字节流
/// @param bytes 字节流输出
/// @param length 字节流长度输出
- (void)getBytes:(void *_Nullable*_Nullable)bytes length:(int *)length;

/// 获取大数无符号字节流
/// @param bytes 字节流输出
/// @param length 字节流长度输出
- (void)getUnsignedBytes:(void *_Nullable*_Nullable)bytes length:(int *)length;

/// 判断大数与0比较的结果
- (int)signum;

/// 二进制位长度
- (uint64_t)bitLength;

- (BOOL)testBit:(uint64_t)index;

@end


/// 大数的商和余数对象
@interface ZZBigInt_QuotientAndRemainder : NSObject

/// 商
@property (nonatomic, strong) ZZBigInt *quotient;

/// 余数
@property (nonatomic, strong) ZZBigInt *remainder;

/// 构造函数
/// @param quotient 商
/// @param remainder 余数
- (instancetype)initWithQuotient:(ZZBigInt *)quotient
                       remainder:(ZZBigInt *)remainder;

@end

NS_ASSUME_NONNULL_END
