//
//  JRCallKitFileManager.h
//  CallKitDemo
//
//  Created by Johnson Rey on 2018/5/16.
//  Copyright © 2018年 Zimeng Rey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CallKit/CallKit.h>

API_AVAILABLE(ios(10.0))
@interface JRCallKitFileManager : NSObject

+ (instancetype)sharedManager;

/**
 初始化 Extersion ID和APP Group ID

 @param externsionIdentifier extersion ID
 @param groupIdentifier APP Group ID
 */
- (void)extensionIdentifier:(NSString *)externsionIdentifier ApplicationGroupIdentifier:(NSString *)groupIdentifier;

/**
 获取Call Direcory是否可用
 根据error，enabledStatus判断
 error == nil && enabledStatus == CXCallDirectoryEnabledStatusEnabled 说明可用
 error 见 CXErrorCodeCallDirectoryManagerError
 enabledStatus 见 CXCallDirectoryEnabledStatus
 */
- (void)getEnableStatus:(nullable void (^)(CXCallDirectoryEnabledStatus enabledStatus, NSError * error))completion;

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
 @return 是否成功
 */
- (BOOL)addPhoneNumber:(NSString *)phoneNumber name:(NSString *)name;

/**
 清除之前添加的数据
 调用reload之后会自动调用
 */
- (void)clearPhoneNumber;

/**
 先调用addPhoneNumber:label:把需要写入的记录添加
 调用该函数会把之前的记录写入系统
 error 见 CXErrorCodeCallDirectoryManagerError
 return NO 写文件失败
 */
- (BOOL)reload:(nullable void (^)(NSError * _Nullable error))completion;

@end
