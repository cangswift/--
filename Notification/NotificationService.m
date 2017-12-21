//
//  NotificationService.m
//  Notification
//
//  Created by Apple on 2017/12/20.
//  Copyright © 2017年 dingzhu. All rights reserved.
//

#import "NotificationService.h"

@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    
    //可以拿到图片
    NSString *imgString = self.bestAttemptContent.userInfo[@"img"];
    if (imgString.length > 0) {
        
        // 创建保存推送图片的文件夹
        NSString *imgDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"pushImg"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:imgDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:imgDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // 下载图片
        NSURL *imgUrl = [NSURL URLWithString:imgString];
        NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithURL:imgUrl completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!error) {
                // 找到上次保存的图片名，删除
                NSString *str = [[NSUserDefaults standardUserDefaults] objectForKey:@"imgFileName"];
                if (str.length > 0) {
                    // 删除掉上次推送展示的图片
                    [[NSFileManager defaultManager] removeItemAtPath:[imgDir stringByAppendingPathComponent:str] error:nil];
                }
                
                // 保存图片名，以便删除
                [[NSUserDefaults standardUserDefaults] setObject:response.suggestedFilename forKey:@"imgFileName"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                // 图片文件存储路径
                NSString *imgFullPath = [imgDir stringByAppendingPathComponent:response.suggestedFilename];
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:imgFullPath] error:&error];
                
                // 推送消息
                NSError *attachmentError = nil;
                UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"img" URL:[NSURL fileURLWithPath:imgFullPath] options:nil error:&attachmentError];
                if (attachmentError) {
                    NSLog(@"%@", attachmentError);
                } else {
                    self.bestAttemptContent.attachments = @[attachment];
                    self.contentHandler(self.bestAttemptContent);
                }
 
            }
            
        }];
        // 开始下载图片
        [downloadTask resume];
        
    }
    
    
    
    self.contentHandler(self.bestAttemptContent);
}

- (void)serviceExtensionTimeWillExpire {
    
    
    
    
    
    self.contentHandler(self.bestAttemptContent);
}

@end
