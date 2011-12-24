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

NSString *const kMarkupLinkAttributeName = @"com.touchcode.link";
NSString *const kMarkupBoldAttributeName = @"com.touchcode.bold";
NSString *const kMarkupItalicAttributeName = @"com.touchcode.italic";
NSString *const kMarkupSizeAdjustmentAttributeName = @"com.touchcode.sizeAdjustment";
NSString *const kMarkupAttachmentAttributeName = @"com.touchcode.attachment";
NSString *const kMarkupTextColorAttributeName = @"com.touchcode.textColor";

@interface CMarkupValueTransformer ()
@property (readwrite, nonatomic, strong) NSMutableArray *attributesForTags;

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack;
+ (NSDictionary *)normalizeAttributes:(NSDictionary *)inAttributes baseFont:(UIFont *)inBaseFont;
@end

#pragma mark -

@implementation CMarkupValueTransformer

@synthesize attributesForTags;

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
        attributesForTags = [NSMutableArray array];

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
    __block NSString *theCurrentColor = NULL;

    CSimpleHTMLParser *theParser = [[CSimpleHTMLParser alloc] init];

    theParser.openTagHandler = ^(NSString *inTag, NSDictionary *inAttributes, NSArray *tagStack) {
        if ([inTag isEqualToString:@"a"] == YES)
            {
            NSString *theURLString = [inAttributes objectForKey:@"href"];
            if ((id)theURLString != [NSNull null] && theURLString.length > 0)
                {
                theCurrentLink = [NSURL URLWithString:theURLString];
                }
            }
        else if ([inTag isEqualToString:@"font"] == YES)
        {
            NSString *theURLString = [inAttributes objectForKey:@"color"];
            if ((id)theURLString != [NSNull null] && theURLString.length > 0)
            {
                theCurrentColor = [NSString stringWithString:theURLString];
            }            
        }
        else if ([inTag isEqualToString:@"img"] == YES)
            {
            id theImageSource = [inAttributes objectForKey:@"src"];
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

    theParser.closeTagHandler = ^(NSString *inTag, NSArray *tagStack) {
        if ([inTag isEqualToString:@"a"] == YES|| [inTag isEqualToString:@"font"] == YES)
        {
            theCurrentLink = NULL;
            theCurrentColor = NULL;
        }
    };

    theParser.textHandler = ^(NSString *inString, NSArray *tagStack) {
        NSDictionary *theAttributes = [self attributesForTagStack:tagStack];
        theTextAttributes = [theAttributes mutableCopy];

        if (theCurrentLink != NULL)
            {
            [theTextAttributes setObject:theCurrentLink forKey:kMarkupLinkAttributeName];
            }
        
        if (theCurrentColor != NULL)
        {
            [theTextAttributes setObject:theCurrentColor forKey:kMarkupTextColorAttributeName];
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
    self.attributesForTags = [NSMutableArray array];
    }

- (void)addStandardStyles
    {
    NSDictionary *theAttributes = NULL;

    // ### b
    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], kMarkupBoldAttributeName,
        NULL];
    [self addStyleAttributes:theAttributes forTag:@"b"];

    // ### i
    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], kMarkupItalicAttributeName,
        NULL];
    [self addStyleAttributes:theAttributes forTag:@"i"];

    // ### a
    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor blueColor].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
        [NSNumber numberWithInt:kCTUnderlineStyleSingle], (__bridge id)kCTUnderlineStyleAttributeName,
        NULL];
    [self addStyleAttributes:theAttributes forTag:@"a"];

    // ### mark
    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor yellowColor].CGColor, @"backgroundColor",
        NULL];
    [self addStyleAttributes:theAttributes forTag:@"mark"];

    // ### strike
    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor blackColor].CGColor, @"strikeColor",
        NULL];
    [self addStyleAttributes:theAttributes forTag:@"strike"];

    // ### small
    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithFloat:-4], kMarkupSizeAdjustmentAttributeName,
        NULL];
    [self addStyleAttributes:theAttributes forTag:@"small"];
    }

- (void)addStyleAttributes:(NSDictionary *)inAttributes forTag:(NSString *)inTag
    {
    [self.attributesForTags addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            inAttributes, @"attributes",
            inTag, @"tag",
            NULL]
        ];
    }

- (void)removeStyleAttributesForTag:(NSString *)inTag
    {
    NSMutableArray *theNewAttributesForTags = [NSMutableArray array];
    
    [self.attributesForTags enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *theTag = [obj objectForKey:@"tag"];
        if ([theTag isEqualToString:inTag] == NO)
            {
            [theNewAttributesForTags addObject:obj];
            }
        }];
    
    self.attributesForTags = theNewAttributesForTags;
    }

#pragma mark -

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack
    {
    NSSet *theTagSet = [NSSet setWithArray:inTagStack];
    NSMutableDictionary *theAttributes = [NSMutableDictionary dictionary];
    
    for (NSDictionary *theDictionary in self.attributesForTags)
        {
        NSString *theTag = [theDictionary objectForKey:@"tag"];

        if ([theTagSet containsObject:theTag])
            {
            [theAttributes addEntriesFromDictionary:[theDictionary objectForKey:@"attributes"]];
            }
        }

    return(theAttributes);
    }

+ (NSDictionary *)normalizeAttributes:(NSDictionary *)inAttributes baseFont:(UIFont *)inBaseFont
    {
    NSMutableDictionary *theAttributes = [inAttributes mutableCopy];
    
    UIFont *theFont = inBaseFont;
    
    // NORMALIZE ATTRIBUTES
    BOOL theBoldFlag = [[theAttributes objectForKey:kMarkupBoldAttributeName] boolValue];
    if ([theAttributes objectForKey:kMarkupBoldAttributeName] != NULL)
        {
        [theAttributes removeObjectForKey:kMarkupBoldAttributeName];
        }

    BOOL theItalicFlag = [[theAttributes objectForKey:kMarkupItalicAttributeName] boolValue];
    if ([theAttributes objectForKey:kMarkupItalicAttributeName] != NULL)
        {
        [theAttributes removeObjectForKey:kMarkupItalicAttributeName];
        }
    
    if (theBoldFlag == YES && theItalicFlag == YES)
        {
        theFont = inBaseFont.boldItalicFont;
        }
    else if (theBoldFlag == YES)
        {
        theFont = inBaseFont.boldFont;
        }
    else if (theItalicFlag == YES)
        {
        theFont = inBaseFont.italicFont;
        }
        
    NSNumber *theSizeValue = [theAttributes objectForKey:kMarkupSizeAdjustmentAttributeName];
    if (theSizeValue != NULL)
        {
        CGFloat theSize = [theSizeValue floatValue];
        theFont = [theFont fontWithSize:theFont.pointSize + theSize];
        
        [theAttributes removeObjectForKey:kMarkupSizeAdjustmentAttributeName];
        }

    if (theFont != NULL)
        {
        [theAttributes setObject:(__bridge id)theFont.CTFont forKey:(__bridge NSString *)kCTFontAttributeName];
        }
        
    return(theAttributes);
    }
    
+ (NSAttributedString *)normalizedAttributedStringForAttributedString:(NSAttributedString *)inAttributedString baseFont:(UIFont *)inBaseFont
    {
    NSMutableAttributedString *theString = [inAttributedString mutableCopy];
    
    [theString enumerateAttributesInRange:(NSRange){ .length = theString.length } options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        UIFont *theFont = inBaseFont;
        CTFontRef theCTFont = (__bridge CTFontRef)[attrs objectForKey:(__bridge NSString *)kCTFontAttributeName];
        if (theCTFont != NULL)
            {
            theFont = [UIFont fontWithCTFont:theCTFont];
            }
        
        attrs = [self normalizeAttributes:attrs baseFont:theFont];
        [theString setAttributes:attrs range:range];
        }];
    return(theString);
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
