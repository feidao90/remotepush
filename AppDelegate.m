//
//  AppDelegate.m
//  Voffice-ios
//
//  Created by 何广忠 on 2017/12/6.
//  Copyright © 2017年 何广忠. All rights reserved.
//

#import "AppDelegate.h"
#import "WXApi.h"

#import "VONetworking+Session.h"
#import "ViewController.h"

#import "VOMustUpdateViewController.h"


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0 // Xcode 8编译会调用
#import <UserNotifications/UserNotifications.h>
#endif
#import <AudioToolbox/AudioToolbox.h>

#import "VOLoginManager.h"
#import "VOMineNotificationListViewController.h"

@interface AppDelegate ()<UNUserNotificationCenterDelegate>

// 用来判断是否是通过点击通知栏开启（唤醒）APP
@property (nonatomic) BOOL isLaunchedByNotification;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //set rooter viewcontroller
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    VOMustUpdateViewController *viewController = [[VOMustUpdateViewController alloc] init];
    self.window.rootViewController = viewController;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //全局设置状态栏
    [UIApplication sharedApplication].statusBarStyle= UIStatusBarStyleLightContent;
    //tabbar 样式
    [[UITabBar appearance] setBarTintColor:[UIColor hex:@"FFFFFF"]];
    [UITabBar appearance].translucent = NO;
    
    //更新
    [self checkUpdate:launchOptions];
    //WX注册
    [WXApi registerApp:@"wxAAAA"];
    //register remote notification
    [self registerRemoteNotification];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if([VOLoginManager isLogined])
    {
        [[VOLoginManager shared] refreshLoginfo:nil];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:kDeviceTokenData];
    //do somethings
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    //注册失败 do somethings
    
}

/** APP已经接收到“远程”通知(推送) - (App运行在后台/App运行在前台)  */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    // userinfof do somethings
    
    
    if (application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesPlaySystemSound(1007);
        //跳转消息通知中心
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self jumpNotificationCenter];
        });
    }
    completionHandler(UIBackgroundFetchResultNewData);
     self.isLaunchedByNotification = YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // userinfo do somethings
    
    
    if (application.applicationState == UIApplicationStateInactive || application.applicationState == UIApplicationStateBackground) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesPlaySystemSound(1007);
        //跳转消息通知中心
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self jumpNotificationCenter];
        });
    }
    self.isLaunchedByNotification = YES;
}

- (void)jumpNotificationCenter
{
    if ([[UIApplication sharedApplication].delegate.window.rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)[UIApplication sharedApplication].delegate.window.rootViewController;
        VOBaseNavViewController *nav = (VOBaseNavViewController *)tab.selectedViewController;
        BOOL hasPush = NO;
        for (BaseViewController *VC in nav.viewControllers) {
            if ([VC isKindOfClass:[VOMineNotificationListViewController class]]) {
                hasPush = YES;
                break;
            }
        }
        if (!hasPush) {
            VOMineNotificationListViewController *notListVC = [[VOMineNotificationListViewController alloc] init];
            notListVC.hidesBottomBarWhenPushed = YES;
            notListVC.readBlock = ^{
                [[VOLoginManager shared] refreshLoginfo:nil];
            };
            notListVC.requestBlock = ^{
                [[VOLoginManager shared] refreshLoginfo:nil];
            };
            [nav pushViewController:notListVC animated:YES];
        }
    }
}

#pragma mark - 用户通知(推送) _自定义方法
/** 注册远程通知 */
- (void)registerRemoteNotification {
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0 // Xcode 8编译会调用
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionCarPlay) completionHandler:^(BOOL granted, NSError *_Nullable error) {
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
            }
        }];
#endif
    } else if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        UIUserNotificationType types = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

#pragma mark - iOS 10中收到推送消息
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
//  iOS 10: App在前台获取到通知
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // 根据APP需要，判断是否要提示用户Badge、Sound、Alert
    [[NSNotificationCenter defaultCenter] postNotificationName:kVORefreshNotificationCenter object:nil];
}

//  iOS 10: 点击通知进入App时触发（后台接受推送）
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    // userinfo do somethings
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive || [UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        //跳转消息通知中心
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self jumpNotificationCenter];
        });
    }
    completionHandler();
}
#endif

#pragma mark - 更新
- (void)checkUpdate:(NSDictionary *)launchOptions
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_Version = [infoDictionary safeObjectForKey:@"CFBundleShortVersionString"];
    NSDictionary *params = @{
                             @"appName" : @"V Office",
                             @"platformCheck" : @"2",
                             @"versionCheck" : app_Version
                             };
    //default rooter
    [VONetworking getWithUrl:@"/v1.0.0/api/appsupdate/checkUpdate" refreshRequest:NO cache:NO params:params needSession:YES successBlock:^(id response) {
        NSString *mustUpdate = [response safeObjectForKey:@"mustUpdate"];
        switch ([mustUpdate integerValue]) {
                case 0:
            {
                //set root
                [self setRooterViewController:launchOptions];
            }
                break;
            case 1:
            {
                //set root
                [self setUpdateRooterViewContoller:response andOptions:launchOptions];
            }
                break;
            case 2:
            {
                //set root
                [self setUpdateRooterViewContoller:response andOptions:launchOptions];
            }break;
            default:
                break;
        }
    } failBlock:^(NSError *error) {
        //set root
        [self setRooterViewController:launchOptions];
    }];
}

#pragma mark - set rootVC
- (void)setRooterViewController:(NSDictionary *)launchOptions
{
    if ([VOLoginManager isLogined])
    {
        ViewController *viewController = [[ViewController alloc] init];
        self.window.rootViewController = viewController;
        
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive) {
            NSDictionary* pushNotificationKey = [launchOptions safeObjectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if (pushNotificationKey) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self jumpNotificationCenter];
                });
            }
        }
    }else
    {
        //弹出登录页面
        [[VOLoginManager shared] verifyLoginStatus];
    }
}

- (void)setUpdateRooterViewContoller:(NSDictionary *)dic andOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    VOMustUpdateViewController *viewController = [[VOMustUpdateViewController alloc] init];
    viewController.info = dic;
    __weak typeof(self) weakSelf =  self;
    viewController.closeBlock = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf setRooterViewController:launchOptions];
    };
    self.window.rootViewController = viewController;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
