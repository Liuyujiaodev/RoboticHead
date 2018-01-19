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

#define Show_Array @[@"20", @"28",@"0",@"1",@"2",@"3",@"4",@"9",@"10",@"11",@"12",@"13",@"34",@"35",@"44",@"45",@"55",@"64",@"65", @"67", @"70", @"73", @"75", @"78", @"72", @"80", @"40", @"41"]

@implementation FaceModel

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

+ (MGFaceInfo*)getCenterPoint:(NSArray*)models {
    NSMutableArray* allPointArray = [NSMutableArray array];//将所有的点分类放到这18数组中
    
    CGFloat p = 0.0,y = 0.0, r= 0.0;
    
    //该循环主要是将18个点进行规整，每一个点都放到对应的数组里，以便求平均数
    for (MGFaceModelArray* modelArray in models) {
        for (MGFaceInfo* faceInfo in modelArray.faceArray) {
            if (faceInfo.pitch > p) {
                p = faceInfo.pitch;
            }
            if (faceInfo.yaw > y) {
                y = faceInfo.yaw;
            }
            if (faceInfo.roll > r) {
                r = faceInfo.roll;
            }
            
            for (NSString* indexString in Face_Array) {
                NSInteger index = [Face_Array indexOfObject:indexString];
                //已经存在改点的数组，则放到该点数组里，还没有则初始化一个数组来存放
                if (allPointArray.count > index) {
                    [[allPointArray objectAtIndex:index] addObject:[faceInfo.points objectAtIndex:index]];
                } else {
                    NSMutableArray* array = [NSMutableArray array];
                    [array addObject:[faceInfo.points objectAtIndex:index]];
                    [allPointArray addObject:array];
                }
            }
        }
    }
    NSLog(@"-----p---%lf------%lf------%lf",p, y, r);

    //求好平均点，放到points里
    NSMutableArray* points = [NSMutableArray array];
    for (NSArray* faceArray in allPointArray) {
        NSLog(@"--------%ld",[allPointArray indexOfObject:faceArray]);
        [points addObject:[NSValue valueWithCGPoint:[self centerPoint:faceArray]]];
    }
    
    MGFaceInfo* faceInfo = [((MGFaceModelArray*)[models objectAtIndex:0]).faceArray objectAtIndex:0];
    faceInfo.points = points;
    return faceInfo;
}

//给点求平均值
+ (CGPoint)centerPoint:(NSArray*)pointArray  {
    
   
//测试最大值
    //    NSMutableArray* array = [NSMutableArray array];
//    NSArray* yLine = [self getYLineArrayWithPoint:[[pointArray objectAtIndex:12] CGPointValue] andPoint:[[pointArray objectAtIndex:13] CGPointValue]];
//    NSArray* xLine = [self getXLineArrayWithYline:yLine andPoint:[[pointArray objectAtIndex:12] CGPointValue]];
//    for (int i = 0; i <pointArray.count; i ++) {
//        CGPoint currentPoint = [pointArray[i] CGPointValue];
//        CGPoint relativeCurrentPoint = [self getRelativePoint:currentPoint yLine:yLine xLine:xLine];
//        [array addObject:[NSValue valueWithCGPoint:relativeCurrentPoint]];
//    }
//
//    CGPoint pointer = [array[0] CGPointValue];
//    CGFloat maxX = pointer.x;
//    CGFloat maxY = pointer.y;
//    CGFloat minY = pointer.y;
//    CGFloat minX = pointer.x;//测试最大值最小值
//
//    for (int i = 0; i < array.count; i ++) {
//        CGPoint pointer = [array[i] CGPointValue];
//
//        if  (pointer.x > maxX){
//            maxX = pointer.x;
//        }
//        if (pointer.y > maxY) {
//            maxY = pointer.y;
//        }
//        if (pointer.x < minX) {
//            minX = pointer.x;
//        }
//        if (pointer.y < minY) {
//            minY = pointer.y;
//        }
//
//    }
//    NSLog(@"------maxX:%f-------maxY:%f----%f------%f", maxX,maxY,minX,minY);

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
+ (NSArray*)getSendData:(MGFaceInfo*)faceInfo {
    NSMutableArray* array = [NSMutableArray array];
    
    NSArray* yLine = [self getYLineArrayWithPoint:[[faceInfo.points objectAtIndex:12] CGPointValue] andPoint:[[faceInfo.points objectAtIndex:13] CGPointValue]];
    NSArray* xLine = [self getXLineArrayWithYline:yLine andPoint:[[faceInfo.points objectAtIndex:12] CGPointValue]];
    for (int i = 0; i <faceInfo.points.count; i ++) {
        CGPoint currentPoint = [faceInfo.points[i] CGPointValue];
        CGPoint relativeCurrentPoint = [self getRelativePoint:currentPoint yLine:yLine xLine:xLine];
        [array addObject:[NSValue valueWithCGPoint:relativeCurrentPoint]];
    }
    
    NSMutableArray* sendData = [NSMutableArray array];
    //左眉
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:0] CGPointValue].y inMin:0 inMax:185 outMin:20 outMax:160]]];
    
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:1] CGPointValue].y inMin:0 inMax:185 outMin:20 outMax:160]]];
    //    Servos(name: "眼睛左右", currentAngle: array[2] as! UInt8, minA: 10, maxA: 170),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:3] CGPointValue].x inMin:0 inMax:112 outMin:10 outMax:170]]];
    //    Servos(name: "眼睛上下", currentAngle: array[3] as! UInt8, minA: 10, maxA: 170),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:3] CGPointValue].y inMin:0 inMax:63 outMin:10 outMax:170]]];

    //    Servos(name: "左上眼皮", currentAngle: array[4] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:5] CGPointValue].y inMin:0 inMax:72 outMin:20 outMax:160]]];
    
    //Servos(name: "右上眼皮", currentAngle: array[5] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:10] CGPointValue].y inMin:0 inMax:80 outMin:20 outMax:160]]];
    
    // Servos(name: "左下眼皮", currentAngle: array[6] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:6] CGPointValue].y inMin:0 inMax:58 outMin:20 outMax:160]]];
    
    //Servos(name: "右下眼皮", currentAngle: array[7] as! UInt8, minA: 20, maxA: 160)
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:11] CGPointValue].y inMin:0 inMax:72 outMin:20 outMax:160]]];
    
    //Servos(name: "左唇上下", currentAngle: array[8] as! UInt8, minA: 20, maxA: 160)
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:14] CGPointValue].y inMin:0 inMax:114 outMin:20 outMax:160]]];
    
    //Servos(name: "右唇上下", currentAngle: array[9] as! UInt8, minA: 20, maxA: 160)
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:16] CGPointValue].y inMin:0 inMax:106 outMin:20 outMax:160]]];
    
    //    Servos(name: "左唇前后", currentAngle: array[10] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:14] CGPointValue].x inMin:0 inMax:80 outMin:20 outMax:160]]];
    
    //    Servos(name: "右唇前后", currentAngle: array[11] as! UInt8, minA: 20, maxA: 160),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:15] CGPointValue].x inMin:0 inMax:76 outMin:20 outMax:160]]];

    //    Servos(name: "嘴部张合", currentAngle: array[12] as! UInt8, minA: 10, maxA: 170),
    [sendData addObject:[NSNumber numberWithInt:[self map:[[array objectAtIndex:16] CGPointValue].x inMin:0 inMax:21 outMin:20 outMax:160]]];

    
    //Servos(name: "头部旋转", currentAngle: array[13] as! UInt8, minA: 40, maxA: 140)
    [sendData addObject:[NSNumber numberWithInt:[self map:faceInfo.pitch inMin:0 inMax:1 outMin:40 outMax:140]]];

     //Servos(name: "头部前后", currentAngle: array[14] as! UInt8, minA: 40, maxA: 140),
     [sendData addObject:[NSNumber numberWithInt:[self map:faceInfo.yaw inMin:0 inMax:2 outMin:40 outMax:140]]];

    //    Servos(name: "头部左右", currentAngle: array[15] as! UInt8, minA: 40, maxA: 140),
    [sendData addObject:[NSNumber numberWithInt:[self map:faceInfo.roll inMin:0 inMax:2 outMin:40 outMax:140]]];
    return sendData;
}

+ (NSArray*)getYLineArrayWithPoint:(CGPoint)point1 andPoint:(CGPoint)point2 {
    CGFloat a = point2.y - point1.y;
    CGFloat b = point1.x - point2.x;
    CGFloat c = point2.x*point1.y - point1.x*point2.y;
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:a], [NSNumber numberWithFloat:b], [NSNumber numberWithFloat:c], nil];
}

+ (NSArray*)getXLineArrayWithYline:(NSArray*)yLine andPoint:(CGPoint)point2 {
    CGFloat a = ((NSNumber*)[yLine objectAtIndex:1]).floatValue;
    CGFloat b = -((NSNumber*)[yLine objectAtIndex:0]).floatValue;
    CGFloat c = -b*point2.y - a*point2.x;
   
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

+ (CGFloat)map:(CGFloat)x inMin:(CGFloat)inMin inMax:(CGFloat)inMax outMin:(CGFloat)outMin outMax:(CGFloat)outMax {
   
    int result = (outMax - outMin) / (inMax - inMin) * (x - inMin) + outMin;
    return result;
}


@end
