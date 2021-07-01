# ZZSM2Encryptor

基于国密SM2加密解密算法的iOS OC语言实现。

## 一、接入方式

1. 将 `ZZSM2Encryptor/Package` 目录下的 `ZZSM2Encryptor.framework` 拷贝到你的项目目录并添加到项目中
2. 添加 `ZZSM2Encryptor.framework` 的系统依赖库 `libc++.tbd` 

添加完成后如下图：

![install](https://raw.githubusercontent.com/lishuzhi1121/oss/master/uPic/2021/06/30-104108-J9hUk4.png)

## 二、使用方式

### 1. 密钥生成

国密SM2使用的密钥生成方式有两种，一种是直接使用该库提供的方法生成，另一种是借助openssl命令行工具生成。一般采用后者，主要是因为密钥生成多在后端完成，所以不会采用客户端代码来生成密钥。

#### 1.1 使用该库方法生成密钥

使用该库方法生成密钥非常简单，示例代码如下：

```objc
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
    
    self.cipher = [ZZSM2Cipher EC_Fp_SECG_256K1];
    NSDictionary *keyPairDict = [ZZSM2Encryptor generateSM2KeyPairHexByCipher:self.cipher];
    // 生成的公钥使用时要去除用于表示非压缩的'04'头
    self.pubKey = [keyPairDict[ZZSM2_PUBLIC_KEY] substringFromIndex:2];
    self.privKey = keyPairDict[ZZSM2_PRIVATE_KEY];
}

@end
```

#### 1.2 使用 openssl 生成密钥

生成私钥命令：

```sh
openssl ecparam -name prime256v1 -genkey -noout -outform PEM -out private_key_prime256v1.pem
```

> -name: 椭圆曲线名称，prime256v1 对应该库的 **EC_Fp_X9_62_256V1** 椭圆曲线，secp256k1 对应该库的 **EC_Fp_SECG_256K1** 椭圆曲线。

导出公钥命令:

```sh
openssl ec -in private_key_prime256v1.pem -inform PEM -pubout -outform PEM -out public_key_prime256v1.pem
```

由于该库不提供密钥文件解析的方法，所以通过openssl生成的密钥文件需要提取出对应的公钥和私钥字符串才能使用，可以使用 [苍墨安全ASN.1在线解析](https://aks.jd.com/tools/sec/) 网站来解析，公钥文件解析示例如下：

![public](https://raw.githubusercontent.com/lishuzhi1121/oss/master/uPic/2021/06/30-175138-hPJurd.png)

解析得到的公钥字符串是：

`1990B34FD1A40945397104809E000D01B94E1DDDD1675D2C0BBCF6D49FF68745556FC084781D832A11194F0BA8C162D0B9BFCF825470B06F0FDED70E0AD76C31`

> 注意：该库使用的公钥字符串是要求不包含 '04' 这个头的。

私钥文件解析示例如下：

![](https://raw.githubusercontent.com/lishuzhi1121/oss/master/uPic/2021/06/30-180043-wAANnO.png)

解析得到的私钥字符串是：

`E21441787BAFF8FA781890BD36F79B394A3F6A52A0860607717EF137AFC2AA02`

### 2. 加密解密

加密解密方法比较简单，示例代码如下：

```objc
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSString *plainText = @"hello, world!";
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    
    // 加密
    NSData *cipherData = [ZZSM2Encryptor sm2Encrypt:plainData
                                          publicKey:self.pubKey
                                             cipher:self.cipher
                                               mode:ZZSM2CipherModeC1C2C3];
    NSString *cipherBase64Str = [ZZSM2Util stringByBase64EncodeData:cipherData];
    NSLog(@"加密结果Base64编码字符串: %@", cipherBase64Str);
    
    // 解密
    NSData *m = [ZZSM2Encryptor sm2Decrypt:cipherData
                                privateKey:self.privKey
                                    cipher:self.cipher
                                      mode:ZZSM2CipherModeC1C2C3];
    NSString *mStr = [[NSString alloc] initWithData:m encoding:NSUTF8StringEncoding];
    NSLog(@"解密结果: %@", mStr);
}
```

### 3. 其他

该库还提供了国密SM2签名与验签方法、SM3杂凑（哈希）算法的实现，具体参见接口及注释。
