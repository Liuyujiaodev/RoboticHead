//
//  FaceModel.m
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/18.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

#import "FaceModel.h"

#define Face_Array @[@"20", @"28",@"0",@"1",@"2",@"3",@"4",@"9",@"10",@"11",@"12",@"13",@"34",@"35",@"44",@"45",@"55",@"64"]
//face++数组对应部位20左眉 28右眉 0左眼眼球 1左眼左角 2左眼右角  3左眼上  4左眼下 9右眼球 10右眼左脚 11右眼右角 12右眼上 13右眼下 34鼻子 35人中 44嘴角左 45嘴角右  55嘴角下  64下巴

@implementation FaceModel

+ (MGFaceModelArray*)getOwnModelArrayFromArray:(MGFaceModelArray*)modelArray {
    for (MGFaceInfo* faceInfo in modelArray.faceArray) {
        NSMutableArray* points = [NSMutableArray array];
        for (NSString* index in Face_Array) {
            [points addObject:[faceInfo.points objectAtIndex:index.intValue]];
        }
        faceInfo.points = points;
    }
    return modelArray;
}


+ (MGFaceInfo*)getCenterPoint:(NSArray*)models {
    NSMutableArray* allPointArray = [NSMutableArray array];//将所有的点分类放到这18数组中
    
    //该循环主要是将18个点进行规整，每一个点都放到对应的数组里，以便求平均数
    for (MGFaceModelArray* modelArray in models) {
        for (MGFaceInfo* faceInfo in modelArray.faceArray) {
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
    
    //求好平均点，放到points里
    NSMutableArray* points = [NSMutableArray array];
    for (NSArray* faceArray in allPointArray) {
        [points addObject:[NSValue valueWithCGPoint:[self centerPoint:faceArray]]];
    }
    
    MGFaceInfo* faceInfo = [((MGFaceModelArray*)[models objectAtIndex:0]).faceArray objectAtIndex:0];
    faceInfo.points = points;
    return faceInfo;
}

//给点求平均值
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
+ (NSArray*)getRelative:(MGFaceInfo*)faceInfo centerInfo:(MGFaceInfo*)centerInfo {
    NSMutableArray* array = [NSMutableArray array];
    
    NSArray* yLine = [self getYLineArrayWithPoint:[[faceInfo.points objectAtIndex:12] CGPointValue] andPoint:[[faceInfo.points objectAtIndex:13] CGPointValue]];
    NSArray* xLine = [self getXLineArrayWithYline:yLine andPoint:[[faceInfo.points objectAtIndex:12] CGPointValue]];

    for (int i = 0; i < centerInfo.points.count; i ++) {
        CGPoint standardPoint = [centerInfo.points[i] CGPointValue];
        CGPoint currentPoint = [faceInfo.points[i] CGPointValue];
        CGPoint relativeStandardPoint = [self getRelativePoint:standardPoint yLine:yLine xLine:xLine];
        CGPoint relativeCurrentPoint = [self getRelativePoint:currentPoint yLine:yLine xLine:xLine];
        
    }
    
    return array;
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

//映射到区间内
+ (CGFloat)map:(CGFloat)x withMin:(CGFloat)min max:(CGFloat)max outMin:(CGFloat)outMin outMax:(CGFloat)outMax {
    return (x - min) * (outMax - outMin) / (max - min) + outMin;
}

@end
