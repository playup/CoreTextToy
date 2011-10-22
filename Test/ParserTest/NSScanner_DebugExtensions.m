//
//  NSScanner_DebugExtensions.m
//  ParserTest
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "NSScanner_DebugExtensions.h"

@implementation NSScanner (NSScanner_DebugExtensions)

- (void)dumpState
    {
    NSLog(@"description: %@", self.description);
    NSLog(@"string: \"%@\"", self.string);
    NSLog(@"isAtEnd: %d", self.isAtEnd);
    NSLog(@"scanLocation: %lu / %lu", self.scanLocation, self.string.length);
    NSLog(@"scanned: \"%@\"", [self.string substringToIndex:self.scanLocation]);
    NSLog(@"current: \"%c\"", [self.string characterAtIndex:self.scanLocation]);
    NSLog(@"to scan: \"%@\"", [self.string substringFromIndex:self.scanLocation]);
    }


@end
