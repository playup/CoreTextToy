//
//  NSString_HTMLExtensions.h
//  knotes
//
//  Created by Jonathan Wight on 9/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_HTMLExtensions)

- (NSString *)stringByLinkifyingString;
- (NSString *)stringByMarkingUpString;

@end
