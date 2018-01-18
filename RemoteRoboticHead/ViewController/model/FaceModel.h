//
//  FaceModel.h
//  RemoteRoboticHead
//
//  Created by 刘玉娇 on 2018/1/18.
//  Copyright © 2018年 EXdoll. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MGFaceModelArray.h"

@interface FaceModel : NSObject

+ (MGFaceModelArray*)getOwnModelArrayFromArray:(MGFaceModelArray*)modelArray;

+ (MGFaceInfo*)getCenterPoint:(NSArray*)models;

+ (NSArray*)getRelative:(MGFaceInfo*)faceInfo centerInfo:(MGFaceInfo*)centerInfo;

+ (NSArray*)getYLineArrayWithPoint:(CGPoint)point1 andPoint:(CGPoint)point2;

+ (NSArray*)getXLineArrayWithYline:(NSArray*)yLine andPoint:(CGPoint)point2;
@end
