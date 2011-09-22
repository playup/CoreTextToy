//
//  NSScanner_HTMLExtensions.h
//  CoreText
//
//  Created by Jonathan Wight on 9/21/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (HTMLExtensions)

- (BOOL)scanOpenTag:(NSString **)outTag attributes:(NSDictionary **)outAttributes;

@end
