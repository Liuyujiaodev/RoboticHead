//
//  UIImage+Base.h
//  YiMeiBusiness
//
//  Created by 刘玉娇 on 16/1/6.
//  Copyright © 2016年 Xiaolinxiaoli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Base)

//截取部分图片
- (UIImage *)imageInRect:(CGRect)rect;

//修正拍照后的照片方向
- (UIImage *)fixOrientation ;

//将图片切圆
- (UIImage*) circleImageWithParam:(CGFloat) inset;

//颜色会成图片
+ (UIImage *)imageWithColor:(UIColor *)color;
-(UIImage *)imageByApplyingAlpha:(CGFloat )alpha;
@end
