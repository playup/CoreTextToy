//
//  NSString_HTMLExtensions.m
//  knotes
//
//  Created by Jonathan Wight on 9/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "NSString_HTMLExtensions.h"

@implementation NSString (NSString_HTMLExtensions)

- (NSString *)stringByLinkifyingString
    {
    NSError *theError = NULL;
    NSDataDetector *theDataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&theError];
    
    NSMutableString *theReplacementString = [NSMutableString string];
    
    __block NSRange theLastRange = { .length = 0 };
    
    [theDataDetector enumerateMatchesInString:self options:NSMatchingCompleted range:(NSRange){ .length = self.length } usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {

        NSRange theRange = result.range;
        if (theRange.length > 0)
            {
            NSString *theString = [self substringWithRange:(NSRange){ .location = theLastRange.location + theLastRange.length, theRange.location - theLastRange.location + theLastRange.length }];
            [theReplacementString appendString:theString];
            
            NSURL *theURL = result.URL;
            theString = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", theURL.absoluteURL, theURL.absoluteURL];
            [theReplacementString appendString:theString];
            }
        else
            {
            NSString *theString = [self substringFromIndex:theLastRange.location + theLastRange.length];
            [theReplacementString appendString:theString];
            }
        
        theLastRange = theRange;
        }];
        
    return(theReplacementString);
    }

- (NSString *)stringByMarkingUpString
    {
    NSString *theString = [self stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    theString = [theString stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    theString = [theString stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    theString = [self stringByLinkifyingString];
    theString = [theString stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    return(theString);    
    }


@end
