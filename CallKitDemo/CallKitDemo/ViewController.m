//
//  ViewController.m
//  CallKitDemo
//
//  Created by Johnson Rey on 2018/5/15.
//  Copyright © 2018年 Zimeng Rey. All rights reserved.
//

#import "ViewController.h"
#import "JRCallKitFileManager.h"
#import "Model.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITextField *numberTF;

@property (weak, nonatomic) IBOutlet UITextField *nameTF;

@property (nonatomic, strong) NSMutableArray * dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)addDataSource:(id)sender {
    
    if (_nameTF.text.length > 0 && _numberTF.text.length > 0) {
        NSString * name = self.nameTF.text;
        NSString * number = self.numberTF.text;
        Model * model = [[Model alloc] init];
        model.name = name;
        model.number = number;
        [self.dataSource addObject:model];
    }
}

- (IBAction)updateDataSource:(id)sender {
    if (@available(iOS 10, *)) {
        for (Model * model in self.dataSource) {
            // 循环遍历数据进行号码添加
            // 目前只对中国大陆号码做正则,如果有发烧友对国际编写有思想课修改内部私有接口正则修改
            [[JRCallKitFileManager sharedManager] addPhoneNumber:model.number name:model.name];
        }
        
        // 写入到库中, 接口返回值 yes 成功 no失败.回调block做验证,如果error有值 那么呼叫功能可能不存在
        BOOL reluat = [[JRCallKitFileManager sharedManager] reload:^(NSError *error) {
            
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
        
        NSString * string = reluat ? @"保存数据成功" : @"保存数据失败";
        
        NSLog(@"%@",string);
    }
}


- (IBAction)retrieve:(id)sender {
    if (@available(iOS 10.0, *)) {
        __weak typeof(self) weakself = self;
        // 检测group id 及权限
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



- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return _dataSource;
}

@end
