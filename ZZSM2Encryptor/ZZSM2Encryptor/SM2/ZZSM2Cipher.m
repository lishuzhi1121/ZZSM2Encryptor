//
//  ZZSM2Cipher.m
//  ZZGSMDemo
//
//  Created by SandsLee on 2021/6/15.
//

#import "ZZSM2Cipher+Private.h"
#import "ZZBigInt.h"
#import "ZZECCurveFp.h"
#import "ZZECPointFp.h"
#import "ZZECFieldElementFp.h"
#import "ZZSM2Util.h"

/// 椭圆曲线类型定义
typedef NS_ENUM(NSUInteger, ZZECCMode) {
    ZZECCModeFp = 0, // Fp(素数域)椭圆曲线 y^2 = x^3 + ax + b
    ZZECCModeF2m,    // F2m(二元扩域)椭圆曲线 y^2 + xy = x^3 + ax^2 + b
};

@interface ZZSM2Cipher ()

/// 基点G, 椭圆曲线上的点对象
@property (nonatomic, strong) ZZECPointFp *g;

/// 椭圆曲线类型
@property (nonatomic, assign) ZZECCMode eccMode;

@end


@implementation ZZSM2Cipher

- (instancetype)initWithFpParamPHex:(NSString *)pHex
                               aHex:(NSString *)aHex
                               bHex:(NSString *)bHex
                              gxHex:(NSString *)gxHex
                              gyHex:(NSString *)gyHex
                               nHex:(NSString *)nHex {
    if (self = [super init]) {
        self.pHex   = pHex;
        self.aHex   = aHex;
        self.bHex   = bHex;
        self.gxHex  = gxHex;
        self.gyHex  = gyHex;
        self.nHex   = nHex;
        
        ZZBigInt *p = [[ZZBigInt alloc] initWithString:pHex radix:16];
        ZZBigInt *a = [[ZZBigInt alloc] initWithString:aHex radix:16];
        ZZBigInt *b = [[ZZBigInt alloc] initWithString:bHex radix:16];
        BOOL vaild = ((gxHex.length == gyHex.length) && (gxHex.length % 2 == 0));
        NSAssert(vaild, @"decode point error.");
        
        self.curve = [[ZZECCurveFp alloc] initWithQ:p
                                                  a:a
                                                  b:b
                                           pointLen:gxHex.length * 2];
        self.g = [self.curve decodePointHex:[NSString stringWithFormat:@"04%@%@", gxHex, gyHex]];
        self.n = [[ZZBigInt alloc] initWithString:nHex radix:16];
        
        self.eccMode = ZZECCModeFp;
    }
    return self;
}

#pragma mark - Fp(素数域)椭圆曲线 y^2 = x^3 + ax + b

+ (ZZSM2Cipher *)EC_Fp_192 {
    static ZZSM2Cipher *cipher192 = nil;
    static dispatch_once_t onceToken192;
    dispatch_once(&onceToken192, ^{
        NSString *pHex     = @"BDB6F4FE3E8B1D9E0DA8C0D46F4C318CEFE4AFE3B6B8551F";
        NSString *aHex     = @"BB8E5E8FBC115E139FE6A814FE48AAA6F0ADA1AA5DF91985";
        NSString *bHex     = @"1854BEBDC31B21B7AEFC80AB0ECD10D5B1B3308E6DBF11C1";
        
        NSString *gxHex    = @"4AD5F7048DE709AD51236DE65E4D4B482C836DC6E4106640";
        NSString *gyHex    = @"02BB3A02D4AAADACAE24817A4CA3A1B014B5270432DB27D2";
        NSString *nHex     = @"BDB6F4FE3E8B1D9E0DA8C0D40FC962195DFAE76F56564677";
        
        cipher192 = [[ZZSM2Cipher alloc] initWithFpParamPHex:pHex
                                                        aHex:aHex
                                                        bHex:bHex
                                                       gxHex:gxHex
                                                       gyHex:gyHex
                                                        nHex:nHex];
    });
    
    return cipher192;
}

/**
 椭圆曲线方程为:y^2 =x^3 +ax+b
 示例1:Fp -256
 素数p: 8542D69E 4C044F18 E8B92435 BF6FF7DE 45728391 5C45517D 722EDB8B 08F1DFC3
 系数a: 787968B4 FA32C3FD 2417842E 73BBFEFF 2F3C848B 6831D7E0 EC65228B 3937E498
 系数b: 63E4C6D3 B23B0C84 9CF84241 484BFE48 F61D59A5 B16BA06E 6E12D1DA 27C5249A
 余因子h: 1
 基点G=(xG ,yG )，其阶记为n。
 坐标xG: 421DEBD6 1B62EAB6 746434EB C3CC315E 32220B3B ADD50BDC 4C4E6C14 7FEDD43D
 坐标yG: 0680512B CBB42C07 D47349D2 153B70C4 E5D7FDFC BFA36EA1 A85841B9 E46E09A2
 阶n: 8542D69E 4C044F18 E8B92435 BF6FF7DD 29772063 0485628D 5AE74EE7 C32E79B7
 */
+ (ZZSM2Cipher *)EC_Fp_256 {
    static ZZSM2Cipher *cipher256 = nil;
    static dispatch_once_t onceToken256;
    dispatch_once(&onceToken256, ^{
        NSString *pHex     = @"8542D69E4C044F18E8B92435BF6FF7DE457283915C45517D722EDB8B08F1DFC3";
        NSString *aHex     = @"787968B4FA32C3FD2417842E73BBFEFF2F3C848B6831D7E0EC65228B3937E498";
        NSString *bHex     = @"63E4C6D3B23B0C849CF84241484BFE48F61D59A5B16BA06E6E12D1DA27C5249A";
        
        NSString *gxHex    = @"421DEBD61B62EAB6746434EBC3CC315E32220B3BADD50BDC4C4E6C147FEDD43D";
        NSString *gyHex    = @"0680512BCBB42C07D47349D2153B70C4E5D7FDFCBFA36EA1A85841B9E46E09A2";
        NSString *nHex     = @"8542D69E4C044F18E8B92435BF6FF7DD297720630485628D5AE74EE7C32E79B7";
        
        cipher256 = [[ZZSM2Cipher alloc] initWithFpParamPHex:pHex
                                                        aHex:aHex
                                                        bHex:bHex
                                                       gxHex:gxHex
                                                       gyHex:gyHex
                                                        nHex:nHex];
    });
    
    return cipher256;
}

/**
 SM2椭圆曲线公钥密码算法推荐曲线参数
 推荐使用素数域256位椭圆曲线。
 椭圆曲线方程:y^2 = x^3 + ax + b。
 曲线参数:
 p=FFFFFFFE FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000000 FFFFFFFF FFFFFFFF
 a=FFFFFFFE FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF 00000000 FFFFFFFF FFFFFFFC
 b=28E9FA9E 9D9F5E34 4D5A9E4B CF6509A7 F39789F5 15AB8F92 DDBCBD41 4D940E93
 n=FFFFFFFE FFFFFFFF FFFFFFFF FFFFFFFF 7203DF6B 21C6052B 53BBF409 39D54123
 Gx=32C4AE2C 1F198119 5F990446 6A39C994 8FE30BBF F2660BE1 715A4589 334C74C7
 Gy=BC3736A2 F4F6779C 59BDCEE3 6B692153 D0A9877C C62A4740 02DF32E5 2139F0A0
 */
+ (ZZSM2Cipher *)EC_Fp_SM2_256V1 {
    static ZZSM2Cipher *cipher256V1 = nil;
    static dispatch_once_t onceToken256V1;
    dispatch_once(&onceToken256V1, ^{
        NSString *pHex     = @"FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFF";
        NSString *aHex     = @"FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFC";
        NSString *bHex     = @"28E9FA9E9D9F5E344D5A9E4BCF6509A7F39789F515AB8F92DDBCBD414D940E93";
        
        NSString *gxHex    = @"32C4AE2C1F1981195F9904466A39C9948FE30BBFF2660BE1715A4589334C74C7";
        NSString *gyHex    = @"BC3736A2F4F6779C59BDCEE36B692153D0A9877CC62A474002DF32E52139F0A0";
        NSString *nHex     = @"FFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFF7203DF6B21C6052B53BBF40939D54123";
        
        cipher256V1 = [[ZZSM2Cipher alloc] initWithFpParamPHex:pHex
                                                          aHex:aHex
                                                          bHex:bHex
                                                         gxHex:gxHex
                                                         gyHex:gyHex
                                                          nHex:nHex];
    });
    
    return cipher256V1;
}

+ (ZZSM2Cipher *)EC_Fp_X9_62_256V1 {
    static ZZSM2Cipher *cipherX9_62_256V1 = nil;
    static dispatch_once_t onceTokenX9_62_256V1;
    dispatch_once(&onceTokenX9_62_256V1, ^{
        NSString *pHex     = @"FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF";
        NSString *aHex     = @"FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC";
        NSString *bHex     = @"5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B";
        
        NSString *gxHex    = @"6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296";
        NSString *gyHex    = @"4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5";
        NSString *nHex     = @"FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551";
        
        cipherX9_62_256V1 = [[ZZSM2Cipher alloc] initWithFpParamPHex:pHex
                                                                aHex:aHex
                                                                bHex:bHex
                                                               gxHex:gxHex
                                                               gyHex:gyHex
                                                                nHex:nHex];
    });
    
    return cipherX9_62_256V1;
}

+ (ZZSM2Cipher *)EC_Fp_SECG_256K1 {
    static ZZSM2Cipher *cipherSECG_256K1 = nil;
    static dispatch_once_t onceTokenSECG_256K1;
    dispatch_once(&onceTokenSECG_256K1, ^{
        NSString *pHex     = @"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F";
        NSString *aHex     = @"0000000000000000000000000000000000000000000000000000000000000000";
        NSString *bHex     = @"0000000000000000000000000000000000000000000000000000000000000007";
        
        NSString *gxHex    = @"79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798";
        NSString *gyHex    = @"483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8";
        NSString *nHex     = @"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141";
        
        cipherSECG_256K1 = [[ZZSM2Cipher alloc] initWithFpParamPHex:pHex
                                                               aHex:aHex
                                                               bHex:bHex
                                                              gxHex:gxHex
                                                              gyHex:gyHex
                                                               nHex:nHex];
    });
    
    return cipherSECG_256K1;
}

#pragma mark - 随机生成公私钥

- (NSDictionary<NSString *,NSString *> *)generateKeyPairHex {
    @autoreleasepool {
        // 随机一个n阶长度的大数
        ZZBigInt *rng = [[ZZBigInt alloc] initWithRandomBits:(int)[_n bitLength]];
        // 求d
        ZZBigInt *d = [[rng modByBigInt:[_n subByBigInt:[ZZBigInt one]]] addByBigInt:[ZZBigInt one]];
        // d补齐64位长度作为私钥
        NSString *privateKey = [ZZSM2Util leftPad:[d toString:16] num:64];
        
        // 私钥导出公钥
        ZZECPointFp *p = [_g multiply:d];
        NSString *px = [ZZSM2Util leftPad:[[[p getX] toBigInteger] toString:16] num:64];
        NSString *py = [ZZSM2Util leftPad:[[[p getY] toBigInteger] toString:16] num:64];
        NSString *publicKey = [NSString stringWithFormat:@"04%@%@", px, py];
        
        NSMutableDictionary *resDict = [NSMutableDictionary dictionaryWithCapacity:2];
        if ([publicKey isKindOfClass:[NSString class]] && publicKey.length > 0) {
            [resDict setObject:publicKey forKey:@"publicKey"];
        }
        if ([privateKey isKindOfClass:[NSString class]] && privateKey.length > 0) {
            [resDict setObject:privateKey forKey:@"privateKey"];
        }
        
        return [resDict copy];
    }
}

#pragma mark - Private

- (NSUInteger)getPointLen {
    return self.curve.pointLen;
}

- (ZZBigInt *)randomBigIntegerK {
    @autoreleasepool {
        // 随机一个n阶长度的大数
        ZZBigInt *rng = [[ZZBigInt alloc] initWithRandomBits:(int)[_n bitLength]];
        // 求d
        ZZBigInt *d = [[rng modByBigInt:[_n subByBigInt:[ZZBigInt one]]] addByBigInt:[ZZBigInt one]];
        return d;
    }
}

- (ZZECPointFp *)kG:(ZZBigInt *)k {
    @autoreleasepool {
        ZZECPointFp *kG = [_g multiply:k];
        return kG;
    }
}

- (ZZECPointFp *)kP:(ZZBigInt *)k PPoint:(ZZECPointFp *)pPoint {
    @autoreleasepool {
        ZZECPointFp *kPoint = [pPoint multiply:k];
        return kPoint;
    }
}

- (ZZECPointFp *)kP:(ZZBigInt *)k PPointHex:(NSString *)pPointHex {
    @autoreleasepool {
        ZZECPointFp *pPoint = [self.curve decodePointHex:[NSString stringWithFormat:@"04%@", pPointHex]];
        ZZECPointFp *kPoint = [pPoint multiply:k];
        return kPoint;
    }
}


@end
