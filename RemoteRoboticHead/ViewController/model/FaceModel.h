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

+ (NSArray*)getSendData:(MGFaceInfo*)faceInfo;

+ (MGFaceModelArray*)getShowArray:(MGFaceModelArray*)modelArray;

+ (CGPoint)getRelativePoint:(CGPoint)point yLine:(NSArray*)yLine xLine:(NSArray*)xLine;
@end
