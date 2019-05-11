//
//  DKLocationKit.h
//  DKLocationDemo
//
//  Created by 崔冰smile on 2019/5/9.
//  Copyright © 2019 Ziwutong. All rights reserved.
//  后台持续定位

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DKLocationKit : NSObject
//授权
- (void)registerLocationPermision:(NSString *)key;

//开启定位
- (void)startLocation;

//停止定位
- (void)stopLocation;
@end

NS_ASSUME_NONNULL_END
