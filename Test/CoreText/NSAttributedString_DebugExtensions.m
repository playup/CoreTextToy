//
//  NSAttributedString_DebugExtensions.m
//  CoreText
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "NSAttributedString_DebugExtensions.h"

@implementation NSAttributedString (NSAttributedString_DebugExtensions)

- (NSString *)betterDescription
    {

    NSMutableArray *theComponents = [NSMutableArray array];


    [self enumerateAttributesInRange:(NSRange){ .length = self.length } options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {

        NSString *theString = [NSString stringWithFormat:@"\"%@\"", [self.string substringWithRange:range]];

        [theComponents addObject:theString];

        }];


    return([NSString stringWithFormat:@"%@ %@", [super description], [theComponents componentsJoinedByString:@", "]]);

    }


@end
