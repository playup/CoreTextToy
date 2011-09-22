//
//  NSScanner_HTMLExtensions.m
//  CoreText
//
//  Created by Jonathan Wight on 9/21/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "NSScanner_HTMLExtensions.h"

@implementation NSScanner (HTMLExtensions)


// <a href="\""> // Not currently supported.
// <a href="">
// <a foo>
// <a>

- (BOOL)scanOpenTag:(NSString **)outTag attributes:(NSDictionary **)outAttributes
    {
    NSUInteger theSavedScanLocation = self.scanLocation;
    NSCharacterSet *theSavedCharactersToBeSkipped = self.charactersToBeSkipped;
    self.charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
    if ([self scanString:@"<" intoString:NULL] == NO)
        {
        self.scanLocation = theSavedScanLocation;
        self.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }
        
        
    NSString *theTag = NULL;
    if ([self scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&theTag] == NO)
        {
        self.scanLocation = theSavedScanLocation;
        self.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }
        
    NSMutableDictionary *theAttributes = [NSMutableDictionary dictionary];
    while (self.isAtEnd == NO)
        {
        NSString *theAttributeName = NULL;
        if ([self scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&theAttributeName] == NO)
            {
            break;
            }

        id theAttributeValue = [NSNull null];

        if ([self scanString:@"=" intoString:NULL] == YES)
            {
            if ([self scanString:@"\"" intoString:NULL] == NO)
                {
                self.scanLocation = theSavedScanLocation;
                self.charactersToBeSkipped = theSavedCharactersToBeSkipped;
                return(NO);
                }
            
            if ([self scanUpToString:@"\"" intoString:&theAttributeValue] == NO)
                {
                self.scanLocation = theSavedScanLocation;
                self.charactersToBeSkipped = theSavedCharactersToBeSkipped;
                return(NO);
                }

            if ([self scanString:@"\"" intoString:NULL] == NO)
                {
                self.scanLocation = theSavedScanLocation;
                self.charactersToBeSkipped = theSavedCharactersToBeSkipped;
                return(NO);
                }
            }
            
        [theAttributes setObject:theAttributeValue forKey:theAttributeName];
        }

    if ([self scanString:@">" intoString:NULL] == NO)
        {
        self.scanLocation = theSavedScanLocation;
        self.charactersToBeSkipped = theSavedCharactersToBeSkipped;
        return(NO);
        }
    
    if (outTag)
        {
        *outTag = theTag;
        }
    
    if (outAttributes && [theAttributes count] > 0)
        {
        *outAttributes = [theAttributes copy];
        }

    self.charactersToBeSkipped = theSavedCharactersToBeSkipped;
    return(YES);
    }

@end
