//
//  ZZECFieldElementFp.m
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import "ZZECFieldElementFp.h"
#import "ZZBigInt.h"

@interface ZZECFieldElementFp ()

/// 素数
@property (nonatomic, strong) ZZBigInt *q;

/// 系数
@property (nonatomic, strong) ZZBigInt *x;

@end

@implementation ZZECFieldElementFp

- (instancetype)initWithQ:(ZZBigInt *)q x:(ZZBigInt *)x {
    if (self = [super init]) {
        self.q = q;
        self.x = x;
    }
    return self;
}

- (BOOL)equals:(ZZECFieldElementFp *)other {
    @autoreleasepool {
        if (self == other) {
            return YES;
        }
        return (([self.q compare:other.q] == NSOrderedSame) &&
                ([self.x compare:other.x] == NSOrderedSame));
    }
}

- (ZZBigInt *)toBigInteger {
    return self.x;
}

- (ZZECFieldElementFp *)negate {
    @autoreleasepool {
        return [[ZZECFieldElementFp alloc] initWithQ:self.q
                                                   x:[[self.x negate] modByBigInt:self.q]];
    }
}

- (ZZECFieldElementFp *)add:(ZZECFieldElementFp *)b {
    @autoreleasepool {
        ZZBigInt *tmp = [b toBigInteger];
        return [[ZZECFieldElementFp alloc] initWithQ:self.q
                                                   x:[[self.x addByBigInt:tmp] modByBigInt:self.q]];
    }
}

- (ZZECFieldElementFp *)subtract:(ZZECFieldElementFp *)b {
    @autoreleasepool {
        ZZBigInt *tmp = [b toBigInteger];
        return [[ZZECFieldElementFp alloc] initWithQ:self.q
                                                   x:[[self.x subByBigInt:tmp] modByBigInt:self.q]];
    }
}

- (ZZECFieldElementFp *)multiply:(ZZECFieldElementFp *)b {
    @autoreleasepool {
        ZZBigInt *tmp = [b toBigInteger];
        return [[ZZECFieldElementFp alloc] initWithQ:self.q
                                                   x:[[self.x multiplyByBigInt:tmp] modByBigInt:self.q]];
    }
}

- (ZZECFieldElementFp *)divide:(ZZECFieldElementFp *)b {
    @autoreleasepool {
        ZZBigInt *tmp = [[b toBigInteger] modInverseByBigInt:self.q];
        return [[ZZECFieldElementFp alloc] initWithQ:self.q
                                                   x:[[self.x multiplyByBigInt:tmp] modByBigInt:self.q]];
    }
}

- (ZZECFieldElementFp *)square {
    @autoreleasepool {
        return [[ZZECFieldElementFp alloc] initWithQ:self.q
                                                   x:[[self.x square] modByBigInt:self.q]];
    }
}

#pragma mark - 模平方根/平方剩余

// https://blog.csdn.net/qq_41746268/article/details/98730749
// 对于给定的奇质数p, 和正整数x, 存在y满足 1≤y≤p−1, 且 x≡y^2(mod p), 则称y为x的模平方根
// 对于正整数m, 若同余式 x^2 ≡ a(mod m) 有解, 则称a为模m的平方剩余, 否则称为模m平方非剩余
//是否存在模平方根
//根据欧拉判别条件:
//设p是奇质数，对于x^2≡a(mod p)
//a是模p的平方剩余的充要条件是(a^((p−1)/2)) % p = 1
//a是模p的平方非剩余的充要条件是(a^((p−1)/2)) % p = -1
//给定a, n(n是质数)，求x^2≡a(mod n)的最小整数解x
//代码复杂度O(log^2(n))

- (ZZECFieldElementFp *)modsqrt {
    @autoreleasepool {
        ZZBigInt *b, *i, *k, *y;
        
        ZZBigInt *n = _q;
        ZZBigInt *a = _x;
        
        // n == 2
        if ([n compare:[[ZZBigInt alloc] initWithInt:2]] == NSOrderedSame) {
            // a%n
            return [[ZZECFieldElementFp alloc] initWithQ:self.q x:[a modByBigInt:n]];
        }
        
        // qpow(a, (n-1)/2, n) == 1 即a是模p的平方剩余
        ZZBigInt *res = [self _qpow:a b:[[n subByInt:1] divideByInt:2] p:n];
        if ([res compare:[ZZBigInt one]] == NSOrderedSame) {
            // a%4 == 3
            if ([[a modByInt:4] compare:[[ZZBigInt alloc] initWithInt:3]] == NSOrderedSame) {
                // y = qpow(a, (n+1)/4, n)
                y = [self _qpow:a b:[[n addByInt:1] divideByInt:4] p:n];
            } else {
                // for(b=1; qpow(b,(n-1)/2,n) == 1; b++);
                for (b = [ZZBigInt one]; [[self _qpow:b b:[[n subByInt:1] divideByInt:2] p:n] compare:[ZZBigInt one]] == NSOrderedSame;) {
                    [b addByInt:1];
                }
                // i = (n-1)/2;
                i = [[n subByInt:1] divideByInt:2];
                // k=0;
                k = [ZZBigInt zero];
                // while(i%2==0){
                while ([[i modByInt:2] compare:[ZZBigInt zero]] == NSOrderedSame) {
                    // i /= 2,k /= 2;
                    i = [i divideByInt:2];
                    k = [k divideByInt:2];
                    
                    // if((qpow(a,i,n)*qpow(b,k,n)+1)%n == 0) k += (n-1)/2;
                    ZZBigInt *tmp1 = [self _qpow:a b:i p:n];
                    ZZBigInt *tmp2 = [self _qpow:b b:k p:n];
                    if ([[[tmp1 multiplyByBigInt:tmp2] modByBigInt:n] compare:[ZZBigInt zero]] == NSOrderedSame) {
                        k = [k addByBigInt:[[n subByInt:1] divideByInt:2]];
                    }
                }
                // y = qpow(a,(i+1)/2,n)*qpow(b,k/2,n)%n;
                ZZBigInt *tt1 = [self _qpow:a b:[[n addByInt:1] divideByInt:2] p:n];
                ZZBigInt *tt2 = [self _qpow:b b:[k divideByInt:2] p:n];
                y = [[tt1 multiplyByBigInt:tt2] modByBigInt:n];
            }
            // if(y*2 > n) y = n-y;
            if ([[y multiplyByInt:2] compare:n] == NSOrderedDescending) {
                y = [n subByBigInt:y];
            }
            // return y;
            return [[ZZECFieldElementFp alloc] initWithQ:self.q x:y];
        }
        // return -1;
        return [[ZZECFieldElementFp alloc] initWithQ:self.q x:[[ZZBigInt alloc] initWithInt:-1]];
    }
}

/// 计算 a^b % p
/// @param a 大数a
/// @param b 指数b
/// @param p 奇质数p
- (ZZBigInt *)_qpow:(ZZBigInt *)a b:(ZZBigInt *)b p:(ZZBigInt *)p {
    @autoreleasepool {
        ZZBigInt *ans = [ZZBigInt one];
        // b != 0
        while ([b compare:[ZZBigInt zero]] != NSOrderedSame) {
            // b&1 != 0
            if ([[b bitwiseAndByInt:1] compare:[ZZBigInt zero]] != NSOrderedSame) {
                // ans = ans * a % p
                ans = [[ans multiplyByBigInt:a] modByBigInt:p];
            }
            // a = a * a % p
            a = [[a multiplyByBigInt:a] modByBigInt:p];
            // b>>=1
            b = [b shiftRight:1];
        }
        return ans;
    }
}

@end
