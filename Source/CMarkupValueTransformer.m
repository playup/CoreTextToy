//
//  CMarkupValueTransformer.m
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

#import "CMarkupValueTransformer.h"

#import <CoreText/CoreText.h>

#import "UIFont_CoreTextExtensions.h"
#import "CMarkupValueTransformer.h"
#import "CSimpleHTMLParser.h"
#import "CCoreTextAttachment.h"
#import "CCoreTextRenderer.h"
#import "NSAttributedString_Extensions.h"

@interface CMarkupValueTransformer ()
@property (readwrite, nonatomic, strong) NSMutableArray *tagHandlers;

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack;
@end

#pragma mark -

@implementation CMarkupValueTransformer

@synthesize tagHandlers;

+ (Class)transformedValueClass
    {
    return([NSAttributedString class]);
    }

+ (BOOL)allowsReverseTransformation
    {
    return(NO);
    }

- (id)init
	{
	if ((self = [super init]) != NULL)
		{
        tagHandlers = [NSMutableArray array];

        [self resetStyles];

        [self addStandardStyles];
		}
	return(self);
	}

- (id)transformedValue:(id)value
    {
    return([self transformedValue:value error:NULL]);
    }

- (id)transformedValue:(id)value error:(NSError **)outError
    {
    NSString *theMarkup = value;

    NSMutableAttributedString *theAttributedString = [[NSMutableAttributedString alloc] init];

    __block NSMutableDictionary *theTextAttributes = NULL;
    __block NSURL *theCurrentLink = NULL;

    CSimpleHTMLParser *theParser = [[CSimpleHTMLParser alloc] init];

    theParser.openTagHandler = ^(CTag *inTag, NSArray *tagStack) {
        if ([inTag.name isEqualToString:@"a"] == YES)
            {
            NSString *theURLString = [inTag.attributes objectForKey:@"href"];
            if ((id)theURLString != [NSNull null] && theURLString.length > 0)
                {
                theCurrentLink = [NSURL URLWithString:theURLString];
                }
            }
        else if ([inTag.name isEqualToString:@"img"] == YES)
            {
            id theImageSource = [inTag.attributes objectForKey:@"src"];
            UIImage *theImage = NULL;
            if (theImageSource != [NSNull null] && [theImageSource length] > 0)
                {
                theImage = [UIImage imageNamed:theImageSource];
                }
            if (theImage == NULL)
                {
                theImage = [UIImage imageNamed:@"MissingImage.png"];
                }
            if (theImage != NULL)
                {
                CCoreTextAttachment *theAttachment = [[CCoreTextAttachment alloc] initWithAscent:theImage.size.height descent:0.0 width:theImage.size.width representedObject:theImage renderer:^(CCoreTextAttachment *inAttachment, CGContextRef inContext, CGRect inRect) {
                    [theImage drawInRect:inRect];
                    }];

                CTRunDelegateRef theRunDelegate = [theAttachment createRunDelegate];

                NSMutableDictionary *theImageAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                    theAttachment, kMarkupAttachmentAttributeName,
                    (__bridge_transfer id)theRunDelegate, (__bridge id)kCTRunDelegateAttributeName,
                    NULL];
                
                if (theCurrentLink != NULL)
                    {
                    [theImageAttributes setObject:theCurrentLink forKey:kMarkupLinkAttributeName];
                    }

                // U+FFFC "Object Replacment Character" (thanks to Jens Ayton for the pointer)
                NSAttributedString *theImageString = [[NSAttributedString alloc] initWithString:@"\uFFFC" attributes:theImageAttributes];
                [theAttributedString appendAttributedString:theImageString];
                }
            }
        };

    theParser.closeTagHandler = ^(CTag *inTag, NSArray *tagStack) {
        if ([inTag.name isEqualToString:@"a"] == YES == YES)
            {
            theCurrentLink = NULL;
            }
    };

    theParser.textHandler = ^(NSString *inString, NSArray *tagStack) {
        NSDictionary *theAttributes = [self attributesForTagStack:tagStack];
        theTextAttributes = [theAttributes mutableCopy];

        if (theCurrentLink != NULL)
            {
            [theTextAttributes setObject:theCurrentLink forKey:kMarkupLinkAttributeName];
            }
        
        [theAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:inString attributes:theTextAttributes]];
        };

    if ([theParser parseString:theMarkup error:outError] == NO)
        {
        return(NULL);
        }

    return(theAttributedString);
    }

- (void)resetStyles
    {
    self.tagHandlers = [NSMutableArray array];
    }

- (void)addStandardStyles
    {
    BTagHandler theTagHandler = NULL;

    // ### b
    theTagHandler = ^(void) {
        return([NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:YES], kMarkupBoldAttributeName,
            NULL]);
        };
    [self addHandler:theTagHandler forTag:@"b"];

    // ### i
    theTagHandler = ^(void) {
        return([NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithBool:YES], kMarkupItalicAttributeName,
            NULL]);
        };
    [self addHandler:theTagHandler forTag:@"i"];

    // ### a
    theTagHandler = ^(void) {
        return([NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)[UIColor blueColor].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
            [NSNumber numberWithInt:kCTUnderlineStyleSingle], (__bridge id)kCTUnderlineStyleAttributeName,
            NULL]);
        };
    [self addHandler:theTagHandler forTag:@"a"];

    // ### mark
    theTagHandler = ^(void) {
        return([NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)[UIColor yellowColor].CGColor, kMarkupBackgroundColorAttributeName,
            NULL]);
        };
    [self addHandler:theTagHandler forTag:@"mark"];

    // ### strike
    theTagHandler = ^(void) {
        return([NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)[UIColor blackColor].CGColor, kMarkupStrikeColorAttributeName,
            NULL]);
        };
    [self addHandler:theTagHandler forTag:@"strike"];

    // ### small
    theTagHandler = ^(void) {
        return([NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithFloat:-4], kMarkupSizeAdjustmentAttributeName,
            NULL]);
        };
    [self addHandler:theTagHandler forTag:@"small"];


    // ### font
    theTagHandler = ^(void) {
        NSLog(@"FONT");
        
        return((NSDictionary *)NULL);
        };
    [self addHandler:theTagHandler forTag:@"font"];
    }

- (void)addHandler:(BTagHandler)inHandler forTag:(NSString *)inTag
    {
    [self.tagHandlers addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            [inHandler copy], @"handler",
            inTag, @"tag",
            NULL]
        ];
    }

- (void)removeHandlerForTag:(NSString *)inTag
    {
    NSMutableArray *theNewHandlers = [NSMutableArray array];
    
    [self.tagHandlers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *theTag = [obj objectForKey:@"tag"];
        if ([theTag isEqualToString:inTag] == NO)
            {
            [theNewHandlers addObject:obj];
            }
        }];
    
    self.tagHandlers = theNewHandlers;
    }

#pragma mark -

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack
    {
    NSSet *theTagSet = [NSSet setWithArray:[inTagStack valueForKey:@"name"]];
    NSMutableDictionary *theCumulativeAttributes = [NSMutableDictionary dictionary];
    
    for (NSDictionary *theDictionary in self.tagHandlers)
        {
        NSString *theTag = [theDictionary objectForKey:@"tag"];

        if ([theTagSet containsObject:theTag])
            {
            BTagHandler theHandler = [theDictionary objectForKey:@"handler"];
            NSDictionary *theAttributes = theHandler();
            [theCumulativeAttributes addEntriesFromDictionary:theAttributes];
            }
        }

    return(theCumulativeAttributes);
    }

@end

#pragma mark -

@implementation NSAttributedString (NSAttributedString_MarkupExtensions)

+ (NSAttributedString *)attributedStringWithMarkup:(NSString *)inMarkup error:(NSError **)outError
    {
    CMarkupValueTransformer *theTransformer = [[CMarkupValueTransformer alloc] init];

    NSAttributedString *theAttributedString = [theTransformer transformedValue:inMarkup error:outError];

    return(theAttributedString);
    }

@end
