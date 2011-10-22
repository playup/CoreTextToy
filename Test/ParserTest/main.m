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
//        NSLog(@"%@", [@"hello http://world how are you?" stringByMarkingUpString]);

        CSimpleHTMLParser *theParser = [[CSimpleHTMLParser alloc] init];
//        theParser.openTagHandler = ^(NSString *text, NSDictionary *attribites, NSArray *tagStack) { printf("<>"); if ([text isEqualToString:@"br"]) printf("\\n\n"); };
//        theParser.closeTagHandler = ^(NSString *text, NSArray *tagStack) { printf("</>"); };
        theParser.textHandler = ^(NSString *text, NSArray *tagStack) { printf("[%s]", [text UTF8String]); };

        NSError *theError = NULL;

        NSString *theMarkup = @"<b>hello <i>world</i></b><br>\n\
A lot of entites are supported. &amp; &lt; &gt;<br>\n";
        
//        NSString *theMarkup = @"<b>hello <i>world</i></b><br>\n\
//A lot of entites are supported. &amp; &lt; &gt;<br>\n\
//White space mostly follows normal HTML rules. (But a bit buggy?)<br>\n\
//<purple>Custom tags can be used for simple styling</purple><br>\n\
//<purple><b>Styles will</b><i>accumulate</i></purple><br>\n\
//<img href=\"placeholder.png\">image tags might work too<br>\n\
//Links will work too:<br>\n\
//<a href=\"http://apple.com\">Apple</a><br>\n\
//<a href=\"http://google.com\">Google</a><br>\n\
//";
        
        if ([theParser parseString:theMarkup error:&theError] == NO)
            {
            NSLog(@"Error: %@", theError);
            }
        NSLog(@"DONE");

        }
    return 0;
    }

