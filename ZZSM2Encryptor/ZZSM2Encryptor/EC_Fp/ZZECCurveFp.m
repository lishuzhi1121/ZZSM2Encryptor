//
//  ZZECCurveFp.m
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import "ZZECCurveFp.h"
#import "ZZBigInt.h"
#import "ZZECFieldElementFp.h"
#import "ZZECPointFp.h"
#import "ZZSM2Util.h"

@interface ZZECCurveFp ()

@property (nonatomic, strong) ZZBigInt *q;
@property (nonatomic, strong) ZZECFieldElementFp *a;
@property (nonatomic, strong) ZZECFieldElementFp *b;
@property (nonatomic, assign) NSUInteger pointLen;
@property (nonatomic, strong) ZZECPointFp *infinity;

@end

@implementation ZZECCurveFp

- (instancetype)initWithQ:(ZZBigInt *)q
                        a:(ZZBigInt *)a
                        b:(ZZBigInt *)b
                 pointLen:(NSUInteger)len {
    if (self = [super init]) {
        self.q = q;
        self.a = [self fromBigInteger:a];
        self.b = [self fromBigInteger:b];
        self.pointLen = len;
        self.infinity = [[ZZECPointFp alloc] initWithCurve:self
                                                         x:nil
                                                         y:nil
                                                         z:nil];
    }
    return self;
}

+ (ZZBigInt *)Three {
    static ZZBigInt *three = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        three = [[ZZBigInt alloc] initWithInt:3];
    });
    
    return three;
}

- (ZZECFieldElementFp *)fromBigInteger:(ZZBigInt *)x {
    return [[ZZECFieldElementFp alloc] initWithQ:self.q x:x];
}

#pragma mark - 椭圆曲线点的压缩与解压缩

/// 坐标点压缩成16进制字符串
/// @param point 坐标点对象
/// @param compressed 是否采用压缩格式
/// 压缩格式: 若公钥y坐标最后一位为0, 则首字节为0x02, 否则为0x03
/// 非压缩格式: 公钥首字节为0x04
- (NSString *)encodePoint:(ZZECPointFp *)point compressed:(BOOL)compressed {
    NSString *pointHex = nil;
    if (compressed) {
        // 02 03
        NSString *pointX = [ZZSM2Util leftPad:[[[point getX] toBigInteger] toString:16]
                                           num:self.pointLen/2];
        ZZBigInt *y = [[point getY] toBigInteger];
        ZZBigInt *py = [y bitwiseAndByInt:1];
        ZZBigInt *pc = [py bitwiseOrByInt:0x02];
        NSString *pcStr = [ZZSM2Util leftPad:[pc toString:16] num:2];
        NSRange range = NSMakeRange(pcStr.length - 2, 2);
        pcStr = [pcStr substringWithRange:range];
        
        pointHex = [NSString stringWithFormat:@"%@%@", pcStr, pointX];
    } else {
        // 04
        NSString *pointX = [ZZSM2Util leftPad:[[[point getX] toBigInteger] toString:16]
                                           num:self.pointLen/2];
        NSString *pointY = [ZZSM2Util leftPad:[[[point getY] toBigInteger] toString:16]
                                           num:self.pointLen/2];
        pointHex = [NSString stringWithFormat:@"04%@%@", pointX, pointY];
    }
    
    return pointHex;
}

/// 16进制字符串解压缩为坐标点
/// @param s 16进制字符串
- (ZZECPointFp *)decodePointHex:(NSString *)s {
    if (![s isKindOfClass:[NSString class]] || s.length < 2) {
        return nil;
    }
    
    NSRange range = NSMakeRange(0, 2);
    const char *cStr = [[s substringWithRange:range] UTF8String]; // 取前两位
    char *ptr = NULL;
    unsigned long outVal = strtoul(cStr, &ptr, 16); // 字符串转整数
    switch (outVal) {
        case 0:
            return self.infinity;
            break;
        case 2:
        case 3:
        {
            // 已知椭圆曲线: y^2 = x^3 + ax +b, 和已知点的x坐标值, 求已知点的y坐标值
            NSUInteger len = s.length - 2; // 编码压缩后的首字节长度为2
            if (len != self.pointLen / 2) {
                // 字符串长度不合法
                return nil;
            }
            
            NSRange range = NSMakeRange(2, len);
            NSString *xHex = [s substringWithRange:range];
            ZZBigInt *x = [[ZZBigInt alloc] initWithString:xHex radix:16];
            // 大数x转为椭圆曲线元素
            ZZECFieldElementFp *x_fe = [self fromBigInteger:x];
            ZZECFieldElementFp *rhs = [[x_fe square] multiply:x_fe];
            rhs = [rhs add:[self.a multiply:x_fe]];
            rhs = [rhs add:self.b];
            // 这里是[y^2 mod q = (x^3 + ax + b) mod q]求y(模平方根)
            ZZECFieldElementFp *y_fe = [rhs modsqrt];
            
            unsigned long yp = outVal & 1;
            if ([[[y_fe toBigInteger] bitwiseAndByInt:1] compare:[[ZZBigInt alloc] initWithInt:yp]] == NSOrderedSame) {
                return [[ZZECPointFp alloc] initWithCurve:self
                                                        x:x_fe
                                                        y:y_fe
                                                        z:nil];
            } else {
                ZZECFieldElementFp *field = [[ZZECFieldElementFp alloc] initWithQ:self.q x:self.q];
                y_fe = [field subtract:y_fe];
                return [[ZZECPointFp alloc] initWithCurve:self
                                                        x:x_fe
                                                        y:y_fe
                                                        z:nil];
            }
            // decode error
            return nil;
        }
            break;
        case 4:
        case 6:
        case 7:
        {
            // 已知椭圆曲线: y^2 = x^3 + ax +b, 和已知点的x坐标值, 求已知点的y坐标值
            NSUInteger len = (s.length - 2) / 2; // 编码非压缩后的首字节长度为2, 单个坐标值长度要除以2
            if (len != self.pointLen / 2) {
                // 字符串长度不合法
                return nil;
            }
            
            NSRange range = NSMakeRange(2, len);
            NSString *xHex = [s substringWithRange:range];
            ZZBigInt *x = [[ZZBigInt alloc] initWithString:xHex radix:16];
            // 大数x转为椭圆曲线元素
            ZZECFieldElementFp *x_fe = [self fromBigInteger:x];
            
            range.location = 2 + len; // 修改range, 取出y
            NSString *yHex = [s substringWithRange:range];
            ZZBigInt *y = [[ZZBigInt alloc] initWithString:yHex radix:16];
            // 大数y转为椭圆曲线元素
            ZZECFieldElementFp *y_fe = [self fromBigInteger:y];
            
            return [[ZZECPointFp alloc] initWithCurve:self
                                                    x:x_fe
                                                    y:y_fe
                                                    z:nil];
        }
            break;
            
        default:
            return nil;
            break;
    }
    
    return nil;
}

#pragma mark - to string

- (NSString *)toString {
    NSString *aStr = [[self.a toBigInteger] toString];
    NSString *bStr = [[self.b toBigInteger] toString];
    NSString *qStr = [self.q toString];
    return [NSString stringWithFormat:@"\"Fp\": y^2 = x^3 + %@x + %@ over %@", aStr, bStr, qStr];
}

@end
