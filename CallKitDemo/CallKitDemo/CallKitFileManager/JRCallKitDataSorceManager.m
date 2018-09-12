//
//  JRCallKitDataSorceManager.m
//  CallKitDemo
//
//  Created by Johnson Rey on 2018/5/16.
//  Copyright © 2018年 Zimeng Rey. All rights reserved.
//

#import "JRCallKitDataSorceManager.h"

@interface JRCallKitDataSorceManager ()

@property (nonatomic, strong) NSString * dataSroceFileName;
/** externsion的Bundle ID **/
@property (nonatomic, strong) NSString *externsionIdentifier;
/** APP Groups的ID **/
@property (nonatomic, strong) NSString *groupIdentifier;
/** 存储待写入电话号码与标识，key：号码，value：标识 **/
@property (nonatomic, strong) NSMutableDictionary *dataList;
/** 带国家码的手机号 **/
@property (nonatomic, strong) NSPredicate *phoneNumberWithNationCodePredicate;
/** 不带国家码的手机号 **/
@property (nonatomic, strong) NSPredicate *phoneNumberWithoutNationCodePredicate;

/** 默认座机号 */
@property (nonatomic, strong) NSPredicate *telephoneNumeberWithoutCodePredicate;

@end

@implementation JRCallKitDataSorceManager

+ (instancetype)sharedManager {
    static JRCallKitDataSorceManager * _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc] init];
    });
    return _manager;
}

- (void)extensionIdentifier:(NSString *)externsionIdentifier ApplicationGroupIdentifier:(NSString *)groupIdentifier dataSroceFileName:(NSString *)dataSroceFileName {
    self.externsionIdentifier = externsionIdentifier;
    self.groupIdentifier = groupIdentifier;
    self.dataSroceFileName = dataSroceFileName;
}

- (void)getEnableStatus:(void (^)(CXCallDirectoryEnabledStatus enabledStatus, NSError * error))completion {
    CXCallDirectoryManager *manager = [CXCallDirectoryManager sharedInstance];
    [manager
     getEnabledStatusForExtensionWithIdentifier:self.externsionIdentifier
     completionHandler:^(CXCallDirectoryEnabledStatus enabledStatus, NSError * _Nullable error) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if (completion) {
                 completion(enabledStatus, error);
             }
         });
     }];
}

- (BOOL)addPhoneNumber:(NSString *)phoneNumber name:(NSString *)name {
    if (!phoneNumber || ![phoneNumber isKindOfClass:[NSString class]] ||
        !name || ![name isKindOfClass:[NSString class]] || name.length == 0) {
        return NO;
    }
    
    NSString *handledPhoneNumber = [self handlePhoneNumber:phoneNumber];
    if (handledPhoneNumber) {
        if (self.dataList[handledPhoneNumber]) { // 已经设置过这个phoneNumber
            return NO;
        }
    } else {
        handledPhoneNumber = [self handleTelePhoneNumber:phoneNumber];
        if (handledPhoneNumber) {
            if (self.dataList[handledPhoneNumber]) { // 已经设置过这个phoneNumber
                return NO;
            }
        } else {
            return NO;
        }
    }
    
    [self.dataList setObject:name forKey:handledPhoneNumber];
    return YES;
}

- (void)reload:(void (^)(NSError * _Nullable error, NSString * filePath))completion {
    if (self.dataList.count == 0) {
        completion([[NSError alloc] initWithDomain:@"The data source is empty, please contact the service." code:-1 userInfo:nil], nil);
    }
    
    NSString * filePath = [self writeDataToAppGroupFile:^(NSError * _Nullable error) {
        if (error) {
            completion(error, nil);
        }
    }];
    
    CXCallDirectoryManager *manager = [CXCallDirectoryManager sharedInstance];
    [manager reloadExtensionWithIdentifier:self.externsionIdentifier completionHandler:^(NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                if (error.code != 0) {
                    completion(error, nil);
                } else {
                    completion(nil, filePath);
                }
            }
        });
    }];
}

#pragma mark -
#pragma mark -Inner Method

- (void)clearPhoneNumber {
    [self.dataList removeAllObjects];
}

/**
 处理手机号码
 自动加上国家码，如果号码不合规返回nil
 */
- (NSString *)handlePhoneNumber:(NSString *)phoneNumber {
    if ([self.phoneNumberWithNationCodePredicate evaluateWithObject:phoneNumber]) {
        return phoneNumber;
    }
    
    if ([self.phoneNumberWithoutNationCodePredicate evaluateWithObject:phoneNumber]) {
        return [NSString stringWithFormat:@"86%@", phoneNumber];
    }
    
    return nil;
}

- (NSString *)handleTelePhoneNumber:(NSString *)telephone {
    telephone = [telephone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    if ([self.telephoneNumeberWithoutCodePredicate evaluateWithObject:telephone]) {
        NSString *string2 = @"00";
        NSRange range1 = [telephone rangeOfString:string2];
        NSInteger location1 = range1.location;
        if (location1 == 0) {
            return nil;
        }
        
        NSString * tel = nil;
        NSString * string = @"0";
        NSRange range = [telephone rangeOfString:string];
        NSUInteger location = range.location;
        if (location == 0) {
            tel = [telephone substringFromIndex:1];
        }
        return [NSString stringWithFormat:@"86%@",tel];
    }
    return nil;
}

/**
 对dataList中的记录进行升序排序，然后转换为string
 */
- (NSString *)dataToString {
    //    NSMutableArray *phoneArray = [NSMutableArray arrayWithArray:[self.dataList allKeys]];
    
    NSMutableArray *phoneArray = [NSMutableArray array];
    for (NSString * key in self.dataList) {
        NSNumber * num = [NSNumber numberWithInteger:[key integerValue]];
        [phoneArray addObject:num];
    }
    [phoneArray sortUsingSelector:@selector(compare:)];
    
    NSMutableString *dataStr = [[NSMutableString alloc] init];
    
    for (NSNumber *phone in phoneArray) {
        NSString *label = self.dataList[phone.stringValue];
        NSString *dicStr = [NSString stringWithFormat:@"{\"%@\":\"%@\"}\n", phone, label];
        [dataStr appendString:dicStr];
    }
    
    return [dataStr copy];
}

/**
 将数据写入APP Group指定文件中
 */
- (NSString *)writeDataToAppGroupFile:(void (^)(NSError * _Nullable error))completion {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *containerURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.groupIdentifier];
    if (containerURL == nil) {
        completion([[NSError alloc] initWithDomain:@"Container link is empty, Please check if the project configuration file is consistent with the APP group id." code:-1000 userInfo:nil]);
        return nil;
    }
    
    containerURL = [containerURL URLByAppendingPathComponent:self.dataSroceFileName];
    NSString * filePath = containerURL.path;
    if (!filePath || ![filePath isKindOfClass:[NSString class]]) {
        completion([[NSError alloc] initWithDomain:@"File path initialization failed" code:-1001 userInfo:nil]);
        return nil;
    }
    
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }
    
    if (![fileManager createFileAtPath:filePath contents:nil attributes:nil]) {
        completion([[NSError alloc] initWithDomain:@"Failed to create file" code:-1001 userInfo:nil]);
        return nil;
    }
    
    BOOL result = [[self dataToString] writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self clearPhoneNumber];
    if (!result) {
        completion([[NSError alloc] initWithDomain:@"Data entry file failed" code:-1002 userInfo:nil]);
        return nil;
    } else {
        completion(nil);
    }
    
    return filePath;
}

#pragma mark -Getter
- (NSMutableDictionary *)dataList {
    if (!_dataList) {
        _dataList = [NSMutableDictionary dictionary];
    }
    return _dataList;
}

- (NSPredicate *)phoneNumberWithNationCodePredicate {
    if (!_phoneNumberWithNationCodePredicate) {
        NSString *mobileWithNationCodeRegex = @"^861[0-9]{10}$";
        _phoneNumberWithNationCodePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileWithNationCodeRegex];
    }
    return _phoneNumberWithNationCodePredicate;
}

- (NSPredicate *)phoneNumberWithoutNationCodePredicate {
    if (!_phoneNumberWithoutNationCodePredicate) {
        NSString *mobileWithoutNationCodeRegex = @"^1[0-9]{10}$";
        _phoneNumberWithoutNationCodePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", mobileWithoutNationCodeRegex];
    }
    return _phoneNumberWithoutNationCodePredicate;
}

- (NSPredicate *)telephoneNumeberWithoutCodePredicate {
    if (!_telephoneNumeberWithoutCodePredicate) {
        NSString * telephoneCodeRegex = @"^[0][1-9]\\d{1,2}\\d{7,8}$";
        _telephoneNumeberWithoutCodePredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", telephoneCodeRegex];
    }
    
    return _telephoneNumeberWithoutCodePredicate;
}

- (BOOL)isPureNumandCharacters:(NSString *)string {
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if(string.length > 0) {
        return NO;
    }
    return YES;
}

@end
