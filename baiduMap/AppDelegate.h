//
//  AppDelegate.h
//  baiduMap
//
//  Created by renxlin on 14-3-11.
//  Copyright (c) 2014年 renxlin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BMKMapManager.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    BMKMapManager *_mapManager;
}
@property (strong, nonatomic) UIWindow *window;

@end
