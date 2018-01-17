//
//  UIButton+Base.m
//  XMShop
//
//  Created by 刘玉娇 on 16/3/4.
//  Copyright © 2016年 刘玉娇. All rights reserved.
//

#import "UIButton+Base.h"
#import "UIImage+Base.h"

@implementation UIButton (Base)

- (void)setBackgroundColor:(UIColor *)backgroundColor forState:(UIControlState)state {
    [self setBackgroundImage:[UIImage imageWithColor:backgroundColor] forState:state];
}

@end
