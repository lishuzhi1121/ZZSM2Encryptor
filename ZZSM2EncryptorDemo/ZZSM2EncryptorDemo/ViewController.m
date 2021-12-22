//
//  ViewController.m
//  ZZSM2EncryptorDemo
//
//  Created by SandsLee on 2021/6/30.
//

#import "ViewController.h"
#import <ZZSM2Encryptor/ZZSM2Encryptor.h>

@interface ViewController ()

@property (nonatomic, strong) ZZSM2Cipher *cipher;

@property (nonatomic, copy) NSString *pubKey;

@property (nonatomic, copy) NSString *privKey;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cipher = [ZZSM2Cipher EC_Fp_X9_62_256V1];
//    NSDictionary *keyPairDict = [ZZSM2Encryptor generateSM2KeyPairHexByCipher:self.cipher];
    // 生成的公钥使用时要去除用于表示非压缩的'04'头
    self.pubKey = @"1990B34FD1A40945397104809E000D01B94E1DDDD1675D2C0BBCF6D49FF68745556FC084781D832A11194F0BA8C162D0B9BFCF825470B06F0FDED70E0AD76C31";
    self.privKey = @"E21441787BAFF8FA781890BD36F79B394A3F6A52A0860607717EF137AFC2AA02";
    
//    [self testSM4_ECB];
    [self testSM4_CBC];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self testSM2];
    
//    [self testSM4_ECB];
    [self testSM4_CBC];
}

- (void)testSM2 {
    for (int i = 0; i < 100; i++) {
        NSString *plainText = [self _randomPlainText];
        NSLog(@"%d 明文: %@", i, plainText);
        NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
        
        // 加密
        NSData *cipherData = [ZZSM2Encryptor sm2Encrypt:plainData
                                              publicKey:self.pubKey
                                                 cipher:self.cipher
                                                   mode:ZZSM2CipherModeC1C2C3];
        NSAssert(cipherData.length > 0, @"SM2加密失败!");
        
//        NSString *cipherBase64Str = [ZZSM2Util stringByBase64EncodeData:cipherData];
//        NSLog(@"加密结果Base64编码字符串: %@", cipherBase64Str);
        
        // 解密
        NSData *m = [ZZSM2Encryptor sm2Decrypt:cipherData
                                    privateKey:self.privKey
                                        cipher:self.cipher
                                          mode:ZZSM2CipherModeC1C2C3];
        NSAssert(m.length > 0, @"SM2解密失败!");
        NSString *mStr = [[NSString alloc] initWithData:m encoding:NSUTF8StringEncoding];
//        NSLog(@"解密结果: %@", mStr);
        NSAssert([mStr isEqualToString:plainText], @"SM2解密失败!");
        
        sleep(1.0);
    }
}

- (void)testSM4_ECB {
    NSString *hexPlainStr = @"0123456789abcdeffedcba9876543210";
    NSData *plainData = [hexPlainStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *hexKeyStr = @"0123456789abcdeffedcba9876543210";
    NSData *keyData = [ZZSM2Util dataByHexString:hexKeyStr];
    NSData *cipherData = [ZZSM4Encryptor sm4Encrypt:plainData
                                                key:keyData
                                          cryptMode:ZZSM4CryptModeECB
                                       cryptPadding:ZZSM4CryptPaddingZero
                                         optionalIV:plainData];
    NSString *hexCipherStr = [ZZSM2Util hexStringByData:cipherData];
    NSLog(@"hexCipherStr: %@", hexCipherStr);
    
    NSData *mData = [ZZSM4Encryptor sm4Decrypt:cipherData
                                           key:keyData
                                     cryptMode:ZZSM4CryptModeECB
                                  cryptPadding:ZZSM4CryptPaddingZero
                                    optionalIV:plainData];
    NSString *mStr = [[NSString alloc] initWithData:mData encoding:NSUTF8StringEncoding];
    NSLog(@"mStr: %@", mStr);
    
    
}


- (void)testSM4_CBC {
    NSString *plainStr = @"*248-jkfnsj(2934@zjkdn$jkfnvew#exkva244%6ads^23i2&j)5.6==/s!+";
    NSString *keyStr = @"0123456789abcdef";
    NSString *ivStr = @"fedcba9876543210";
    NSData *cipherData = [ZZSM4Encryptor sm4EncryptText:plainStr
                                              keyString:keyStr
                                              cryptMode:ZZSM4CryptModeCBC
                                           cryptPadding:ZZSM4CryptPaddingPKCS7
                                             optionalIV:ivStr];
    NSString *cStr = [ZZSM2Util hexStringByData:cipherData];
    NSLog(@"cStr: %@", cStr);

    NSData *mData = [ZZSM2Encryptor sm4DecryptText:cStr
                                         keyString:keyStr
                                         cryptMode:ZZSM4CryptModeCBC
                                      cryptPadding:ZZSM4CryptPaddingPKCS7
                                        optionalIV:ivStr];
    NSString *mStr = [[NSString alloc] initWithData:mData encoding:NSUTF8StringEncoding];
    NSLog(@"mStr: %@", mStr);
}




- (NSString *)_randomPlainText {
    NSMutableString *mstr = [NSMutableString string];
    int randomLen = arc4random_uniform(1024) + 2;
    for (int i = 0; i < randomLen; i++) {
        // ASCII 35-125
        int cInt = arc4random_uniform(126)+35;
        [mstr appendFormat:@"%c", cInt];
    }
    
    return [mstr copy];
}

@end
