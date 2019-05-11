//
//  ViewController.m
//  DKLocationDemo
//
//  Created by 崔冰smile on 2019/5/8.
//  Copyright © 2019 Ziwutong. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <Bugly/Bugly.h>

@interface ViewController ()
<
CLLocationManagerDelegate
>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) dispatch_source_t backgroundTimer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"后台定位";
//    [self initLocation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)appEnterBackground {
    _backgroundTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_backgroundTimer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_backgroundTimer, ^{
        NSDictionary *dict = @{@"测试":@"1"};
        [Bugly reportExceptionWithCategory:3 name:@"APP设置了UIBackgroundTaskIdentifier后台任务" reason:@"测试后台运行效果" callStack:@[] extraInfo:dict terminateApp:NO];
    });
    dispatch_resume(_backgroundTimer);
    
    [self startBackgroundTask];
}

- (void)startBackgroundTask{
    /*正常程序退出后，会在几秒内停止工作,要想申请更长的时间，需要用到
     beginBackgroundTaskWithExpirationHandler
     endBackgroundTask
     一定要成对出现*/
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier bgTask;
    bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}


- (void)initLocation {
    UIAlertController *alert;
    if ([CLLocationManager locationServicesEnabled] == NO) {
        alert = [UIAlertController alertControllerWithTitle:@"" message:@"你目前有这个设备的所有位置服务禁用" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"知道啦" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:sureAction];
    } else {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (kCLAuthorizationStatusDenied == status || kCLAuthorizationStatusRestricted == status) {
            NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
            CFShow((__bridge CFTypeRef)(infoDictionary));
            NSString *appName = [infoDictionary objectForKey:@"CFBundleDisplayName"];
            NSString *descInfo = [NSString stringWithFormat:@"请在设置中找到设置->隐私->定位服务->允许%@访问您的位置。",appName];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"您还未开启定位服务" message:descInfo preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (@available(iOS 10.0, *)) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            }]];
        } else {
            [self startLocation];
        }
    }
}

- (void)startLocation {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager requestWhenInUseAuthorization];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        self.locationManager.allowsBackgroundLocationUpdates = YES;
    }
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    [self.locationManager startUpdatingLocation];
}

#pragma mark -delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];
    double lat = location.coordinate.latitude;
    double lon = location.coordinate.longitude;
    NSLog(@"lat:%@----lon:%@",@(lat),@(lon));
    [Bugly reportExceptionWithCategory:3 name:@"APP设置了UIBackgroundTaskIdentifier后台任务" reason:@"测试后台运行效果" callStack:@[] extraInfo:@{@"测试":@"1"} terminateApp:NO];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"定位失败");
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"用户还未决定授权");
            break;
        }
        case kCLAuthorizationStatusRestricted: {
            NSLog(@"访问受限");
            break;
        }
        case kCLAuthorizationStatusDenied: {
            if ([CLLocationManager locationServicesEnabled]) {
                NSLog(@"定位服务开启，被拒绝");
            } else {
                NSLog(@"定位服务关闭，不可用");
            }
            break;
        }
        case kCLAuthorizationStatusAuthorizedAlways: {
            NSLog(@"获得前后台授权");
            break;
        }
        case kCLAuthorizationStatusAuthorizedWhenInUse: {
            NSLog(@"获得前台授权");
            break;
        }
        default:
            break;
    }
}


@end
