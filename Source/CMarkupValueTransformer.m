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



@interface CMarkupValueTransformer ()
@property (readwrite, nonatomic, strong) NSMutableArray *attributesForTagSets;

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack;
@end

#pragma mark -

@implementation CMarkupValueTransformer

@synthesize standardFont;
@synthesize attributesForTagSets;

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
        standardFont = [UIFont fontWithName:@"Helvetica" size:16.0];

        attributesForTagSets = [NSMutableArray array];

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

    theParser.openTagHandler = ^(NSString *inTag, NSDictionary *inAttributes, NSArray *tagStack) {

        if ([inTag isEqualToString:@"a"] == YES)
            {
            NSString *theURLString = [inAttributes objectForKey:@"href"];
            theCurrentLink = [NSURL URLWithString:theURLString];
            }
        else if ([inTag isEqualToString:@"img"] == YES)
            {
            NSString *theImageSource = [inAttributes objectForKey:@"src"];
            UIImage *theImage = [UIImage imageNamed:theImageSource];
            if (theImage == NULL)
                {
                theImage = [UIImage imageNamed:@"MissingImage.png"];
                }
            if (theImage != NULL)
                {
                NSDictionary *theImageAttributes = [NSDictionary dictionaryWithObject:theImage forKey:@"image"];
                // U+FFFC is the "object replacment character" (thanks to Jens Ayton for the pointer) - doesn't work - takes up actual space.
                // U+2061 is the "FUNCTION APPLICATION" character - doesn't work gets striped.
                // 200B zero width space
                [theAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"." attributes:theImageAttributes]];
                }
            }
        else if ([inTag isEqualToString:@"br"] == YES)
            {
            [theAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:theTextAttributes]];
            }
        };

    theParser.closeTagHandler = ^(NSString *inTag, NSArray *tagStack) {

        if ([inTag isEqualToString:@"a"] == YES)
            {
            theCurrentLink = NULL;
            }

        };

    theParser.textHandler = ^(NSString *inString, NSArray *tagStack) {
        theTextAttributes = [[self attributesForTagStack:tagStack] mutableCopy];

        if (theCurrentLink != NULL)
            {
            [theTextAttributes setObject:theCurrentLink forKey:@"link"];
            }

        [theAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:inString attributes:theTextAttributes]];
        };


    if ([theParser parseString:theMarkup error:outError] == NO)
        {
        return(NULL);
        }

    return([theAttributedString copy]);
    }

- (void)resetStyles
    {
    self.attributesForTagSets = [NSMutableArray array];

    NSDictionary *theAttributes = NULL;

    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)self.standardFont.CTFont, (__bridge NSString *)kCTFontAttributeName,
        NULL];
    [attributesForTagSets addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            theAttributes, @"attributes",
            [NSSet set], @"tags",
            NULL]
        ];
    }

- (void)addStandardStyles
    {
    NSDictionary *theAttributes = NULL;

    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[self.standardFont boldFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
        NULL];
    [attributesForTagSets addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            theAttributes, @"attributes",
            [NSSet setWithObjects:@"b", NULL], @"tags",
            NULL]
        ];

    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[self.standardFont italicFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
        NULL];
    [attributesForTagSets addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            theAttributes, @"attributes",
            [NSSet setWithObjects:@"i", NULL], @"tags",
            NULL]
        ];

    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[self.standardFont boldItalicFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
        NULL];
    [attributesForTagSets addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            theAttributes, @"attributes",
            [NSSet setWithObjects:@"b", @"i", NULL], @"tags",
            NULL]
        ];

    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor blueColor].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
        [NSNumber numberWithInt:kCTUnderlineStyleSingle], (__bridge id)kCTUnderlineStyleAttributeName,
        NULL];
    [attributesForTagSets addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            theAttributes, @"attributes",
            [NSSet setWithObjects:@"a", NULL], @"tags",
            NULL]
        ];
    }

- (void)addStyleAttributes:(NSDictionary *)inAttributes forTagSet:(NSSet *)inTagSet
    {
    [self.attributesForTagSets addObject:
        [NSDictionary dictionaryWithObjectsAndKeys:
            inAttributes, @"attributes",
            inTagSet, @"tags",
            NULL]
        ];
    }

#pragma mark -

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack
    {
    NSSet *theTagSet = [NSSet setWithArray:inTagStack];
    NSMutableDictionary *theAttributes = [NSMutableDictionary dictionary];
    for (NSDictionary *theDictionary in self.attributesForTagSets)
        {
        NSSet *theTags = [theDictionary objectForKey:@"tags"];

        if (theTags.count == 0 || [theTags isSubsetOfSet:theTagSet])
            {
            [theAttributes addEntriesFromDictionary:[theDictionary objectForKey:@"attributes"]];
            }
        }

    return(theAttributes);
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
