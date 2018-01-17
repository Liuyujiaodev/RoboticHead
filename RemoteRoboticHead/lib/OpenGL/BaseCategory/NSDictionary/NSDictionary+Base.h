//
//  NSDictionary+Base.h
//  YiMei
//
//  Created by 刘玉娇 on 15/10/26.
//  Copyright © 2015年 Xiaolinxiaoli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Base)

/**
 *  获取string 如果为null或者不存在则返回空字符串
 *
 *  @param key
 */
- (NSString*)stringWithKey:(NSString*)key;

/**
 *  获取array 如果为null或者不存在则返回空数组
 *
 *  @param key
 */
- (NSArray*)arrayWithKey:(NSString*)key;

/**
 *  获取dic 如果为null或者不存在则返回空dic
 *
 *  @param key
 */
- (NSDictionary*)dicWithKey:(NSString*)key;

@end
