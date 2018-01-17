//
//  UIView+Base.m
//  YiMeiBusiness
//
//  Created by 刘玉娇 on 15/12/8.
//  Copyright © 2015年 Xiaolinxiaoli. All rights reserved.
//

#import "UIView+Base.h"

@implementation UIView (Base)

- (CGFloat) height {
    return self.frame.size.height;
}

- (CGFloat) width {
    return self.frame.size.width;
}

- (CGFloat) left {
    return self.frame.origin.x;
}

- (CGFloat) top {
    return self.frame.origin.y;
}

- (CGFloat) right {
    return self.frame.origin.x + self.frame.size.width;
}

- (CGFloat) bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (CGFloat)centerY {
    return self.center.y;
}
- (CGFloat)centerX {
    return self.center.x;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = CGRectMake(self.left, self.top, self.width, height);
    self.frame = frame;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = CGRectMake(self.left, self.top, width, self.height);
    self.frame = frame;
}

- (void)setLeft:(CGFloat)left {
    CGRect frame = CGRectMake(left, self.top, self.width, self.height);
    self.frame = frame;
}

- (void)setTop:(CGFloat)top {
    CGRect frame = CGRectMake(self.left, top, self.width, self.height);
    self.frame = frame;
}

- (void)setCenterX:(CGFloat)centerX {
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}
- (void)setCenterY:(CGFloat)centerY {
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (void)setBottom:(CGFloat)bottom {
    CGRect frame = CGRectMake(self.left, bottom - self.height, self.width, bottom);
    self.frame = frame;
}

@end
