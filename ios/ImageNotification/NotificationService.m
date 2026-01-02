//
//  NotificationService.m
//  ImageNotification
//
//  Created by admin on 30/12/2025.
//

#import "NotificationService.h"



@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request
                   withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler
{
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];

    // Modify the notification content here (optional) before Firebase populates it
    // e.g. self.bestAttemptContent.title = @"Updated title";


}

- (void)serviceExtensionTimeWillExpire
{
    // Deliver best attempt content if time is about to expire
    if (self.contentHandler && self.bestAttemptContent) {
        self.contentHandler(self.bestAttemptContent);
    }
}

@end
