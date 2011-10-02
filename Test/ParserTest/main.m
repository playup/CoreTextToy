//
//  main.m
//  TouchCode
//
//  Created by Jonathan Wight on 07/15/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import <Foundation/Foundation.h>

#import "NSString_HTMLExtensions.h"
#import "CSimpleHTMLParser.h"

int main (int argc, const char * argv[])
    {
    @autoreleasepool
        {
        NSLog(@"%@", [@"hello http://world how are you?" stringByMarkingUpString]);



//        CSimpleHTMLParser *theParser = [[CSimpleHTMLParser alloc] init];
//        theParser.openTagHandler = ^(NSString *text, NSDictionary *attribites, NSArray *tagStack) { NSLog(@"TAG:  \"%@\"", text); };
//        theParser.closeTagHandler = ^(NSString *text, NSArray *tagStack) { NSLog(@"/TAG: \"%@\"", text); };
//        theParser.textHandler = ^(NSString *text, NSArray *tagStack) { NSLog(@"TEXT: \"%@\"", text); };
//
//        NSError *theError = NULL;
//        if ([theParser parseString:@"<i>hello </i><br><b>world</b>" error:&theError] == NO)
//            {
//            NSLog(@"Error: %@", theError);
//            }

        }
    return 0;
    }

