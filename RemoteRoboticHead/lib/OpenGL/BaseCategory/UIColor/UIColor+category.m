//
//  UIColor+category.m
//  SDKeyboard
//
//  Created by xiao qiang on 2017/6/27.
//  Copyright © 2017年 zy. All rights reserved.
//

#import "UIColor+category.h"

@implementation UIColor (category)

- (UIImage *)imageWithSize:(CGSize)size
{
    UIImage *img = nil;
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.CGColor);
    CGContextFillRect(context, rect);
    img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
