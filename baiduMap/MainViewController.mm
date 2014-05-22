//
//  MainViewController.m
//  baiduMap
//
//  Created by renxlin on 14-3-11.
//  Copyright (c) 2014年 renxlin. All rights reserved.
//

#import "MainViewController.h"





@interface RouteAnnotation : BMKPointAnnotation
{
	int _type; ///<0:起点 1：终点 2：公交 3：地铁 4:驾乘 5:途经点
	int _degree;
}

@property (nonatomic) int type;
@property (nonatomic) int degree;
@end

@implementation RouteAnnotation

@synthesize type = _type;
@synthesize degree = _degree;
@end

@interface UIImage(InternalMethod)

- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees;

@end

@implementation UIImage(InternalMethod)

- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees
{
    
    CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    
	CGSize rotatedSize;
    
    rotatedSize.width = width;
    rotatedSize.height = height;
    
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
	CGContextRotateCTM(bitmap, degrees * M_PI / 180);
	CGContextRotateCTM(bitmap, M_PI);
	CGContextScaleCTM(bitmap, -1.0, 1.0);
	CGContextDrawImage(bitmap, CGRectMake(-rotatedSize.width/2, -rotatedSize.height/2, rotatedSize.width, rotatedSize.height), self.CGImage);
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}

@end





@interface MainViewController ()

@end

@implementation MainViewController
{
    BMKMapView * _mapView;
    
    BMKSearch *_search;
    
    
    NSMutableArray *_pathArray;
    
    NSString  *_cityStr;
    NSString *_cityName;
    CLLocationCoordinate2D _startPt;
    float _localLatitude;
    float _localLongitude;
    BOOL _localJudge;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    _pathArray = [[NSMutableArray alloc] init];
    
    
    _mapView =[[BMKMapView alloc] initWithFrame:self.view.bounds];
    _mapView.mapType = BMKMapTypeStandard;
    
    _mapView.delegate = self;
    
    BMKPointAnnotation * annotation = [[BMKPointAnnotation alloc] init];
    CLLocationCoordinate2D coor;
    coor.latitude = 39.915;
    coor.longitude = 116.404;
    annotation.coordinate = coor;
    annotation.title = @"北京天安门";
    [_mapView addAnnotation:annotation];
    [self.view addSubview:_mapView];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [_mapView addGestureRecognizer:longPress];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(Region:)];
    doubleTap.numberOfTapsRequired = 2;
    [_mapView addGestureRecognizer:doubleTap];
    
    //显示比例尺：
    _mapView.showMapScaleBar = YES;
    _mapView.showsUserLocation = NO;
    _mapView.userTrackingMode = BMKUserTrackingModeFollowWithHeading;//设置定位的状态
    _mapView.showsUserLocation = YES;
    
    
    //添加折线覆盖物：
    CLLocationCoordinate2D cools[3] = {0};
    cools[0].latitude = 39.915;
    cools[0].longitude = 116.4;
    
    cools[1].latitude = 39.815;
    cools[1].longitude = 116.4;
    
    cools[2].latitude = 39.7;
    cools[2].longitude = 116.3;
    BMKPolyline *polyline = [BMKPolyline polylineWithCoordinates:cools count:3];
    [_mapView addOverlay:polyline];
    //添加多边形分别区域：
    CLLocationCoordinate2D coolss[4] = {0};
    coolss[0].latitude = 39.315;
    coolss[0].longitude = 116.304;
    
    coolss[1].latitude = 39.515;
    coolss[1].longitude = 116.55;
    
    coolss[2].latitude = 39.50;
    coolss[2].longitude = 116.39;
    
    coolss[3].latitude = 39.4;
    coolss[3].longitude = 116.24;
    BMKPolygon *polygon = [BMKPolygon polygonWithCoordinates:coolss count:4];
    [_mapView addOverlay:polygon];
    
    //添加圆形覆盖物：
    CLLocationCoordinate2D radio;
    radio.latitude = 39.9;
    radio.longitude = 116.4;
    BMKCircle *circle = [BMKCircle circleWithCenterCoordinate:radio radius:5000];
    [_mapView addOverlay:circle];
    
    //城市内检索
    _search = [[BMKSearch alloc] init];
    _search.delegate = self;
    [_search poiSearchNearBy:@"大学" center:cools[0] radius:100000 pageIndex:0];
    
    
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(rightBArClick)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(leftBarClick)];
}
-(void)rightBArClick
{
    //城市内检索
    NSLog(@"啊啊啊啊啊啊啊啊啊啊啊");
    _search = [[BMKSearch alloc] init];
    _search.delegate = self;
    if(![_search poiSearchInCity:@"北京" withKey:@"千峰" pageIndex:0])
    {
        NSLog(@"failed search");
    }
    
    
}
#pragma mark 点击开始路径规划：
-(void)leftBarClick
{
    _localJudge = YES;
    //是否为当前位置为起始点
    if(_localJudge){
        //        NSLog(@"从当前位置开始驾车导航");
        //        BMKPlanNode* start = [[BMKPlanNode alloc]init];
        //        start.name =@"天安门";
        //        BMKPlanNode* end = [[BMKPlanNode alloc]init];
        //        end.name = @"北京大学";
        //
        //        BOOL flag = [_search drivingSearch:@"北京" startNode:start endCity:@"北京" endNode:end];
        //        if (flag) {
        //            NSLog(@"search success.");
        //        }
        //        else{
        //            NSLog(@"search failed!");
        //        }
        
        
        //步行检索：
        BMKPlanNode *start = [[BMKPlanNode alloc] init];
        start.name = @"天安门";
        BMKPlanNode *end = [[BMKPlanNode alloc] init];
        end.name = @"百度大厦";
        BOOL flag = [_search walkingSearch:@"北京" startNode:start endCity:@"北京" endNode:end];
        
        if (flag) {
            NSLog(@"search success.");
        }
        else{
            NSLog(@"search failed!");
        }
        
        
        
    }else{
        NSLog(@"从给定地点导航");
        BMKPlanNode *start = [[BMKPlanNode alloc] init];
        start.name = @"天安门";
        BMKPlanNode *end = [[BMKPlanNode alloc] init];
        end.name = @"百度大厦";
        if (![_search transitSearch:@"北京" startNode:start endNode:end]) {
            NSLog(@"search failed");
        }
    }
}
-(void)onGetAddrResult:(BMKAddrInfo *)result errorCode:(int)error
{
    
}
#pragma mark 双击将视角切换的所点击的点：
-(void)Region:(UITapGestureRecognizer *)tap
{
    NSLog(@"双击将视角转到该点");
    CGPoint point = [tap locationInView:tap.view];
    CLLocationCoordinate2D cool = [_mapView convertPoint:point toCoordinateFromView:_mapView];
    NSLog(@"%f,%f",cool.latitude,cool.longitude);
    NSDictionary *dic = BMKBaiduCoorForWgs84(cool);
    CLLocationCoordinate2D cool1 = BMKCoorDictionaryDecode(dic);
    BMKCoordinateRegion viewRegion = BMKCoordinateRegionMake(cool1, BMKCoordinateSpanMake(0.1, 0.01));
    BMKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion animated:YES];
    
}

//城市内poi检索：代理：
-(void)onGetPoiResult:(NSArray *)poiResultList searchType:(int)type errorCode:(int)error
{
    NSLog(@"检索poi");
    if (error == BMKErrorOk) {
        BMKPoiResult *result = [poiResultList objectAtIndex:0];
        for(int i = 0; i < [result.poiInfoList count]; i++){
            BMKPoiInfo *poi = [result.poiInfoList  objectAtIndex:i];
            BMKPointAnnotation *item = [[BMKPointAnnotation alloc]init];
            item.coordinate = poi.pt;
            item.title = poi.name;
            [_mapView addAnnotation:item];
        }
    }
}
#pragma mark 步行检索：
- (void)onGetWalkingRouteResult:(BMKPlanResult*)result errorCode:(int)error
{
    NSLog(@"步行检索调用！");
    NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
	[_mapView removeAnnotations:array];
	array = [NSArray arrayWithArray:_mapView.overlays];
	[_mapView removeOverlays:array];
	if (error == BMKErrorOk) {
		BMKRoutePlan* plan = (BMKRoutePlan*)[result.plans objectAtIndex:0];
        
		RouteAnnotation* item = [[RouteAnnotation alloc]init];
		item.coordinate = result.startNode.pt;
		item.title = @"起点";
		item.type = 0;
		[_mapView addAnnotation:item];
 		
		int index = 0;
		int size = [plan.routes count];
		for (int i = 0; i < 1; i++) {
			BMKRoute* route = [plan.routes objectAtIndex:i];
			for (int j = 0; j < route.pointsCount; j++) {
				int len = [route getPointsNum:j];
				index += len;
			}
		}
		
		BMKMapPoint* points = new BMKMapPoint[index];
		index = 0;
		
		for (int i = 0; i < 1; i++) {
			BMKRoute* route = [plan.routes objectAtIndex:i];
			for (int j = 0; j < route.pointsCount; j++) {
				int len = [route getPointsNum:j];
				BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
				memcpy(points + index, pointArray, len * sizeof(BMKMapPoint));
				index += len;
			}
			size = route.steps.count;
			for (int j = 0; j < size; j++) {
				BMKStep* step = [route.steps objectAtIndex:j];
				item = [[RouteAnnotation alloc]init];
				item.coordinate = step.pt;
				item.title = step.content;
				item.degree = step.degree * 30;
				item.type = 4;
				[_mapView addAnnotation:item];
 			}
			
		}
		
		item = [[RouteAnnotation alloc]init];
		item.coordinate = result.endNode.pt;
		item.type = 1;
		item.title = @"终点";
		[_mapView addAnnotation:item];
        
		BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:points count:index];
		[_mapView addOverlay:polyLine];
		delete []points;
        [_mapView setCenterCoordinate:result.startNode.pt animated:YES];
	}
}

#pragma mark 驾车检索：
-(void)onGetDrivingRouteResult:(BMKPlanResult *)result errorCode:(int)error
{
    NSLog(@"驾车检索代理调用！");
    if (result != nil) {
        NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
        [_mapView removeAnnotations:array];
        array = [NSArray arrayWithArray:_mapView.overlays];
        [_mapView removeOverlays:array];
        
        // error 值的意义请参考BMKErrorCode
        if (error == BMKErrorOk) {
            BMKRoutePlan* plan = (BMKRoutePlan*)[result.plans objectAtIndex:0];
            
            // 添加起点
            RouteAnnotation* item = [[RouteAnnotation alloc]init];
            item.coordinate = result.startNode.pt;
            item.title = @"起点";
            item.type = 0;
            [_mapView addAnnotation:item];
            
            // 下面开始计算路线，并添加驾车提示点
            int index = 0;
            int size = [plan.routes count];
            for (int i = 0; i < 1; i++) {
                BMKRoute* route = [plan.routes objectAtIndex:i];
                for (int j = 0; j < route.pointsCount; j++) {
                    int len = [route getPointsNum:j];
                    index += len;
                }
            }
            
            BMKMapPoint* points = new BMKMapPoint[index];
            index = 0;
            for (int i = 0; i < 1; i++) {
                BMKRoute* route = [plan.routes objectAtIndex:i];
                for (int j = 0; j < route.pointsCount; j++) {
                    int len = [route getPointsNum:j];
                    BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
                    memcpy(points + index, pointArray, len * sizeof(BMKMapPoint));
                    index += len;
                }
                size = route.steps.count;
                for (int j = 0; j < size; j++) {
                    // 添加驾车关键点
                    BMKStep* step = [route.steps objectAtIndex:j];
                    item = [[RouteAnnotation alloc]init];
                    item.coordinate = step.pt;
                    item.title = step.content;
                    item.degree = step.degree * 30;
                    item.type = 4;
                    [_mapView addAnnotation:item];
                }
                
            }
            
            // 添加终点
            item = [[RouteAnnotation alloc]init];
            item.coordinate = result.endNode.pt;
            item.type = 1;
            item.title = @"终点";
            [_mapView addAnnotation:item];
            
            // 添加途经点
            if (result.wayNodes) {
                for (BMKPlanNode* tempNode in result.wayNodes) {
                    item = [[RouteAnnotation alloc]init];
                    item.coordinate = tempNode.pt;
                    item.type = 5;
                    item.title = tempNode.name;
                    [_mapView addAnnotation:item];
                }
            }
            
            // 根究计算的点，构造并添加路线覆盖物
            BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:points count:index];
            [_mapView addOverlay:polyLine];
            delete []points;
            
            [_mapView setCenterCoordinate:result.startNode.pt animated:YES];
        }
    }
    
}

#pragma mark 公交检索：
-(void)onGetTransitRouteResult:(BMKPlanResult *)result errorCode:(int)error
{
    NSLog(@"公交检索");
    
    NSArray* array = [NSArray arrayWithArray:_mapView.annotations];
	[_mapView removeAnnotations:array];
	array = [NSArray arrayWithArray:_mapView.overlays];
	[_mapView removeOverlays:array];
    NSLog(@"错误代码%d",error);
    if (error == BMKErrorOk) {
		BMKTransitRoutePlan* plan = (BMKTransitRoutePlan*)[result.plans objectAtIndex:0];
        NSLog(@"方案个数%d",[result.plans count]);
        NSLog(@"第一条路径的路程%d米",plan.distance);
		RouteAnnotation* item = [[RouteAnnotation alloc]init];
        
        //添加起点大头针：
		item.coordinate = plan.startPt;
		item.title = @"起点";
		item.type = 0;
		[_mapView addAnnotation:item]; // 添加起点标注
        
        //添加终点大头针：
		item = [[RouteAnnotation alloc]init];
		item.coordinate = plan.endPt;
		item.type = 1;
		item.title = @"终点";
		[_mapView addAnnotation:item]; // 终点标注
		
        // 计算路线方案中的点数
		int size = [plan.lines count];
		int planPointCounts = 0;
		for (int i = 0; i < size; i++) {
			BMKRoute* route = [plan.routes objectAtIndex:i];
			for (int j = 0; j < route.pointsCount; j++) {
				int len = [route getPointsNum:j];
				planPointCounts += len;
			}
			BMKLine* line = [plan.lines objectAtIndex:i];
			planPointCounts += line.pointsCount;
			if (i == size - 1) {
				i++;
				route = [plan.routes objectAtIndex:i];
				for (int j = 0; j < route.pointsCount; j++) {
					int len = [route getPointsNum:j];
					planPointCounts += len;
				}
				break;
			}
		}
		
        // 构造方案中点的数组，用户构建BMKPolyline
		BMKMapPoint* points = new BMKMapPoint[planPointCounts];
		planPointCounts = 0;
		
        // 查询队列中的元素，构建points数组，并添加公交标注
		for (int i = 0; i < size; i++) {
			BMKRoute* route = [plan.routes objectAtIndex:i];
			for (int j = 0; j < route.pointsCount; j++) {
				int len = [route getPointsNum:j];
				BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
				memcpy(points + planPointCounts, pointArray, len * sizeof(BMKMapPoint));
				planPointCounts += len;
			}
			BMKLine* line = [plan.lines objectAtIndex:i];
			memcpy(points + planPointCounts, line.points, line.pointsCount * sizeof(BMKMapPoint));
			planPointCounts += line.pointsCount;
			
			item = [[RouteAnnotation alloc]init];
			item.coordinate = line.getOnStopPoiInfo.pt;
			item.title = line.tip;
			if (line.type == 0) {
				item.type = 2;
			} else {
				item.type = 3;
			}
			
			[_mapView addAnnotation:item]; // 上车标注
			route = [plan.routes objectAtIndex:i+1];
			item = [[RouteAnnotation alloc]init];
			item.coordinate = line.getOffStopPoiInfo.pt;
			item.title = route.tip;
			if (line.type == 0) {
				item.type = 2;
			} else {
				item.type = 3;
			}
			[_mapView addAnnotation:item]; // 下车标注
			if (i == size - 1) {
				i++;
				route = [plan.routes objectAtIndex:i];
				for (int j = 0; j < route.pointsCount; j++) {
					int len = [route getPointsNum:j];
					BMKMapPoint* pointArray = (BMKMapPoint*)[route getPoints:j];
					memcpy(points + planPointCounts, pointArray, len * sizeof(BMKMapPoint));
					planPointCounts += len;
				}
				break;
			}
		}
        
        // 通过points构建BMKPolyline
		BMKPolyline* polyLine = [BMKPolyline polylineWithPoints:points count:planPointCounts];
		[_mapView addOverlay:polyLine]; // 添加路线overlay
		delete []points;
        
        [_mapView setCenterCoordinate:result.startNode.pt animated:YES];
	}
    
    
}

-(void)tapGestureRecognizer:(UIGestureRecognizer *)tap
{
    CGPoint Point = [tap locationInView:tap.view];
    CLLocationCoordinate2D cool = [_mapView convertPoint:Point toCoordinateFromView:_mapView];
    BMKPointAnnotation *newAnnotation = [[BMKPointAnnotation alloc] init];
    newAnnotation.coordinate = cool;
    newAnnotation.title = @"unknow";
    [_mapView addAnnotation:newAnnotation];
    NSLog(@"fvgbhjnkml");
}
#pragma mark 添加覆盖物代理方法：
-(BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]]) {
        BMKPolylineView *newPoly = [[BMKPolylineView alloc] initWithOverlay:overlay];
        newPoly.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:1];
        newPoly.lineWidth = 3;
        return newPoly;
    }else if ([overlay isKindOfClass:[BMKPolygon class]]){
        BMKPolygonView *polygon = [[BMKPolygonView alloc] initWithOverlay:overlay];
        polygon.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:1];
        polygon.fillColor = [[UIColor orangeColor] colorWithAlphaComponent:0.5];
        polygon.lineWidth = 5;
        return polygon;
    }else if ([overlay isKindOfClass:[BMKCircle class]]){
        BMKCircleView *circle = [[BMKCircleView alloc]initWithOverlay:overlay];
        circle.fillColor = [[UIColor purpleColor] colorWithAlphaComponent:0.4];
        circle.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.8];
        circle.lineWidth = 5;
        return circle;
    }
    return nil;
}

#pragma mark annotationDelegate methods:
-(BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        BMKPinAnnotationView *newAnnotation = [[BMKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"myAnnotation"];
        newAnnotation.canShowCallout = true;
        newAnnotation.pinColor = BMKPinAnnotationColorPurple;
        newAnnotation.animatesDrop = YES;
        newAnnotation.image = [UIImage imageNamed:@"2.png"];
        
        UIView *vie = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        newAnnotation.rightCalloutAccessoryView = vie;
        UIImageView *im = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        im.image = [UIImage imageNamed:@"renxlin.png"];
        newAnnotation.leftCalloutAccessoryView = im;
        vie.backgroundColor = [UIColor redColor];
        NSLog(@"fgyhujikml,<<<<<<>>>>>>>>>>");
        return newAnnotation;
        
    }
    return nil;
}
//选择一个annotation view 时调用此方法(必须是在大头针的title后才可调用代理方法)：
-(void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view
{
    NSLog(@"选中了，annotation ！ %f,%f",view.annotation.coordinate.latitude,view.annotation.coordinate.longitude);
}
//当点击annotation view弹出的泡泡时，调用此接口
- (void)mapView:(BMKMapView *)mapView annotationViewForBubble:(BMKAnnotationView *)view
{
    NSLog(@"点击annotation view弹出的泡泡");
}
////用户位置信息改变，即移动。
-(void)mapView:(BMKMapView *)mapView didUpdateUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"moving:当前地点改变！");
    NSLog(@"%f,%f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    
    _startPt = userLocation.location.coordinate;
}
-(void)mapViewDidStopLocatingUser:(BMKMapView *)mapView
{
    NSLog(@"停止定位");
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
