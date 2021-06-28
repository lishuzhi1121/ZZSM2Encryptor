//
//  ZZSM2Encryptor.m
//  ZZSM2Encryptor
//
//  Created by SandsLee on 2021/6/28.
//

#import "ZZSM2Encryptor.h"
#import "ZZSM2Cipher+Private.h"
#import "ZZECPointFp.h"
#import "ZZECCurveFp.h"
#import "ZZECFieldElementFp.h"
#import "ZZBigInt.h"
#import "ZZSM3Digest.h"

@implementation ZZSM2Encryptor

#pragma mark - SM2密钥生成

+ (NSDictionary *)generateSM2KeyPairHex {
    return [[ZZSM2Cipher EC_Fp_SM2_256V1] generateKeyPairHex];
}

+ (NSDictionary *)generateSM2KeyPairHexByCipher:(ZZSM2Cipher *)cipher {
    return [cipher generateKeyPairHex];
}

#pragma mark - SM2加解密

+ (NSData *)sm2Encrypt:(NSData *)plainData publicKey:(NSString *)publicKey {
    ZZSM2Cipher *cipher = [ZZSM2Cipher EC_Fp_SM2_256V1];
    return [ZZSM2Encryptor sm2Encrypt:plainData
                            publicKey:publicKey
                               cipher:cipher
                                 mode:ZZSM2CipherModeC1C2C3];
}

+ (NSData *)sm2Decrypt:(NSData *)cipherData privateKey:(NSString *)privateKey {
    ZZSM2Cipher *cipher = [ZZSM2Cipher EC_Fp_SM2_256V1];
    return [ZZSM2Encryptor sm2Decrypt:cipherData
                           privateKey:privateKey
                               cipher:cipher
                                 mode:ZZSM2CipherModeC1C2C3];
}

/* ------------------------------------------
 加密算法
 设需要发送的消息为比特串M，klen为M的比特长度。
 为了对明文M 进行加密，作为加密者的用户A应实现以下运算步骤:
 A1:用随机数发生器产生随机数k∈[1,n-1];
 A2:计算椭圆曲线点C1=[k]G=(x1,y1)，将C1的数据类型转换为比特串;
 A3:计算椭圆曲线点S=[h]PB ，若S是无穷远点，则报错并退出;
 A4:计算椭圆曲线点[k]PB=(x2,y2)，将坐标x2、y2 的数据类型转换为比特串;
 A5:计算t=KDF (x2 ∥ y2, klen)，若t为全0比特串，则返回A1;
 A6:计算C2 = M ⊕ t;
 A7:计算C3 = Hash(x2 ∥ M ∥ y2);
 A8:输出密文C = C1 ∥ C2 ∥ C3。
 --------------------------------------------- */

+ (NSData *)sm2Encrypt:(NSData *)plainData
             publicKey:(NSString *)publicKey
                cipher:(ZZSM2Cipher *)cipher
                  mode:(ZZSM2CipherMode)mode {
    if (![plainData isKindOfClass:[NSData class]] || plainData.length == 0) {
        return nil;
    }
    if (![publicKey isKindOfClass:[NSString class]] || publicKey.length == 0) {
        return nil;
    }
    
    BOOL repeat = NO;
    NSString *C1, *C2, *C3 = nil;
    
    do {
        repeat = NO;
        
        // 随机一个大数r
        ZZBigInt *r = [cipher randomBigIntegerK];
        
        // 🌟 C1 = 04 || rG (rG即点{x1, y1})
        ZZECPointFp *rGPoint = [cipher kG:r];
        NSUInteger pointLen = [cipher getPointLen];
        //x1
        NSString *rGPointX = [ZZSM2Util leftPad:[[[rGPoint getX] toBigInteger] toString:16] num:pointLen/2];
        //y1
        NSString *rGPointY = [ZZSM2Util leftPad:[[[rGPoint getY] toBigInteger] toString:16] num:pointLen/2];
        NSString *rG = [NSString stringWithFormat:@"%@%@", rGPointX, rGPointY];
        C1 = [NSString stringWithFormat:@"04%@", rG];
        
        // rQ (rQ即点{x2, y2})
        ZZECPointFp *rQPoint = [cipher kP:r PPointHex:publicKey];
        if (!rQPoint) { // TODO: 若S是无穷远点，则报错并退出
            return nil;
        }
        //x2
        NSString *rQPointX = [ZZSM2Util leftPad:[[[rQPoint getX] toBigInteger] toString:16] num:pointLen/2];
        //y2
        NSString *rQPointY = [ZZSM2Util leftPad:[[[rQPoint getY] toBigInteger] toString:16] num:pointLen/2];
        
        NSData *rQPointXData = [ZZSM2Util dataByHexString:rQPointX];
        NSData *rQPointYData = [ZZSM2Util dataByHexString:rQPointY];
        
        // t = KDF(x2y2, M_LEN)
        // 🌟 C2 = M⊕t （M异或t）
        NSMutableData *x2y2 = [NSMutableData dataWithData:rQPointXData];
        [x2y2 appendData:rQPointYData];
        NSUInteger ml = plainData.length;
        NSData *t = [ZZSM3Digest KDF:[x2y2 copy] keylen:(int)ml];
        NSString *tHex = [ZZSM2Util hexStringByData:t];
        ZZBigInt *tBigInt = [[ZZBigInt alloc] initWithString:tHex radix:16];
        if ([tBigInt compare:[ZZBigInt zero]] == NSOrderedSame) {
            repeat = YES;
            continue;
        }
        NSString *plainHex = [ZZSM2Util hexStringByData:plainData];
        ZZBigInt *plainBigInt = [[ZZBigInt alloc] initWithString:plainHex radix:16];
        C2 = [[plainBigInt bitwiseXorByBigInt:tBigInt] toString:16];
        C2 = [ZZSM2Util leftPad:C2 num:ml*2];
        
        // 🌟 C3 = hash(rQPointX+M+rQPointY)
        NSMutableData *x2My2 = [NSMutableData dataWithData:rQPointXData];
        [x2My2 appendData:plainData];
        [x2My2 appendData:rQPointYData];
        
        NSData *hash_x2My2 = [ZZSM3Digest hashData:[x2My2 copy]];
        C3 = [ZZSM2Util hexStringByData:hash_x2My2];
        
    } while (repeat);
    
    NSString *C = nil;
    if (mode == ZZSM2CipherModeC1C2C3) {
        C = [NSString stringWithFormat:@"%@%@%@", C1, C2, C3];
    } else {
        C = [NSString stringWithFormat:@"%@%@%@", C1, C3, C2];
    }
    NSLog(@"#### SM2 Encrypted: %@", C);
    return [ZZSM2Util dataByHexString:C];
}

/* ------------------------------------------
 解密算法
 设klen为密文中C2的比特长度。
 为了对密文C=C1 ∥ C2 ∥ C3 进行解密，作为解密者的用户B应实现以下运算步骤:
 B1:从C中取出比特串C1，将C1的数据类型转换为椭圆曲线上的点，验证C1是否满足椭圆曲线方程，若不满足则报错并退出;
 B2:计算椭圆曲线点S=[h]C1，若S是无穷远点，则报错并退出;
 B3:计算[dB]C1=(x2,y2)，将坐标x2、y2的数据类型转换为比特串;
 B4:计算t=KDF (x2 ∥ y2, klen)，若t为全0比特串，则报错并退出;
 B5:从C中取出比特串C2，计算M ′ = C2 ⊕ t;
 B6:计算u = Hash(x2 ∥ M′ ∥ y2)，从C中取出比特串C3，若u != C3，则报错并退出;
 B7:输出明文M ′。
 --------------------------------------------- */

+ (NSData *)sm2Decrypt:(NSData *)cipherData
            privateKey:(NSString *)privateKey
                cipher:(ZZSM2Cipher *)cipher
                  mode:(ZZSM2CipherMode)mode {
    if (![cipherData isKindOfClass:[NSData class]] || cipherData.length <= 1) {
        return nil;
    }
    if (![privateKey isKindOfClass:[NSString class]] || privateKey.length == 0) {
        return nil;
    }
    
    NSUInteger pointLen = [cipher getPointLen];
    ZZBigInt *k = [[ZZBigInt alloc] initWithString:privateKey radix:16];
    
    NSData *cipherDataHead = [cipherData subdataWithRange:NSMakeRange(0, 1)];
    
    //提取rG (不能直接拿C1当做rG, 因为可能被压缩过)
    NSUInteger C1_Len = 0;
    ZZECPointFp *rGPoint = nil;
    uint8_t head;
    memcpy(&head, [cipherDataHead bytes], 1);
    switch (head) {
        case 2:
        case 3:
        {
            // 压缩过的点
            C1_Len = 1 + pointLen / 4;
            NSData *C1 = [cipherData subdataWithRange:NSMakeRange(0, C1_Len)];
            rGPoint = [cipher.curve decodePointHex:[ZZSM2Util hexStringByData:C1]];
        }
            break;
        case 4:
        case 6:
        case 7:
        {
            // 未压缩的点
            C1_Len = 1 + pointLen / 2;
            NSData *C1 = [cipherData subdataWithRange:NSMakeRange(0, C1_Len)];
            rGPoint = [cipher.curve decodePointHex:[ZZSM2Util hexStringByData:C1]];
        }
            break;
            
        default:
            break;
    }
    // C1 提取失败
    if (!rGPoint) {
        return nil;
    }
    
    NSUInteger cipherLen = cipherData.length;
    // C3就是一个ZZSM3_HASH_SIZE长度, 所以密文长度肯定不能小于 C1+C3 的长度
    if (cipherLen < C1_Len + ZZSM3_HASH_SIZE) {
        return nil;
    }
    
    NSRange rangeC2, rangeC3;
    if (mode == ZZSM2CipherModeC1C2C3) {
        // C = C1 || C2 || C3
        rangeC3.location = cipherLen - ZZSM3_HASH_SIZE;
        rangeC3.length = ZZSM3_HASH_SIZE;
        
        rangeC2.location = C1_Len;
        rangeC2.length = cipherLen - C1_Len - ZZSM3_HASH_SIZE;
        
    } else {
        // C = C1 || C3 || C2
        rangeC3.location = C1_Len;
        rangeC3.length = ZZSM3_HASH_SIZE;
        
        rangeC2.location = C1_Len + ZZSM3_HASH_SIZE;
        rangeC2.length = cipherLen - C1_Len - ZZSM3_HASH_SIZE;
    }
    
    NSData *C2 = [cipherData subdataWithRange:rangeC2];
    NSString *C2Hex = [ZZSM2Util hexStringByData:C2];
    NSData *C3 = [cipherData subdataWithRange:rangeC3];
    NSString *C3Hex = [ZZSM2Util hexStringByData:C3];
    
    // k*C1
    ZZECPointFp *kC1Point = [cipher kP:k PPoint:rGPoint];
    // x2
    NSString *kC1PointX = [ZZSM2Util leftPad:[[[kC1Point getX] toBigInteger] toString:16] num:pointLen / 2];
    // y2
    NSString *kC1PointY = [ZZSM2Util leftPad:[[[kC1Point getY] toBigInteger] toString:16] num:pointLen / 2];
    NSString *kC1 = [NSString stringWithFormat:@"%@%@", kC1PointX, kC1PointY];
    NSLog(@"#### kC1: %@", kC1);
    
    NSData *kC1PointXData = [ZZSM2Util dataByHexString:kC1PointX];
    NSData *kC1PointYData = [ZZSM2Util dataByHexString:kC1PointY];
    NSData *kC1Data = [ZZSM2Util dataByHexString:kC1];
    
    // 计算t=KDF (x2 ∥ y2, klen)
    NSUInteger ml = C2.length;
    NSData *tData = [ZZSM3Digest KDF:kC1Data keylen:(int)ml];
    NSString *tHex = [ZZSM2Util hexStringByData:tData];
    ZZBigInt *t = [[ZZBigInt alloc] initWithString:tHex radix:16];
    if ([t compare:[ZZBigInt zero]] == NSOrderedSame) {
        return nil;
    }
    
    // 计算M′ = C2 ⊕ t
    ZZBigInt *C2BigInt = [[ZZBigInt alloc] initWithString:C2Hex radix:16];
    ZZBigInt *plainBitInt = [C2BigInt bitwiseXorByBigInt:t];
    NSString *plainHex = [ZZSM2Util leftPad:[plainBitInt toString:16] num:ml * 2];
    NSData *plainData = [ZZSM2Util dataByHexString:plainHex];
    
    // 计算u = Hash(x2 ∥ M′ ∥ y2)
    NSMutableData *x2_Mt_y2 = [NSMutableData dataWithData:kC1PointXData];
    [x2_Mt_y2 appendData:plainData];
    [x2_Mt_y2 appendData:kC1PointYData];
    
    NSData *C3_t = [ZZSM3Digest hashData:[x2_Mt_y2 copy]];
    NSString *C3_tHex = [ZZSM2Util hexStringByData:C3_t];
    
    // 若u != C3，则报错并退出
    if (![C3_tHex.lowercaseString isEqualToString:C3Hex.lowercaseString]) {
        return nil;
    }
    // 输出明文M‘
    return plainData;
}


#pragma mark - SM2数字签名与验签

/* ------------------------------------------
 数字签名的生成算法
 设待签名的消息为M，为了获取消息M的数字签名(r,s)，作为签名者的用户A应实现以下运算步骤:
 A1:置M'=ZA ∥ M;  // ZA:关于用户A的可辨别标识、部分椭圆曲线系统参数和用户A公钥的杂凑值
 A2:计算e = Hv(M')，将e的数据类型转换为整数; // Hv( ):消息摘要长度为v比特的密码杂凑函数
 A3:用随机数发生器产生随机数k ∈[1,n-1];
 A4:计算椭圆曲线点(x1,y1)=[k]G，将x1的数据类型转换为整数;
 A5:计算r=(e+x1) modn，若r=0或r+k=n则返回A3;
 A6:计算s = ((1 + dA)^−1 · (k − r · dA)) modn，若s=0则返回A3;
 A7:将r、s的数据类型转换为字节串，消息M 的签名为(r,s)。
 --------------------------------------------- */

+ (NSData *)sm2Sign:(NSData *)srcData
             userId:(NSString *)userId
         privateKey:(NSString *)privateKey
             cipher:(ZZSM2Cipher *)cipher {
    if (![srcData isKindOfClass:[NSData class]] || srcData.length == 0) {
        return nil;
    }
    if (![privateKey isKindOfClass:[NSString class]] || privateKey.length == 0) {
        return nil;
    }
    
    @autoreleasepool {
        NSString *rHex, *sHex = nil;
        
        NSData *userIdData = [userId dataUsingEncoding:NSUTF8StringEncoding];
        NSString *userIdHex = [ZZSM2Util hexStringByData:userIdData];
        NSString *ENTL_A = [NSString stringWithFormat:@"%lx", userIdData.length * 8];
        ENTL_A = [ZZSM2Util leftPad:ENTL_A num:4];
        
        // 公钥 = 私钥*G
        ZZBigInt *dA = [[ZZBigInt alloc] initWithString:privateKey radix:16];
        ZZECPointFp *PPonit = [cipher kG:dA];
        NSUInteger pointLen = [cipher getPointLen];
        NSString *Px = [ZZSM2Util leftPad:[[[PPonit getX] toBigInteger] toString:16] num:pointLen / 2];
        NSString *Py = [ZZSM2Util leftPad:[[[PPonit getY] toBigInteger] toString:16] num:pointLen / 2];
        
        // ZA = Hash(ENTL_A || userId || a || b || Gx || Gy || Px || Py)
        NSMutableString *ZAStr = [NSMutableString string];
        [ZAStr appendString:ENTL_A];
        [ZAStr appendString:userIdHex];
        [ZAStr appendString:cipher.aHex];
        [ZAStr appendString:cipher.bHex];
        [ZAStr appendString:cipher.gxHex];
        [ZAStr appendString:cipher.gyHex];
        [ZAStr appendString:Px];
        [ZAStr appendString:Py];
        
        NSData *ZAHashData = [ZZSM3Digest hashData:[ZAStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        // M' = ZA || M
        NSMutableData *Mt = [NSMutableData dataWithData:ZAHashData];
        [Mt appendData:srcData];
        
        // e = H256(M')
        NSData *MtHash = [ZZSM3Digest hashData:[Mt copy]];
        NSString *MtHex = [ZZSM2Util hexStringByData:MtHash];
        ZZBigInt *e = [[ZZBigInt alloc] initWithString:MtHex radix:16];
        
        BOOL repeat = NO;
        do {
            repeat = NO;
            // 随机数k
            ZZBigInt *k = [cipher randomBigIntegerK];
            ZZECPointFp *kGPoint = [cipher kG:k];
            // x1
            NSUInteger pointLen = [cipher getPointLen];
            NSString *kGPointX = [ZZSM2Util leftPad:[[[kGPoint getX] toBigInteger] toString:16] num:pointLen / 2];
            ZZBigInt *kX = [[ZZBigInt alloc] initWithString:kGPointX radix:16];
            
            // r=(e+x1) mod n
            ZZBigInt *r = [[e addByBigInt:kX] modByBigInt:cipher.n];
            // 若r=0或r+k=n则返回A3
            if (([r compare:[ZZBigInt zero]] == NSOrderedSame) ||
                ([[r addByBigInt:k] compare:cipher.n] == NSOrderedSame)) {
                repeat = YES;
                continue;
            }
            
            rHex = [ZZSM2Util leftPad:[r toString:16] num:pointLen / 2];
            
            // s = ((1 + dA)^−1 · (k − r · dA)) mod n
            ZZBigInt *t1 = [[[ZZBigInt one] addByBigInt:dA] pow:[[ZZBigInt alloc] initWithInt:-1] mod:cipher.n];
            ZZBigInt *t2 = [k subByBigInt:[r multiplyByBigInt:dA]];
            ZZBigInt *s = [[t1 multiplyByBigInt:t2] modByBigInt:cipher.n];
            // 若s=0则返回A3
            if ([s compare:[ZZBigInt zero]] == NSOrderedSame) {
                repeat = YES;
                continue;
            }
            
            sHex = [ZZSM2Util leftPad:[s toString:16] num:pointLen / 2];
            
        } while (repeat);
        
        return [ZZSM2Util dataByHexString:[NSString stringWithFormat:@"%@%@", rHex, sHex]];
    }
    
}

/* ------------------------------------------
 数字签名的验证算法
 为了检验收到的消息M′及其数字签名(r′, s′)，作为验证者的用户B应实现以下运算步骤:
 B1:检验r′ ∈[1,n-1]是否成立，若不成立则验证不通过;
 B2:检验s′ ∈[1,n-1]是否成立，若不成立则验证不通过;
 B3:置M′=ZA ∥ M′;
 B4:计算e′ = Hv(M′)，将e′的数据类型转换为整数;
 B5:将r′、s′的数据类型转换为整数，计算t = (r′ + s′) modn， 若t = 0，则验证不通过;
 B6:计算椭圆曲线点(x1′, y1′ )=[s′]G + [t]PA;
 B7:将x1′的数据类型转换为整数，计算R = (e′ + x1′) modn，检验R=r′是否成立，若成立则验证通过;否则验证不通过。
 --------------------------------------------- */

+ (BOOL)sm2Verify:(NSData *)srcData
           userId:(NSString *)userId
        publicKey:(NSString *)publicKey
           cipher:(ZZSM2Cipher *)cipher
             sign:(NSData *)sign {
    if (![srcData isKindOfClass:[NSData class]] || srcData.length == 0) {
        return NO;
    }
    if (![publicKey isKindOfClass:[NSString class]] || publicKey.length == 0) {
        return NO;
    }
    if (![sign isKindOfClass:[NSData class]] || sign.length == 0) {
        return NO;
    }
    
    @autoreleasepool {
        ZZBigInt *n_1 = [cipher.n subByBigInt:[ZZBigInt one]];
        
        NSString *signHex = [ZZSM2Util hexStringByData:sign];
        NSUInteger len = signHex.length / 2;
        NSString *rtHex = [signHex substringWithRange:NSMakeRange(0, len)];
        ZZBigInt *rt = [[ZZBigInt alloc] initWithString:rtHex radix:16];
        // 检验r′ ∈[1,n-1]是否成立
        if ([rt compare:[ZZBigInt one]] == NSOrderedDescending
            || [rt compare:n_1] == NSOrderedAscending) {
            return NO;
        }
        // 检验s′ ∈[1,n-1]是否成立
        NSString *stHex = [signHex substringWithRange:NSMakeRange(len, len)];
        ZZBigInt *st = [[ZZBigInt alloc] initWithString:stHex radix:16];
        if ([st compare:[ZZBigInt one]] == NSOrderedDescending
            || [st compare:n_1] == NSOrderedAscending) {
            return NO;
        }
        
        NSData *userIdData = [userId dataUsingEncoding:NSUTF8StringEncoding];
        NSString *userIdHex = [ZZSM2Util hexStringByData:userIdData];
        NSString *ENTL_A = [NSString stringWithFormat:@"%lx", userIdData.length * 8];
        ENTL_A = [ZZSM2Util leftPad:ENTL_A num:4];
        
        // 公钥
        NSUInteger pointLen = [cipher getPointLen];
        len = publicKey.length / 2;
        NSString *Px = [ZZSM2Util leftPad:[publicKey substringWithRange:NSMakeRange(0, len)]
                                       num:pointLen / 2];
        NSString *Py = [ZZSM2Util leftPad:[publicKey substringWithRange:NSMakeRange(len, len)]
                                       num:pointLen / 2];
        // ZA = Hash(ENTL_A || userId || a || b || Gx || Gy || Px || Py)
        NSMutableString *ZAStr = [NSMutableString string];
        [ZAStr appendString:ENTL_A];
        [ZAStr appendString:userIdHex];
        [ZAStr appendString:cipher.aHex];
        [ZAStr appendString:cipher.bHex];
        [ZAStr appendString:cipher.gxHex];
        [ZAStr appendString:cipher.gyHex];
        [ZAStr appendString:Px];
        [ZAStr appendString:Py];
        
        NSData *ZAHashData = [ZZSM3Digest hashData:[ZAStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        // M' = ZA || M'
        NSMutableData *Mt = [NSMutableData dataWithData:ZAHashData];
        [Mt appendData:srcData];
        
        // e = H256(M')
        NSData *MtHash = [ZZSM3Digest hashData:[Mt copy]];
        NSString *MtHex = [ZZSM2Util hexStringByData:MtHash];
        ZZBigInt *e = [[ZZBigInt alloc] initWithString:MtHex radix:16];
        
        // 计算t = (r′ + s′) modn
        ZZBigInt *t = [[rt addByBigInt:st] modByBigInt:cipher.n];
        // 若t = 0，则验证不通过
        if ([t compare:[ZZBigInt zero]] == NSOrderedSame) {
            return NO;
        }
        
        // 计算椭圆曲线点(x1′, y1′ )=[s′]G + [t]PA
        ZZECPointFp *stGPoint = [cipher kG:st];
        ZZECPointFp *tPPoint = [cipher kP:t PPointHex:publicKey];
        ZZECPointFp *point = [stGPoint add:tPPoint];
        ZZBigInt *x = [[point getX] toBigInteger];
        
        // 计算R = (e′ + x1′) mod n
        ZZBigInt *R = [[e addByBigInt:x] modByBigInt:cipher.n];
        
        // 检验R=r′是否成立
        return [R compare:rt] == NSOrderedSame;
    }
}


#pragma mark - SM3哈希

+ (NSData *)sm3HashWithString:(NSString *)message {
    if ([message isKindOfClass:[NSString class]] && message.length > 0) {
        NSData *msgData = [message dataUsingEncoding:NSUTF8StringEncoding];
        return [ZZSM3Digest hashData:msgData];
    }
    return nil;
}

+ (NSData *)sm3HashWithData:(NSData *)data {
    return [ZZSM3Digest hashData:data];
}

@end
