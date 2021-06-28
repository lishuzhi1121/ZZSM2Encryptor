//
//  ZZSM2EncryptorTests.m
//  ZZSM2EncryptorTests
//
//  Created by SandsLee on 2021/6/28.
//

#import <XCTest/XCTest.h>
#import <ZZSM2Encryptor/ZZSM2Encryptor.h>

@interface ZZSM2EncryptorTests : XCTestCase

/// 椭圆曲线对象
@property (nonatomic, strong) ZZSM2Cipher *cipher;

/// 公钥
@property (nonatomic, copy) NSString *publicKey;

/// 私钥
@property (nonatomic, copy) NSString *privateKey;

@end

@implementation ZZSM2EncryptorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.cipher = [ZZSM2Cipher EC_Fp_X9_62_256V1];
    self.publicKey = @"2C61B66AE99E7828140255621834CD30F07A1766D79AA8D22B52C1EA6746FCD685DD5C76529CA8090B7109FA1D4A535BCB56528E10D4C4B268A8EB75BFAE8020";
    self.privateKey = @"B385E92FD2CC8B7DF07E591F1B2763C42FDD04455B3D603CE0A36FD59889A03E";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSString *plainText = @"hello, world!";
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    // 加密
    NSData *cipherData = [ZZSM2Encryptor sm2Encrypt:plainData
                                          publicKey:self.publicKey
                                             cipher:self.cipher
                                               mode:ZZSM2CipherModeC1C2C3];
    XCTAssert(cipherData.length > 0, @"SM2加密失败!");
    
    NSString *cipherBase64Str = [ZZSM2Util stringByBase64EncodeData:cipherData];
    NSLog(@"加密结果Base64编码字符串: %@", cipherBase64Str);
    
    // 解密
    NSData *m = [ZZSM2Encryptor sm2Decrypt:cipherData
                                privateKey:self.privateKey
                                    cipher:self.cipher
                                      mode:ZZSM2CipherModeC1C2C3];
    XCTAssert(m.length > 0, @"SM2解密失败!");
    NSString *mStr = [[NSString alloc] initWithData:m encoding:NSUTF8StringEncoding];
    NSLog(@"解密结果: %@", mStr);
    XCTAssert([mStr isEqualToString:plainText], @"SM2解密失败!");
}

- (void)testGenerateKeyPairAndEncrypt {
    NSDictionary *defaultKeyPair = [ZZSM2Encryptor generateSM2KeyPairHex];
    XCTAssert([defaultKeyPair isKindOfClass:[NSDictionary class]] && defaultKeyPair.count > 0, @"SM2默认密钥生成失败!");
    NSString *pubKey = [defaultKeyPair[@"publicKey"] substringFromIndex:2];
    NSString *privKey = defaultKeyPair[@"privateKey"];
    NSLog(@"\npubKey: %@ \nprivKey: %@\n", pubKey, privKey);
    
    NSString *plainText = @"hello, world!";
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    // 加密
    NSData *cipherData = [ZZSM2Encryptor sm2Encrypt:plainData
                                          publicKey:pubKey];
    XCTAssert(cipherData.length > 0, @"SM2默认生成的密钥加密失败!");
    
    NSString *cipherBase64Str = [ZZSM2Util stringByBase64EncodeData:cipherData];
    NSLog(@"加密结果Base64编码字符串: %@", cipherBase64Str);
    
    // 解密
    NSData *m = [ZZSM2Encryptor sm2Decrypt:cipherData
                                privateKey:privKey];
    XCTAssert(m.length > 0, @"SM2默认生成的密钥解密失败!");
    NSString *mStr = [[NSString alloc] initWithData:m encoding:NSUTF8StringEncoding];
    NSLog(@"解密结果: %@", mStr);
    XCTAssert([mStr isEqualToString:plainText], @"SM2默认生成的密钥解密失败!");
    
}

- (void)testSM2SignAndVerify {
    NSString *srcText = @"Hello, I'm Sands!";
    NSData *srcData = [srcText dataUsingEncoding:NSUTF8StringEncoding];
    NSString *userId = @"shuzhi.li@quvideo.com";
    NSData *signData = [ZZSM2Encryptor sm2Sign:srcData
                                        userId:userId
                                    privateKey:self.privateKey
                                        cipher:self.cipher];
    XCTAssert(signData.length > 0, @"SM2 签名失败!");
    
    BOOL success = [ZZSM2Encryptor sm2Verify:srcData
                                      userId:userId
                                   publicKey:self.publicKey
                                      cipher:self.cipher
                                        sign:signData];
    XCTAssert(success, @"SM2 验证签名失败!");
    
}

- (void)testSM3Hash {
    NSString *srcText = @"Hello, I'm Sands!";
    NSData *hashData = [ZZSM2Encryptor sm3HashWithString:srcText];
    NSString *hashStr1 = [ZZSM2Util hexStringByData:hashData];
    NSLog(@"SM3哈希结果1: %@", hashStr1);
    XCTAssert(hashData.length > 0, @"SM3 哈希失败!");
    
    NSData *srcData = [srcText dataUsingEncoding:NSUTF8StringEncoding];
    hashData = [ZZSM2Encryptor sm3HashWithData:srcData];
    NSString *hashStr2 = [ZZSM2Util hexStringByData:hashData];
    NSLog(@"SM3哈希结果2: %@", hashStr2);
    XCTAssert(hashData.length > 0, @"SM3 哈希失败!");
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
