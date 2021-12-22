//
//  ZZSM4Encryptor.m
//  ZZSM2Encryptor
//
//  Created by SandsLee on 2021/12/17.
//

#import "ZZSM4Encryptor.h"
#import "ZZSM2Util.h"

namespace com
{
    namespace zzspace
    {
        namespace sm4
        {
            /**
             32-bit integer manipulation macros (big endian)
             32位整型转为字节序（大端模式）
             */
            #ifndef SM4_GET_ULONG_BE
            #define SM4_GET_ULONG_BE(n,b,i)                         \
            {                                                       \
                (n) = ( (unsigned long) (b)[(i)    ] << 24 )        \
                    | ( (unsigned long) (b)[(i) + 1] << 16 )        \
                    | ( (unsigned long) (b)[(i) + 2] <<  8 )        \
                    | ( (unsigned long) (b)[(i) + 3]       );       \
            }
            #endif
            
            /**
             32-bit integer manipulation macros (big endian)
             字节序转为32位整型（大端模式）
             */
            #ifndef SM4_SET_ULONG_BE
            #define SM4_SET_ULONG_BE(n,b,i)                         \
            {                                                       \
                (b)[(i)    ] = (unsigned char) ( (n) >> 24 );       \
                (b)[(i) + 1] = (unsigned char) ( (n) >> 16 );       \
                (b)[(i) + 2] = (unsigned char) ( (n) >>  8 );       \
                (b)[(i) + 3] = (unsigned char) ( (n)       );       \
            }
            #endif
            
            /**
             向左循环移位
             */
            #define SM4_Left_Rotate(word, bits)                     \
                    ( (word) << (bits) | (word) >> (32 - (bits)) )
            
            #define SM4_SWAP(a,b) { unsigned long t = a; a = b; b = t; t = 0; }
            
            /**
             context 模式定义
             */
            typedef int SM4ContextMode;
            SM4ContextMode SM4ContextModeEncrypt = 0;
            SM4ContextMode SM4ContextModeDecrypt = 1;
        
            /**
             SM4分组密码算法context结构体定义
             mode: 当前context用于加密还是解密
             sk: 加密/解密的轮密钥
             */
            typedef struct {
                SM4ContextMode mode;        /*!<  encrypt/decrypt   */
                unsigned long sk[32];       /*!<  SM4 subkeys       */
            } SM4Context;
            
            #pragma mark - 常量定义
            /**
             Expanded SM4 S-boxes
             Sbox table: 8bits input convert to 8 bits output
             */
            static const unsigned char SboxTable[16][16] = {
                {0xd6,0x90,0xe9,0xfe,0xcc,0xe1,0x3d,0xb7,0x16,0xb6,0x14,0xc2,0x28,0xfb,0x2c,0x05},
                {0x2b,0x67,0x9a,0x76,0x2a,0xbe,0x04,0xc3,0xaa,0x44,0x13,0x26,0x49,0x86,0x06,0x99},
                {0x9c,0x42,0x50,0xf4,0x91,0xef,0x98,0x7a,0x33,0x54,0x0b,0x43,0xed,0xcf,0xac,0x62},
                {0xe4,0xb3,0x1c,0xa9,0xc9,0x08,0xe8,0x95,0x80,0xdf,0x94,0xfa,0x75,0x8f,0x3f,0xa6},
                {0x47,0x07,0xa7,0xfc,0xf3,0x73,0x17,0xba,0x83,0x59,0x3c,0x19,0xe6,0x85,0x4f,0xa8},
                {0x68,0x6b,0x81,0xb2,0x71,0x64,0xda,0x8b,0xf8,0xeb,0x0f,0x4b,0x70,0x56,0x9d,0x35},
                {0x1e,0x24,0x0e,0x5e,0x63,0x58,0xd1,0xa2,0x25,0x22,0x7c,0x3b,0x01,0x21,0x78,0x87},
                {0xd4,0x00,0x46,0x57,0x9f,0xd3,0x27,0x52,0x4c,0x36,0x02,0xe7,0xa0,0xc4,0xc8,0x9e},
                {0xea,0xbf,0x8a,0xd2,0x40,0xc7,0x38,0xb5,0xa3,0xf7,0xf2,0xce,0xf9,0x61,0x15,0xa1},
                {0xe0,0xae,0x5d,0xa4,0x9b,0x34,0x1a,0x55,0xad,0x93,0x32,0x30,0xf5,0x8c,0xb1,0xe3},
                {0x1d,0xf6,0xe2,0x2e,0x82,0x66,0xca,0x60,0xc0,0x29,0x23,0xab,0x0d,0x53,0x4e,0x6f},
                {0xd5,0xdb,0x37,0x45,0xde,0xfd,0x8e,0x2f,0x03,0xff,0x6a,0x72,0x6d,0x6c,0x5b,0x51},
                {0x8d,0x1b,0xaf,0x92,0xbb,0xdd,0xbc,0x7f,0x11,0xd9,0x5c,0x41,0x1f,0x10,0x5a,0xd8},
                {0x0a,0xc1,0x31,0x88,0xa5,0xcd,0x7b,0xbd,0x2d,0x74,0xd0,0x12,0xb8,0xe5,0xb4,0xb0},
                {0x89,0x69,0x97,0x4a,0x0c,0x96,0x77,0x7e,0x65,0xb9,0xf1,0x09,0xc5,0x6e,0xc6,0x84},
                {0x18,0xf0,0x7d,0xec,0x3a,0xdc,0x4d,0x20,0x79,0xee,0x5f,0x3e,0xd7,0xcb,0x39,0x48}
            };
            
            /**
             System parameter FK
             */
            static const unsigned long FK[4] = {
                0xa3b1bac6, 0x56aa3350, 0x677d9197, 0xb27022dc
            };
            
            /**
             Const parameter CK
             */
            static const unsigned long CK[32] = {
                0x00070e15,0x1c232a31,0x383f464d,0x545b6269,
                0x70777e85,0x8c939aa1,0xa8afb6bd,0xc4cbd2d9,
                0xe0e7eef5,0xfc030a11,0x181f262d,0x343b4249,
                0x50575e65,0x6c737a81,0x888f969d,0xa4abb2b9,
                0xc0c7ced5,0xdce3eaf1,0xf8ff060d,0x141b2229,
                0x30373e45,0x4c535a61,0x686f767d,0x848b9299,
                0xa0a7aeb5,0xbcc3cad1,0xd8dfe6ed,0xf4fb0209,
                0x10171e25,0x2c333a41,0x484f565d,0x646b7279
            };
            
            #pragma mark - 函数定义
            void SM4SetKey(unsigned long SK[32], unsigned char key[16]);
            unsigned long SM4CalculateRki(unsigned long ka);
            unsigned char SM4Sbox(unsigned char inch);
            
            void SM4OneRoundCrypt(unsigned long sk[32], unsigned char input[16], unsigned char output[16]);
            unsigned long SM4F(unsigned long x0, unsigned long x1, unsigned long x2, unsigned long x3, unsigned long rk);
            unsigned long SM4Lt(unsigned long ka);
        
            #pragma mark - 函数实现
        
            #pragma mark - 密钥设置
            
            /// 设置加密密钥
            /// @param ctx context
            void SM4SetEncryptKey(SM4Context *ctx, unsigned char key[16]) {
                ctx->mode = SM4ContextModeEncrypt;
                SM4SetKey(ctx->sk, key);
            }
            
            /// 设置解密密钥
            /// @param ctx context
            void SM4SetDecryptKey(SM4Context *ctx, unsigned char key[16]) {
                ctx->mode = SM4ContextModeDecrypt;
                SM4SetKey(ctx->sk, key);
                // 解密时轮密钥需要反转
                for (int i = 0; i < 16; i++) {
                    SM4_SWAP(ctx->sk[i], ctx->sk[31-i]);
                }
            }
            
            /// 密钥扩展
            void SM4SetKey(unsigned long SK[32], unsigned char key[16]) {
                // 加密密钥MK=(MK0, MK1, MK2, MK3)，MKi∈ Z 32 ，i=0,1,2,3;
                unsigned long MK[4];
                unsigned long k[36];
                
                // 将传入的密钥key表示为加密密钥MK
                SM4_GET_ULONG_BE(MK[0], key, 0);
                SM4_GET_ULONG_BE(MK[1], key, 4);
                SM4_GET_ULONG_BE(MK[2], key, 8);
                SM4_GET_ULONG_BE(MK[3], key, 12);
                // (K0,K1,K2,K3)=(MK0^FK0,MK1^FK1,MK2^FK2,MK3^FK3)
                k[0] = MK[0] ^ FK[0];
                k[1] = MK[1] ^ FK[1];
                k[2] = MK[2] ^ FK[2];
                k[3] = MK[3] ^ FK[3];
                // 轮密钥为 rk ∈ Z 32 , i = 0 ,1,..., 31
                // 对i = 0,1,2,..., 31
                // rki =Ki+4 =Ki ^ T′(Ki+1 ^ Ki+2 ^ Ki+3 ^ CKi)
                for (int i = 0; i < 32; i++) {
                    k[i+4] = k[i] ^ SM4CalculateRki(k[i+1] ^ k[i+2] ^ k[i+3] ^ CK[i]);
                    SK[i] = k[i+4];
                }
            }
            
            // 计算密钥扩展中的T‘
            unsigned long SM4CalculateRki(unsigned long ka) {
                unsigned char a[4];
                unsigned char b[4];
                unsigned long bb;
                unsigned long rk;
                // 将unsigned long 转为字节序
                SM4_SET_ULONG_BE(ka, a, 0);
                // 查SBox得到b0...b3
                b[0] = SM4Sbox(a[0]);
                b[1] = SM4Sbox(a[1]);
                b[2] = SM4Sbox(a[2]);
                b[3] = SM4Sbox(a[3]);
                // 将字节序转为unsigned long
                SM4_GET_ULONG_BE(bb, b, 0);
                // T'变换与加密算法轮函数中的T基本相同，只将其中的线性变换L修改为以下L':
                // L'(B)=B ^ (B <<< 13) ^ (B <<< 23)
                rk = bb ^ (SM4_Left_Rotate(bb, 13)) ^ (SM4_Left_Rotate(bb, 23));
                return rk;
            }
            
            // 查SBox
            unsigned char SM4Sbox(unsigned char inch) {
                unsigned char *sbox = (unsigned char *)SboxTable;
                unsigned char retVal = (unsigned char)(sbox[inch]);
                return retVal;
            }
        
            #pragma mark - 加解密
            void SM4CryptECB(SM4Context ctx, unsigned char *input, int length, unsigned char *output) {
                while (length > 0) {
                    SM4OneRoundCrypt(ctx.sk, input, output);
                    input += 16;
                    output += 16;
                    length -= 16;
                }
            }
            
            void SM4CryptCBC(SM4Context ctx, unsigned char iv[16], unsigned char *input, int length, unsigned char *output) {
                
                int i = 0;
                unsigned char tempIV[16] = {0};
                unsigned char temp[16] = {0};
                // 由于iv在每轮计算中会发生变化,同时传进来的又是一个指针,
                // 所以为了不影响外部iv的复用,这里做一个copy,每次计算用copy后的变量做迭代
                memcpy(tempIV, iv, 16);
                
                if (ctx.mode == SM4ContextModeEncrypt) {
                    while (length > 0) {
                        // iv 向量异或
                        for (i = 0; i < 16; i++) {
                            temp[i] = (unsigned char)(input[i] ^ tempIV[i]);
                        }
                        // 一轮加密
                        SM4OneRoundCrypt(ctx.sk, temp, output);
                        
                        // 将输出作为下一轮的iv向量
                        memcpy(tempIV, output, 16);
                        
                        input  += 16;
                        output += 16;
                        length -= 16;
                    }
                    
                } else if (ctx.mode == SM4ContextModeDecrypt) {
                    while (length > 0) {
                        // 保存原始输入
                        memcpy(temp, input, 16);
                        
                        SM4OneRoundCrypt(ctx.sk, input, output);
                        
                        // iv 向量异或
                        for (i = 0; i < 16; i++) {
                            output[i] = (unsigned char)(output[i] ^ tempIV[i]);
                        }
                        
                        // 将原始输入作为下一轮的iv向量
                        memcpy(tempIV, temp, 16);
                        
                        input  += 16;
                        output += 16;
                        length -= 16;
                    }
                }
            }
            
            /// 一轮分组加密
            void SM4OneRoundCrypt(unsigned long sk[32], unsigned char input[16], unsigned char output[16]) {
                unsigned long ulbuff[36];
                unsigned long i = 0;
                
                memset(ulbuff, 0, sizeof(ulbuff));
                SM4_GET_ULONG_BE(ulbuff[0], input, 0);
                SM4_GET_ULONG_BE(ulbuff[1], input, 4);
                SM4_GET_ULONG_BE(ulbuff[2], input, 8);
                SM4_GET_ULONG_BE(ulbuff[3], input, 12);
                
                while (i < 32) {
                    ulbuff[i+4] = SM4F(ulbuff[i], ulbuff[i+1], ulbuff[i+2], ulbuff[i+3], sk[i]);
                    
                    i++;
                }
                
                SM4_SET_ULONG_BE(ulbuff[35], output, 0);
                SM4_SET_ULONG_BE(ulbuff[34], output, 4);
                SM4_SET_ULONG_BE(ulbuff[33], output, 8);
                SM4_SET_ULONG_BE(ulbuff[32], output, 12);
                
            }
            
            // 轮函数 F
            unsigned long SM4F(unsigned long x0, unsigned long x1, unsigned long x2, unsigned long x3, unsigned long rk) {
                return (x0 ^ SM4Lt(x1 ^ x2 ^ x3 ^ rk));
            }
            
            // 线性变换 L
            unsigned long SM4Lt(unsigned long ka) {
                unsigned char a[4];
                unsigned char b[4];
                unsigned long bb;
                unsigned long c;
                // 将unsigned long 转为字节序
                SM4_SET_ULONG_BE(ka, a, 0);
                // 查SBox得到b0...b3
                b[0] = SM4Sbox(a[0]);
                b[1] = SM4Sbox(a[1]);
                b[2] = SM4Sbox(a[2]);
                b[3] = SM4Sbox(a[3]);
                // 将字节序转为unsigned long
                SM4_GET_ULONG_BE(bb, b, 0);
                // 设输入为B∈Z32 ，输出为C∈Z32，则:
                // C = L(B) = B ^ (B <<< 2) ^ (B <<< 10) ^ (B <<< 18) ^ (B <<< 24)
                c = bb ^ (SM4_Left_Rotate(bb, 2)) ^ (SM4_Left_Rotate(bb, 10)) ^ (SM4_Left_Rotate(bb, 18)) ^ (SM4_Left_Rotate(bb, 24));
                return c;
            }
            
        }
    }
}

using namespace com::zzspace::sm4;


@implementation ZZSM4Encryptor

+ (NSData *)sm4EncryptText:(NSString *)plainText
                 keyString:(NSString *)keyString
                 cryptMode:(ZZSM4CryptMode)mode
              cryptPadding:(ZZSM4CryptPadding)padding
                optionalIV:(NSString *)ivString {
    NSParameterAssert([keyString isKindOfClass:[NSString class]] && keyString.length == 16);
    if (mode == ZZSM4CryptModeCBC) {
        NSParameterAssert([ivString isKindOfClass:[NSString class]] && ivString.length == 16);
    }
    if (![plainText isKindOfClass:[NSString class]] || plainText.length == 0) {
        return nil;
    }
    
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [keyString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [ivString dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self sm4Encrypt:plainData
                        key:keyData
                  cryptMode:mode
               cryptPadding:padding
                 optionalIV:ivData];
}

+ (NSData *)sm4DecryptText:(NSString *)hexCipherText
                 keyString:(NSString *)keyString
                 cryptMode:(ZZSM4CryptMode)mode
              cryptPadding:(ZZSM4CryptPadding)padding
                optionalIV:(NSString *)ivString {
    NSParameterAssert([keyString isKindOfClass:[NSString class]] && keyString.length == 16);
    if (mode == ZZSM4CryptModeCBC) {
        NSParameterAssert([ivString isKindOfClass:[NSString class]] && ivString.length == 16);
    }
    if (![hexCipherText isKindOfClass:[NSString class]] || hexCipherText.length == 0) {
        return nil;
    }
    
    NSData *cipherData = [ZZSM2Util dataByHexString:hexCipherText];
    NSData *keyData = [keyString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [ivString dataUsingEncoding:NSUTF8StringEncoding];
    
    return [self sm4Decrypt:cipherData
                        key:keyData
                  cryptMode:mode
               cryptPadding:padding
                 optionalIV:ivData];
}


+ (NSData *)sm4Encrypt:(NSData *)plainData
                   key:(NSData *)key
             cryptMode:(ZZSM4CryptMode)mode
          cryptPadding:(ZZSM4CryptPadding)padding
            optionalIV:(NSData *)iv {
    NSParameterAssert([key isKindOfClass:[NSData class]] && key.length == 16);
    if (mode == ZZSM4CryptModeCBC) {
        NSParameterAssert([iv isKindOfClass:[NSData class]] && iv.length == 16);
    }
    // 分组大小
    uint8_t blockSize = 16;
    
    NSData *paddedPlainData = [self _paddingForData:plainData
                                            padding:padding
                                          blockSize:blockSize];
    NSUInteger paddedPlainDataLength = paddedPlainData.length;
    // 存储加密结果
    unsigned char *cOutput = (unsigned char *)malloc(paddedPlainDataLength);
    
    // SM4
    SM4Context ctx;
    // 初始化context
    SM4SetEncryptKey(&ctx, (unsigned char *)key.bytes);
    
    if (mode == ZZSM4CryptModeECB) {
        SM4CryptECB(ctx,
                    (unsigned char *)paddedPlainData.bytes,
                    (int)paddedPlainDataLength,
                    cOutput);
    } else if (mode == ZZSM4CryptModeCBC) {
        if ([iv isKindOfClass:[NSData class]] && iv.length == 16) {
            SM4CryptCBC(ctx,
                        (unsigned char *)iv.bytes,
                        (unsigned char *)paddedPlainData.bytes,
                        (int)paddedPlainDataLength,
                        cOutput);
        }
    }
    // 加密结果
    NSData *cryptedData = [NSData dataWithBytes:cOutput length:paddedPlainDataLength];
    free(cOutput);
    
    return cryptedData;
}


+ (NSData *)sm4Decrypt:(NSData *)cipherData
                   key:(NSData *)key
             cryptMode:(ZZSM4CryptMode)mode
          cryptPadding:(ZZSM4CryptPadding)padding
            optionalIV:(NSData *)iv {
    NSParameterAssert([key isKindOfClass:[NSData class]] && key.length == 16);
    if (mode == ZZSM4CryptModeCBC) {
        NSParameterAssert([iv isKindOfClass:[NSData class]] && iv.length == 16);
    }
    
    // 密文长度
    NSUInteger cipherLength = cipherData.length;
    
    // 存储解密结果
    unsigned char *mOutput = (unsigned char *)malloc(cipherLength);
    
    // SM4
    SM4Context ctx;
    // 初始化context
    SM4SetDecryptKey(&ctx, (unsigned char *)key.bytes);
    
    if (mode == ZZSM4CryptModeECB) {
        SM4CryptECB(ctx,
                    (unsigned char *)cipherData.bytes,
                    (int)cipherLength,
                    mOutput);
    } else if (mode == ZZSM4CryptModeCBC) {
        if ([iv isKindOfClass:[NSData class]] && iv.length == 16) {
            SM4CryptCBC(ctx,
                        (unsigned char *)iv.bytes,
                        (unsigned char *)cipherData.bytes,
                        (int)cipherLength,
                        mOutput);
        }
    }
    
    // 解密结果
    NSData *plainData = [NSData dataWithBytes:mOutput length:cipherLength];
    free(mOutput);
    // 去除padding
    plainData = [self _unPaddingForData:plainData padding:padding];
    
    return plainData;
}

/// 根据填充模式进行分组填充
/// @param data 需要填充的数据
/// @param padding 填充模式
/// @param blockSize 分组大小
+ (NSData *)_paddingForData:(NSData *)data
                    padding:(ZZSM4CryptPadding)padding
                  blockSize:(uint8_t)blockSize {
    if (![data isKindOfClass:[NSData class]] || data.length == 0) {
        return nil;
    }
    NSUInteger remainderBits = data.length % (int)blockSize;
    if (remainderBits == 0) {
        // 如果数据本身已经是分组大小的整数倍了,则不需要进行padding
        return data;
    }
    // 用于填充的数据
    unsigned char tempPaddingData[16] = {0};
    // 获取需要补位的长度
    uint8_t paddingLength = blockSize - remainderBits;
    
    // fill data
    NSData *paddedData = nil;
    switch (padding) {
        case ZZSM4CryptPaddingNone:
        {
            paddedData = data;
            break;
        }
        case ZZSM4CryptPaddingZero:
        {
            memset(tempPaddingData, 0, paddingLength);
            NSMutableData *tmpData = [NSMutableData dataWithCapacity:data.length + paddingLength];
            [tmpData appendData:data];
            [tmpData appendBytes:tempPaddingData length:paddingLength];
            paddedData = tmpData;
            break;
        }
        case ZZSM4CryptPaddingPKCS5:
        case ZZSM4CryptPaddingPKCS7:
        {
            // PKCS5:只支持分组长度为8bytes的
            // PKCS7:支持分组长度1-128bytes
            memset(tempPaddingData, paddingLength, paddingLength);
            NSMutableData *tmpData = [NSMutableData dataWithCapacity:data.length + paddingLength];
            [tmpData appendData:data];
            [tmpData appendBytes:tempPaddingData length:paddingLength];
            paddedData = tmpData;
            break;
        }
        case ZZSM4CryptPaddingISO10126:
        {
            // 最后一位用"需要填充的长度"填充, 其他随机
            for (int i = 0; i < paddingLength - 1; i++) {
                tempPaddingData[i] = arc4random() % 256;
            }
            tempPaddingData[paddingLength-1] = paddingLength;
            NSMutableData *tmpData = [NSMutableData dataWithCapacity:data.length + paddingLength];
            [tmpData appendData:data];
            [tmpData appendBytes:tempPaddingData length:paddingLength];
            paddedData = tmpData;
            break;
        }
        case ZZSM4CryptPaddingANSIX923:
        {
            // 最后一位用"需要填充的长度"填充, 其他为0
            memset(tempPaddingData, 0, paddingLength);
            tempPaddingData[paddingLength-1] = paddingLength;
            NSMutableData *tmpData = [NSMutableData dataWithCapacity:data.length + paddingLength];
            [tmpData appendData:data];
            [tmpData appendBytes:tempPaddingData length:paddingLength];
            paddedData = tmpData;
            break;
        }
        case ZZSM4CryptPadding0x80:
        {
            // 第一位填充"0x80", 其他为0
            NSInteger diffSize = (data.length + 1) % blockSize;
            if (diffSize == 0) {
                // 补充一个'0x80'即可
                paddingLength = 1;
                memset(tempPaddingData, 0x80, paddingLength);
                NSMutableData *tmpData = [NSMutableData dataWithCapacity:data.length + paddingLength];
                [tmpData appendData:data];
                [tmpData appendBytes:tempPaddingData length:paddingLength];
                paddedData = tmpData;
            } else {
                // 除了补充一个'0x80'外需要填充多少个0
                paddingLength = blockSize - diffSize;
                memset(tempPaddingData, 0x80, 1);
                memset(tempPaddingData+1, 0x00, paddingLength);
                NSMutableData *tmpData = [NSMutableData dataWithCapacity:data.length + 1 + paddingLength];
                [tmpData appendData:data];
                [tmpData appendBytes:tempPaddingData length:paddingLength];
                paddedData = tmpData;
            }
            break;
        }
            
        default:
            break;
    }
    
    return paddedData;
}

/// 根据填充模式去除填充的字节
/// @param data 需要去除填充的数据
/// @param padding 填充模式
+ (NSData *)_unPaddingForData:(NSData *)data
                      padding:(ZZSM4CryptPadding)padding {
    if (![data isKindOfClass:[NSData class]] || data.length == 0) {
        return nil;
    }
    
    // 去除填充后的data
    NSData *unPaddedData = nil;
    // 需要去除的填充长度
    uint16_t paddingLength = 0;
    unsigned char *cipherBytes = (unsigned char *)data.bytes;
    switch (padding) {
        case ZZSM4CryptPaddingNone:
        {
            unPaddedData = data;
            break;
        }
        case ZZSM4CryptPaddingZero:
        {
            // 将指针指向字节序的末尾
            unsigned char *pBytes = cipherBytes + (data.length - 1);
            paddingLength = 0;
            do {
                // 倒序遍历, 不等于0x00时退出
                if (*pBytes != 0x00) {
                    break;
                }
                
                paddingLength++;
                pBytes--;
            } while (paddingLength < data.length);
            // 循环结束即得到了padding的长度
            unPaddedData = [NSData dataWithBytes:cipherBytes length:data.length - paddingLength];
            break;
        }
        case ZZSM4CryptPaddingPKCS5:
        case ZZSM4CryptPaddingPKCS7:
        case ZZSM4CryptPaddingANSIX923:
        case ZZSM4CryptPaddingISO10126:
        {
            // 这几种模式都是最后一个字节表示补位的长度
            paddingLength = cipherBytes[data.length - 1];
            if (paddingLength >= data.length) {
                return nil;
            }
            unPaddedData = [NSData dataWithBytes:cipherBytes length:data.length - paddingLength];
            break;
        }
        case ZZSM4CryptPadding0x80:
        {
            
            // 将指针指向字节序的末尾
            unsigned char *pBytes = cipherBytes + (data.length - 1);
            paddingLength = 0;
            do {
                // 倒序遍历, 等于0x80时退出
                if (*pBytes == 0x80) {
                    paddingLength++; // FIX: 将自身占用的一个字节加上
                    break;
                }
                
                paddingLength++;
                pBytes--;
            } while (paddingLength < data.length);
            // 循环结束即得到了padding的长度
            unPaddedData = [NSData dataWithBytes:cipherBytes length:data.length - paddingLength];
            break;
        }
            
        default:
            break;
    }
    
    return unPaddedData;
}


@end
