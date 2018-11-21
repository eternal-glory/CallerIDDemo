# CallerIDDemo
iOS - callkit 来电显示 extension
>前言
iOS10.0版本后,苹果公司推出callkit框架来支持VoIP功能.这里我们不去对VoIP所产生的callkit进行功能开发,针对callkit来电提示功能进行描述编写;

>工程创建

### 1 对工程创建call extension功能 target

![创建target.png](https://upload-images.jianshu.io/upload_images/2183931-b156aad34dfdb4c2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 2 选中iOS下Call Directory Extension

![Call Directory Extension.png](https://upload-images.jianshu.io/upload_images/2183931-17a4df78cece5b28.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 3 编写extension工程名(callExtension的bundle id)

![Product.png](https://upload-images.jianshu.io/upload_images/2183931-38adc78338ff912a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 4 配置工程App Group功能

![callExtension.png](https://upload-images.jianshu.io/upload_images/2183931-c98a5a2e3d8c1d21.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![product.png](https://upload-images.jianshu.io/upload_images/2183931-ed7bb12b695ed328.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

工程配置环境准备完毕!

### 功能开发

>[Demo](https://github.com/eternal-glory/CallerIDDemo)中工具类JRCallKitFileManager
这个是对CXCallDirectoryManager类对象的封装

接口简介
> 初始化
```
/**
 初始化 Extersion ID, APP Group ID 文件名

 @param externsionIdentifier extersion bundle ID
 @param groupIdentifier APP Groups ID
 @param dataSroceFileName 文件名
 */
- (void)extensionIdentifier:(NSString *)externsionIdentifier
            groupIdentifier:(NSString *)groupIdentifier
          dataSroceFileName:(NSString *)dataSroceFileName;
```
> 添加数据源
```
/**
 增加一条记录，记录增加完成后调用reload写入系统。
 推荐按照电话号码升序写入，不能写入重复的号码。
 如果重复以第一次写入的为准，后面写入的直接Return NO；
 
 PhoneNumber格式要求：
 手机：
 1. 带国家号。例如：8618011112222，^861[0-9]{10}$
 2. 不带国家号。例如：18011112222，会自动加上86，最终为：8618011112222，^1[0-9]{10}$
 3. 其它格式return NO；
 
 座机:
 1.不带国家号.但必须有区号 例如01066667777
 
 @param phoneNumber 手机号码
 @param name 标识
 */
- (void)addPhoneNumber:(NSString *)phoneNumber
                  name:(NSString *)name
            completion:(nullable void (^)(NSError * _Nullable error))completion;
```

> 写入系统中

```
/**
 先调用addPhoneNumber:label:把需要写入的记录添加
 调用该函数会把之前的记录写入系统

 @param completion 返回错误或成功后路径
 */
- (void)reload:(nullable void (^)(NSError * _Nullable error))completion;
```

> 检验是否可用及权限

```
/**
 获取Call Direcory是否可用
 根据error，enabledStatus判断
 error == nil && enabledStatus == CXCallDirectoryEnabledStatusEnabled 说明可用
 error 见 CXErrorCodeCallDirectoryManagerError
 enabledStatus 见 CXCallDirectoryEnabledStatus
 */
- (void)getEnableStatus:(nullable void (^)(CXCallDirectoryEnabledStatus enabledStatus, NSError * error))completion;
```

### 工具使用

将Demo中CallKitFileManager文件夹引导到工程内
APPDelegate中引用JRCallKitDataSorceManager.h
根据Extersion ID和APP Group ID来初始化CMPCallDirectoryManager
``` 
if (@available(iOS 10.0, *)) {
        // 初始化Extersion ID和APP Group ID
        [[JRCallKitDataSorceManager sharedManager] extensionIdentifier:ExtensionIdentifier
                                                       groupIdentifier:AppGroupIdentifier
                                                     dataSroceFileName:FileName];
    }
```

检查来电权限(iOS10以上系统真机测试)
```
- (IBAction)retrieve:(id)sender {
    if (@available(iOS 10.0, *)) {
        __weak typeof(self) weakself = self;
        [[JRCallKitFileManager sharedManager] getEnableStatus:^(CXCallDirectoryEnabledStatus enabledStatus, NSError *error) {
            if (error) {
                [weakself alertWithMessage:@"来电提示功能 获取权限发生错误 请联系开发人员" tag:0];
                return;
            }
            if (enabledStatus == CXCallDirectoryEnabledStatusUnknown) {
                [weakself alertWithMessage:@"来电提示功能 获取权限-未知状态" tag:0];
            } else if (enabledStatus == CXCallDirectoryEnabledStatusDisabled) {
                [weakself alertWithMessage:@"是否开启来电显示权限功能" tag:1];
            } else if (enabledStatus == CXCallDirectoryEnabledStatusEnabled) {
                NSLog(@"来电权限已开启");
            }
        }];
    }
}


- (void)alertWithMessage:(NSString *)message tag:(int)tag {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    
    if (tag == 1) {
        UIAlertAction * confirmAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root"] options:@{} completionHandler:nil];
            }
        }];
        [alert addAction:confirmAction];
    }
    [self presentViewController:alert animated:YES completion:nil];
}
```

信息资源录入地方

```
- (IBAction)updateDataSource:(id)sender {
    if (@available(iOS 10, *)) {
           if (@available(iOS 10, *)) {
        for (Model * model in self.dataSource) {
            // 循环遍历数据进行号码添加
            // 目前只对中国大陆号码做正则,如果有发烧友对国际编写有思想课修改内部私有接口正则修改
            [[JRCallKitDataSorceManager sharedManager] addPhoneNumber:model.number name:model.name completion:^(NSError * _Nullable error) {
                
            }];
        }
        
        // 写入到库中, 接口返回值 yes 成功 no失败.回调block做验证,如果error有值 那么呼叫功能可能不存在
        [[JRCallKitDataSorceManager sharedManager] reload:^(NSError * _Nullable error) {
            
            NSString * message = nil;
            if (error) {
                message = @"失败";
            } else {
                message = @"成功";
            }
            UIAlertController * alerVC = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
            
            [alerVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alerVC animated:YES completion:nil];
        }];
    }
}
```

### CallExtension工程文件配置

CallDirectoryHandler.m文件中添加下列代码
```
- (BOOL)addIdentificationPhoneNumbersToContext:(CXCallDirectoryExtensionContext *)context {
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:AppGroupIdentifier];
    //TODO: 必须填写文件名
    containerURL = [containerURL URLByAppendingPathComponent:@"RCECallDirectoryData"];
    FILE *file = fopen([containerURL.path UTF8String], "r");
    if (!file) {
        return YES;
    }
    char buffer[1024];
    
    // 一行一行的读，避免爆内存
    while (fgets(buffer, 1024, file) != NULL) {
        @autoreleasepool {
            NSString *result = [NSString stringWithUTF8String:buffer];
            NSData *jsonData = [result dataUsingEncoding:NSUTF8StringEncoding];
            NSError *err;
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&err];
            
            if(!err && dic && [dic isKindOfClass:[NSDictionary class]]) {
                NSString *number = dic.allKeys[0];
                NSString *name = dic[number];
                if (number && [number isKindOfClass:[NSString class]] &&
                    name && [name isKindOfClass:[NSString class]]) {
                    CXCallDirectoryPhoneNumber phoneNumber = [number longLongValue];
                    [context addIdentificationEntryWithNextSequentialPhoneNumber:phoneNumber label:name];
                }
            }
            
            dic = nil;
            result = nil;
            jsonData = nil;
            err = nil;
        }
    }
    fclose(file);
    return YES;
}
```

代理方法:- (void)beginRequestWithExtensionContext:(CXCallDirectoryExtensionContext *)context中添加:
```
if (![self addIdentificationPhoneNumbersToContext:context]) {
        NSError *error = [NSError errorWithDomain:@"CallDirectoryHandler" code:2 userInfo:nil];
        [context cancelRequestWithError:error];
        return;
    }
```

工程编写完成.

### 手机功能权限开启

![设置.png](https://upload-images.jianshu.io/upload_images/2183931-1392fe4e2bcb4eae.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![来电阻止与身份识别.png](https://upload-images.jianshu.io/upload_images/2183931-15a54c2e511e24b9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

打开你的工程权限就可以了

