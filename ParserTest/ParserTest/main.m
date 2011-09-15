//
//  main.m
//  ParserTest
//
//  Created by Jonathan Wight on 07/15/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CSimpleHTMLParser.h"

int main (int argc, const char * argv[])
    {
    @autoreleasepool
        {
        CSimpleHTMLParser *theParser = [[CSimpleHTMLParser alloc] init];
        theParser.openTagHandler = ^(NSString *text, NSArray *tagStack) { NSLog(@"TAG: %@", text); };        
        theParser.closeTagHandler = ^(NSString *text, NSArray *tagStack) { NSLog(@"/TAG: %@", text); };        
        theParser.textHandler = ^(NSString *text, NSArray *tagStack) { NSLog(@"TEXT: %@", text); };        
                
        NSError *theError = NULL;
        if ([theParser parseString:@"<i>hello </i><br><b>world</b>" error:&theError] == NO)
            {
            NSLog(@"Error: %@", theError);
            }
        
        }
    return 0;
    }

