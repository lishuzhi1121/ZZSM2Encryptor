//
//  ZZECPointFp.m
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import "ZZECPointFp.h"
#import "ZZBigInt.h"
#import "ZZECCurveFp.h"
#import "ZZECFieldElementFp.h"



@interface ZZECPointFp ()

@property (nonatomic, weak) ZZECCurveFp *curve;
@property (nonatomic, strong) ZZECFieldElementFp *x;
@property (nonatomic, strong) ZZECFieldElementFp *y;
@property (nonatomic, strong) ZZBigInt *z;
@property (nonatomic, strong) ZZBigInt *zinv;

@end


@implementation ZZECPointFp

- (instancetype)initWithCurve:(ZZECCurveFp *)curve
                            x:(ZZECFieldElementFp *)x
                            y:(ZZECFieldElementFp *)y
                            z:(ZZBigInt *)z {
    if (self = [super init]) {
        self.curve = curve;
        self.x = x;
        self.y = y;
        // 标准射影坐标系: zinv == null 或 z * zinv == 1
        self.z = z == nil ? [ZZBigInt one] : z;
        
        self.zinv = nil;
    }
    return self;
}

- (ZZECFieldElementFp *)getX {
    @autoreleasepool {
        if (self.zinv == nil) {
            self.zinv = [self.z modInverseByBigInt:self.curve.q];
        }
        ZZBigInt *tmp = [[[self.x toBigInteger] multiplyByBigInt:self.zinv] modByBigInt:self.curve.q];
        return [self.curve fromBigInteger:tmp];
    }
}

- (ZZECFieldElementFp *)getY {
    @autoreleasepool {
        if (self.zinv == nil) {
            self.zinv = [self.z modInverseByBigInt:self.curve.q];
        }
        ZZBigInt *tmp = [[[self.y toBigInteger] multiplyByBigInt:self.zinv] modByBigInt:self.curve.q];
        return [self.curve fromBigInteger:tmp];
    }
}

// 取反, x轴对称点
- (ZZECPointFp *)negate {
    @autoreleasepool {
        return [[ZZECPointFp alloc] initWithCurve:self.curve
                                                x:self.x
                                                y:[self.y negate]
                                                z:self.z];
    }
}


/// 相加运算
/// 标准射影坐标系
/// λ1 = x1 * z2
/// λ2 = x2 * z1
/// λ3 = λ1 − λ2
/// λ4 = y1 * z2
/// λ5 = y2 * z1
/// λ6 = λ4 − λ5
/// λ7 = λ1 + λ2
/// λ8 = z1 * z2
/// λ9 = λ3^2
/// λ10 = λ3 * λ9
/// λ11 = λ8 * λ6^2 − λ7 * λ9
/// x3 = λ3 * λ11
/// y3 = λ6 * (λ9 * λ1 − λ11) − λ4 * λ10
/// z3 = λ10 * λ8
/// @param b 另一个点
- (ZZECPointFp *)add:(ZZECPointFp *)b {
    @autoreleasepool {
        if ([self isInfinity]) {
            return b;
        }
        if ([b isInfinity]) {
            return self;
        }
        
        ZZBigInt *x1 = [self.x toBigInteger];
        ZZBigInt *y1 = [self.y toBigInteger];
        ZZBigInt *z1 = self.z;
        ZZBigInt *x2 = [b.x toBigInteger];
        ZZBigInt *y2 = [b.y toBigInteger];
        ZZBigInt *z2 = b.z;
        ZZBigInt *q = self.curve.q;
        
        ZZBigInt *w1 = [[x1 multiplyByBigInt:z2] modByBigInt:q];
        ZZBigInt *w2 = [[x2 multiplyByBigInt:z1] modByBigInt:q];
        ZZBigInt *w3 = [w1 subByBigInt:w2];
        ZZBigInt *w4 = [[y1 multiplyByBigInt:z2] modByBigInt:q];
        ZZBigInt *w5 = [[y2 multiplyByBigInt:z1] modByBigInt:q];
        ZZBigInt *w6 = [w4 subByBigInt:w5];
        
        if ([w3 compare:[ZZBigInt zero]] == NSOrderedSame) {
            if ([w6 compare:[ZZBigInt zero]] == NSOrderedSame) {
                return [self twice];
            }
            return self.curve.infinity;
        }
        
        ZZBigInt *w7 = [w1 addByBigInt:w2];
        ZZBigInt *w8 = [[z1 multiplyByBigInt:z2] modByBigInt:q];
        ZZBigInt *w9 = [[w3 square] modByBigInt:q];
        ZZBigInt *w10 = [[w3 multiplyByBigInt:w9] modByBigInt:q];
        ZZBigInt *w11 = [[[w8 multiplyByBigInt:[w6 square]] subByBigInt:[w7 multiplyByBigInt:w9]] modByBigInt:q];
        
        ZZBigInt *x3 = [[w3 multiplyByBigInt:w11] modByBigInt:q];
        ZZBigInt *y3 = [[[w6 multiplyByBigInt:[[w1 multiplyByBigInt:w9] subByBigInt:w11]] subByBigInt:[w4 multiplyByBigInt:w10]] modByBigInt:q];
        ZZBigInt *z3 = [[w8 multiplyByBigInt:w10] modByBigInt:q];
        
        return [[ZZECPointFp alloc] initWithCurve:self.curve
                                                x:[self.curve fromBigInteger:x3]
                                                y:[self.curve fromBigInteger:y3]
                                                z:z3];
    }
}

/// 自加运算
/// 标准射影坐标系：
///  λ1 = 3 * x1^2 + a * z1^2
///  λ2 = 2 * y1 * z1
///  λ3 = y1^2
///  λ4 = λ3 * x1 * z1
///  λ5 = λ2^2
///  λ6 = λ1^2 − 8 * λ4
///  x3 = λ2 * λ6
///  y3 = λ1 * (4 * λ4 − λ6) − 2 * λ5 * λ3
///  z3 = λ2 * λ5
///
- (ZZECPointFp *)twice {
    @autoreleasepool {
        if ([self isInfinity]) {
            return self;
        }
        
        if (![[self.y toBigInteger] signum]) {
            return self.curve.infinity;
        }
        
        ZZBigInt *x1 = [self.x toBigInteger];
        ZZBigInt *y1 = [self.y toBigInteger];
        ZZBigInt *z1 = self.z;
        ZZBigInt *q = self.curve.q;
        ZZBigInt *a = [self.curve.a toBigInteger];
        
        ZZBigInt *w1 = [[[[x1 square] multiplyByBigInt:[ZZECCurveFp Three]] addByBigInt:[[z1 square] multiplyByBigInt:a]] modByBigInt:q];
        ZZBigInt *w2 = [[[y1 shiftLeft:1] multiplyByBigInt:z1] modByBigInt:q];
        ZZBigInt *w3 = [[y1 square] modByBigInt:q];
        ZZBigInt *w4 = [[[w3 multiplyByBigInt:x1] multiplyByBigInt:z1] modByBigInt:q];
        ZZBigInt *w5 = [[w2 square] modByBigInt:q];
        ZZBigInt *w6 = [[[w1 square] subByBigInt:[w4 shiftLeft:3]] modByBigInt:q];
        
        ZZBigInt *x3 = [[w2 multiplyByBigInt:w6] modByBigInt:q];
        ZZBigInt *y3 = [[[w1 multiplyByBigInt:[[w4 shiftLeft:2] subByBigInt:w6]] subByBigInt:[[w5 shiftLeft:1] multiplyByBigInt:w3]] modByBigInt:q];
        ZZBigInt *z3 = [[w2 multiplyByBigInt:w5] modByBigInt:q];
        
        return [[ZZECPointFp alloc] initWithCurve:self.curve
                                                x:[self.curve fromBigInteger:x3]
                                                y:[self.curve fromBigInteger:y3]
                                                z:z3];
    }
}

- (ZZECPointFp *)multiply:(ZZBigInt *)k {
    @autoreleasepool {
        if ([self isInfinity]) {
            return self; // 无穷远点的k倍还是无穷远
        }
        if (![k signum]) {
            return self.curve.infinity;
        }
        
        ZZBigInt *k3 = [k multiplyByBigInt:[ZZECCurveFp Three]];
        ZZECPointFp *neg = [self negate];
        ZZECPointFp *Q = self;
        for (uint64_t i = ([k3 bitLength] - 2); i > 0; i--) {
            Q = [Q twice];
            
            BOOL k3Bit = [k3 testBit:i];
            BOOL kBit = [k testBit:i];
            
            if (k3Bit != kBit) {
                Q = [Q add:(k3Bit ? self : neg)];
            }
        }
        
        return Q;
    }
}

/// 判断是否是同一个点
/// @param b 另一个点
- (BOOL)_equals:(ZZECPointFp *)b {
    @autoreleasepool {
        if (self == b) {
            return true;
        }
        if ([self isInfinity]) {
            return [b isInfinity];
        }
        if ([b isInfinity]) {
            return [self isInfinity];
        }
        
        // u = y2 * z1 - y1 * z2
        ZZBigInt *u = [[[[b.y toBigInteger] multiplyByBigInt:self.z] subByBigInt:[[self.y toBigInteger] multiplyByBigInt:b.z]] modByBigInt:self.curve.q];
        if ([u compare:[ZZBigInt zero]] != NSOrderedSame) {
            return false;
        }
        
        // v = x2 * z1 - x1 * z2
        ZZBigInt *v = [[[[b.x toBigInteger] multiplyByBigInt:self.z] subByBigInt:[[self.x toBigInteger] multiplyByBigInt:b.z]] modByBigInt:self.curve.q];
        return [v compare:[ZZBigInt zero]] == NSOrderedSame;
    }
}

/// 判断是否是无穷远点
- (BOOL)isInfinity {
    @autoreleasepool {
        if (self.x == nil && self.y == nil) {
            return true;
        }
        
        return ([self.z compare:[ZZBigInt zero]] == NSOrderedSame) && ([[self.y toBigInteger] compare:[ZZBigInt zero]] != NSOrderedSame);
    }
}

@end
