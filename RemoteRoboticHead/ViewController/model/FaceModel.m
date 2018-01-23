//
//  FaceModel.m
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/18.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

#import "FaceModel.h"

#define Face_Array @[@"20", @"28",@"0",@"1",@"2",@"3",@"4",@"9",@"10",@"11",@"12",@"13",@"34",@"35",@"44",@"45",@"55",@"64"]
//face++数组对应部位20左眉0 28右眉1  0左眼眼球2 1左眼左角3 2左眼右角4  3左眼上5  4左眼下6 9右眼球7 10右眼左脚8 11右眼右角9 12右眼上10 13右眼下11 34鼻子12 35人中13 44嘴角左14 45嘴角右15  55嘴角下16  64下巴17

#define Show_Array @[@"20", @"28",@"0",@"1",@"2",@"3",@"4",@"9",@"10",@"11",@"12",@"13",@"34",@"35",@"44",@"45",@"55",@"64",@"65", @"66", @"73", @"72", @"74", @"80", @"40", @"41"]

@implementation FaceModel

//从face++的数组里挑出我们需要传输的点
+ (MGFaceModelArray*)getOwnModelArrayFromArray:(MGFaceModelArray*)modelArray {
    for (MGFaceInfo* faceInfo in modelArray.faceArray) {
        NSMutableArray* points = [NSMutableArray array];
        for (NSString* index in Face_Array) {
            [points addObject:[faceInfo.points objectAtIndex:[Face_Array indexOfObject:index]]];
        }
        faceInfo.points = points;
    }
    return modelArray;
}

//从face++的数组里挑出我们需要的显示的点
+ (MGFaceModelArray*)getShowArray:(MGFaceModelArray*)modelArray {
    for (MGFaceInfo* faceInfo in modelArray.faceArray) {
        NSMutableArray* points = [NSMutableArray array];
        for (NSString* index in Show_Array) {
            [points addObject:[faceInfo.points objectAtIndex:index.intValue]];
        }
        faceInfo.points = points;
    }
    return modelArray;
}

//拿到定位的数据
+ (MGFaceInfo*)getCenterPoint:(NSArray*)models {
    NSMutableArray* allPointArray = [NSMutableArray array];//将所有的点分类放到这18数组中
    //该循环主要是将18个点进行规整，每一个点都放到对应的数组里，以便求平均数
    for (MGFaceModelArray* modelArray in models) {
        for (MGFaceInfo* faceInfo in modelArray.faceArray) {
            //Y轴：拿鼻尖和人中两个点，求出方程AX+By+C=0，数组返回A、B、C
            NSArray* yLine = [self getYLineArrayWithPoint:[[faceInfo.points objectAtIndex:12] CGPointValue] andPoint:[[faceInfo.points objectAtIndex:13] CGPointValue]];
            //X轴：拿左右眼角，求出方程AX+By+C=0，数组返回A、B、C
            NSArray* xLine = [self getYLineArrayWithPoint:[[faceInfo.points objectAtIndex:3] CGPointValue] andPoint:[[faceInfo.points objectAtIndex:9] CGPointValue]];

            for (NSString* indexString in Face_Array) {
                NSInteger index = [Face_Array indexOfObject:indexString];
                CGPoint point = [[faceInfo.points objectAtIndex:index] CGPointValue];
                //relativeCurrentPoint是point相对于X轴和Y轴的坐标
                CGPoint relativeCurrentPoint = [self getRelativePoint:point yLine:yLine xLine:xLine];

                //已经存在改点的数组，则放到该点数组里，还没有则初始化一个数组来存放（也就是左眼角的所有数据放一个数组，右眼角的数据放一个数组，allPointArray里存放了左眼角的数组，右眼角的数组等这样的数据）
                if (allPointArray.count > index) {
                    [[allPointArray objectAtIndex:index] addObject:[NSValue valueWithCGPoint:relativeCurrentPoint]];
                } else {
                    NSMutableArray* array = [NSMutableArray array];
                    [array addObject:[NSValue valueWithCGPoint:relativeCurrentPoint]];
                    [allPointArray addObject:array];
                }
            }
        }
    }

    //求好平均点，放到points里
    NSMutableArray* points = [NSMutableArray array];
    for (NSArray* faceArray in allPointArray) {
        [points addObject:[NSValue valueWithCGPoint:[self centerPoint:faceArray]]];
    }

    //初始化一个faceinfo，用于放计算好平均点的point
    MGFaceInfo* faceInfo = [[MGFaceInfo alloc] init];
    faceInfo.points = points;
    return faceInfo;
}

//给点求平均值，先计算出x的和，Y的和，然后除以数量
+ (CGPoint)centerPoint:(NSArray*)pointArray  {
    CGFloat totalX = 0.0, totalY = 0.0;
    for (int i = 0; i < pointArray.count; i ++) {
        CGPoint pointer = [pointArray[i] CGPointValue];

        totalX += pointer.x;
        totalY += pointer.y;
    }
    CGPoint point = CGPointMake(totalX/pointArray.count, totalY/pointArray.count);
    return point;
}

//转换成需要发送的数据
+ (NSArray*)getSendData:(NSArray*)faceArray {
    NSMutableArray* array = [NSMutableArray array];
    //如果没有数据则发送蓝牙数据90
    if (faceArray.count == 0) {
        for (int i = 0; i < 16; i++) {
            [array addObject:[NSNumber numberWithInt:90]];
        }
        return array;
    }
    
    MGFaceInfo* faceInfo = [faceArray objectAtIndex:0];
    
    //face++返回值的打印，
    CGPoint currentPoint = [faceInfo.points[0] CGPointValue];
    NSLog(@"/**********point.x:%lf*********point.y:%f", currentPoint.x,currentPoint.y);
  
    
    //Y轴：拿鼻尖和人中两个点，求出方程AX+By+C=0，数组返回A、B、C
    NSArray* yLine = [self getYLineArrayWithPoint:[[faceInfo.points objectAtIndex:12] CGPointValue] andPoint:[[faceInfo.points objectAtIndex:13] CGPointValue]];
    //X轴：拿左右眼角，求出方程AX+By+C=0，数组返回A、B、C
    NSArray* xLine = [self getYLineArrayWithPoint:[[faceInfo.points objectAtIndex:3] CGPointValue] andPoint:[[faceInfo.points objectAtIndex:9] CGPointValue]];
   
    //将所有的Point做转换，转换成以X轴和Y轴的相对坐标，存到到array数组
    for (int i = 0; i <faceInfo.points.count; i ++) {
        CGPoint currentPoint = [faceInfo.points[i] CGPointValue];
        CGPoint relativeCurrentPoint = [self getRelativePoint:currentPoint yLine:yLine xLine:xLine];
        [array addObject:[NSValue valueWithCGPoint:relativeCurrentPoint]];
    }
    
    NSMutableArray* sendData = [NSMutableArray array];
    //左眉
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:0] CGPointValue].y inMin:1 inMax:100 outMin:20 outMax:160 index:0]]];
    //右眉
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:1] CGPointValue].y inMin:1 inMax:100 outMin:20 outMax:160 index:1]]];
    //    Servos(name: "眼睛左右", currentAngle: array[2] as! UInt8, minA: 10, maxA: 170),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:3] CGPointValue].x inMin:80 inMax:200 outMin:10 outMax:170 index:2]]];
    //    Servos(name: "眼睛上下", currentAngle: array[3] as! UInt8, minA: 10, maxA: 170),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:3] CGPointValue].y inMin:0 inMax:20 outMin:10 outMax:170 index:3]]];
    //    Servos(name: "左上眼皮", currentAngle: array[4] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:5] CGPointValue].y inMin:3 inMax:15 outMin:20 outMax:160 index:4]]];
    
    //Servos(name: "右上眼皮", currentAngle: array[5] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:10] CGPointValue].y inMin:0 inMax:15 outMin:20 outMax:160 index:5]]];
    
    // Servos(name: "左下眼皮", currentAngle: array[6] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:6] CGPointValue].y inMin:0 inMax:28 outMin:20 outMax:160 index:6]]];
    
    //Servos(name: "右下眼皮", currentAngle: array[7] as! UInt8, minA: 20, maxA: 160)
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:11] CGPointValue].y inMin:0 inMax:28 outMin:20 outMax:160 index:7]]];
    
    //Servos(name: "左唇上下", currentAngle: array[8] as! UInt8, minA: 20, maxA: 160)
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:14] CGPointValue].y inMin:3 inMax:230 outMin:20 outMax:160 index:8]]];
    
    //Servos(name: "右唇上下", currentAngle: array[9] as! UInt8, minA: 20, maxA: 160)
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:16] CGPointValue].y inMin:3 inMax:290 outMin:20 outMax:160 index:9]]];
    
    //    Servos(name: "左唇前后", currentAngle: array[10] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:14] CGPointValue].x inMin:3 inMax:90 outMin:20 outMax:160 index:10]]];
    
    //    Servos(name: "右唇前后", currentAngle: array[11] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:15] CGPointValue].x inMin:3 inMax:80 outMin:20 outMax:160 index:11]]];

    //    Servos(name: "嘴部张合", currentAngle: array[12] as! UInt8, minA: 10, maxA: 170),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:16] CGPointValue].x inMin:0 inMax:30 outMin:20 outMax:160 index:12]]];

    
    //Servos(name: "头部旋转", currentAngle: array[13] as! UInt8, minA: 40, maxA: 140)
    [sendData addObject:[NSNumber numberWithInt:[self map:faceInfo.pitch inMin:-1 inMax:1 outMin:40 outMax:140 index:13]]];

     //Servos(name: "头部前后", currentAngle: array[14] as! UInt8, minA: 40, maxA: 140),
     [sendData addObject:[NSNumber numberWithInt:[self map:faceInfo.yaw inMin:-1 inMax:1 outMin:40 outMax:140 index:14]]];

    //    Servos(name: "头部左右", currentAngle: array[15] as! UInt8, minA: 40, maxA: 140),
    [sendData addObject:[NSNumber numberWithInt:[self map:faceInfo.roll inMin:0 inMax:2 outMin:40 outMax:140 index:15]]];
    return sendData;
}

//两点求出方程AX+By+C=0，数组返回A、B、C
+ (NSArray*)getYLineArrayWithPoint:(CGPoint)point1 andPoint:(CGPoint)point2 {
    CGFloat a = point2.y - point1.y;
    CGFloat b = point1.x - point2.x;
    CGFloat c = point2.x*point1.y - point1.x*point2.y;
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:a], [NSNumber numberWithFloat:b], [NSNumber numberWithFloat:c], nil];
}

//计算点到x坐标和y坐标的相对位置
+ (CGPoint)getRelativePoint:(CGPoint)point yLine:(NSArray*)yLine xLine:(NSArray*)xLine {
    CGFloat ax = ((NSNumber*)[xLine objectAtIndex:0]).floatValue;
    CGFloat bx = ((NSNumber*)[xLine objectAtIndex:1]).floatValue;
    CGFloat cx = ((NSNumber*)[xLine objectAtIndex:2]).floatValue;
    
    CGFloat ay = ((NSNumber*)[yLine objectAtIndex:0]).floatValue;
    CGFloat by = ((NSNumber*)[yLine objectAtIndex:1]).floatValue;
    CGFloat cy = ((NSNumber*)[yLine objectAtIndex:2]).floatValue;
    
    CGFloat x = fabs(ay*point.x + by*point.y + cy)/sqrt(ay*ay + by*by);
    
    CGFloat y = fabs(ax*point.x + bx*point.y + cx)/sqrt(ax*ax + bx*bx);
    
    CGPoint newPoint = CGPointMake(x, y);
    return newPoint;
}

//map区间值
+ (CGFloat)map:(CGFloat)x inMin:(CGFloat)inMin inMax:(CGFloat)inMax outMin:(CGFloat)outMin outMax:(CGFloat)outMax index:(NSInteger)index {
    
    if (x < inMin) {
        NSLog(@"/*****************index:%ld******最小值应改为:%lf",(long)index, x);
    }
    if (x > inMax) {
        NSLog(@"/*****************index:%ld******最大值应改为:%lf",(long)index, x);
    }
    int result = (outMax - outMin) / (inMax - inMin) * (x - inMin) + outMin;
    
    //index == 0这个对应的就是蓝牙发送的数组里对应的值，比如 0是左眉 1是右眉 2眼睛左右  3眼睛上下
    if (index == 0) {
        NSLog(@"/******map之前：%lf*******map之后：%d", x, result);
    }
    return result;
}


@end
