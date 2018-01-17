//
//  NSDictionary+Base.m
//  YiMei
//
//  Created by 刘玉娇 on 15/10/26.
//  Copyright © 2015年 Xiaolinxiaoli. All rights reserved.
//

#import "NSDictionary+Base.h"

@implementation NSDictionary (Base)

- (NSString*)stringWithKey:(NSString*)key {
    id object = [self objectForKey:key];
    if (object && ([object isKindOfClass:[NSString class]] || [object isKindOfClass:[NSNumber class]])) {
        return [NSString stringWithFormat:@"%@", object];
    } else {
        return @"";
    }
}

- (NSArray*)arrayWithKey:(NSString*)key {
    id object = [self objectForKey:key];
    if (object && [object isKindOfClass:[NSArray class]]) {
        return object;
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        return [object allValues];
    } else {
        return [NSArray array];
    }
}

- (NSDictionary*)dicWithKey:(NSString*)key {
    id object = [self objectForKey:key];
    if (object && [object isKindOfClass:[NSDictionary class]]) {
        return object;
    } else {
        return [NSDictionary dictionary];
    }
}
@end
