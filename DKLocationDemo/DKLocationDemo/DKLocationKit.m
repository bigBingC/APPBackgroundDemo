//
//  DKLocationKit.m
//  DKLocationDemo
//
//  Created by 崔冰smile on 2019/5/9.
//  Copyright © 2019 Ziwutong. All rights reserved.
//

#import "DKLocationKit.h"
#import <BMKLocationKit/BMKLocationComponent.h>

@interface DKLocationKit () <BMKLocationAuthDelegate,BMKLocationManagerDelegate>
@property (nonatomic, strong) BMKLocationManager *locationManager;
@property (nonatomic, assign) BOOL isCollectLocation;
@end

@implementation DKLocationKit

- (instancetype)init {
    if (self = [super init]) {
        self.isCollectLocation = NO;
        //监听进入后台通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)applicationEnterBackground {
    [self.locationManager setLocatingWithReGeocode:YES];
    [self.locationManager startUpdatingLocation];
}

- (void)registerLocationPermision:(NSString *)key {
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:key authDelegate:self];
}

- (void)startLocation {
    NSLog(@"开始定位");
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
            [self applicationEnterBackground];
        }
    }
}

- (void)restartLocation {
    NSLog(@"重新启动定位");
    [self.locationManager setLocatingWithReGeocode:YES];
    [self.locationManager startUpdatingLocation];
}

- (void)stopLocation {
    NSLog(@"停止定位");
    self.isCollectLocation = NO;
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - delegate
- (void)onCheckPermissionState:(BMKLocationAuthErrorCode)iError {
    if (iError == BMKLocationAuthErrorSuccess) {
        NSLog(@"鉴权成功");
    } else {
        NSLog(@"鉴权失败");
    }
}

- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager didFailWithError:(NSError * _Nullable)error {
    NSLog(@"定位失败");
    
}

- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager didUpdateLocation:(BMKLocation * _Nullable)location orError:(NSError * _Nullable)error {
    NSLog(@"定位采集");
    
    if (self.isCollectLocation) {
        return;
    }
    
    [self performSelector:@selector(restartLocation) withObject:nil afterDelay:120];
    [self performSelector:@selector(stopLocation) withObject:nil afterDelay:10];
    self.isCollectLocation = YES;
    
    if (error) {
        NSLog(@"定位失败");
    } else if (location) {
        NSLog(@"LON = %@----LAT = %@",@(location.location.coordinate.longitude),@(location.location.coordinate.latitude));
        
        if (location.rgcData) {
            NSLog(@"rgc = %@",[location.rgcData description]);
        }
    }
    
}

- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
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


#pragma mark - 初始化
- (BMKLocationManager *)locationManager {
    if (!_locationManager) {
        //初始化实例
        _locationManager = [[BMKLocationManager alloc] init];
        //设置delegate
        _locationManager.delegate = self;
        //设置返回位置的坐标系类型
        _locationManager.coordinateType = BMKLocationCoordinateTypeBMK09LL;
        //设置距离过滤参数
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        //设置预期精度参数
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //设置应用位置类型
        _locationManager.activityType = CLActivityTypeAutomotiveNavigation;
        //设置是否自动停止位置更新
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        //设置是否允许后台定位
        _locationManager.allowsBackgroundLocationUpdates = YES;
        //设置位置获取超时时间
        _locationManager.locationTimeout = 10;
        //设置获取地址信息超时时间
        _locationManager.reGeocodeTimeout = 10;
    }
    return _locationManager;
}
@end
