//
//  CMarkupValueTransformer.m
//  CoreText
//
//  Created by Jonathan Wight on 07/15/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CMarkupValueTransformer.h"

#import <CoreText/CoreText.h>

#import "UIFont_CoreTextExtensions.h"
#import "CMarkupValueTransformer.h"
#import "CSimpleHTMLParser.h"

@interface CMarkupValueTransformer ()
@property (readwrite, nonatomic, retain) UIFont *standardFont;
@property (readwrite, nonatomic, retain) NSSet *supportedTags;
@property (readwrite, nonatomic, retain) NSMutableDictionary *attributesForTagSets;

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack;
@end

#pragma mark -

@implementation CMarkupValueTransformer

@synthesize standardFont;
@synthesize supportedTags;
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
        
        supportedTags = [NSSet setWithObjects:@"b", @"i", NULL];
        
        attributesForTagSets = [NSMutableDictionary dictionary];
        
        NSDictionary *theAttributes = NULL;


        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)self.standardFont.CTFont, (__bridge NSString *)kCTFontAttributeName,
            NULL];
        [attributesForTagSets setObject:theAttributes forKey:[NSSet set]];

        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)[self.standardFont boldItalicFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
            NULL];
        [attributesForTagSets setObject:theAttributes forKey:[NSSet setWithObjects:@"b", @"i", NULL]];

        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)[self.standardFont boldFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
            NULL];
        [attributesForTagSets setObject:theAttributes forKey:[NSSet setWithObjects:@"b", NULL]];

        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)[self.standardFont italicFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
            NULL];
        [attributesForTagSets setObject:theAttributes forKey:[NSSet setWithObjects:@"i", NULL]];
        
        // TODO generate supported tags from attributesForTagSets keys.
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
  
    __block NSDictionary *theAttributes = NULL;  
  
    CSimpleHTMLParser *theParser = [[CSimpleHTMLParser alloc] init];
    
    theParser.openTagHandler = ^(NSString *inTag, NSArray *tagStack) {
        if ([inTag isEqualToString:@"br"])
            {
            [theAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:theAttributes]];
            }
        };

    theParser.closeTagHandler = ^(NSString *inTag, NSArray *tagStack) {
        };
    

    theParser.textHandler = ^(NSString *inString, NSArray *tagStack) {
        theAttributes = [self attributesForTagStack:tagStack];
        [theAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:inString attributes:theAttributes]];
        };
    
    
    if ([theParser parseString:theMarkup error:outError] == NO)
        {
        return(NULL);
        }

    return([theAttributedString copy]);
    }

#pragma mark -

- (NSDictionary *)attributesForTagStack:(NSArray *)inTagStack
    {
    NSMutableSet *theStyles = [NSMutableSet set];

    BOOL theSmallFlag = NO;

    NSMutableDictionary *theAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        NULL];
    
    for (NSString *theTag in inTagStack)
        {
        if ([theTag isEqualToString:@"b"] || [theTag isEqualToString:@"strong"])
            {
            [theStyles addObject:@"Bold"];
            }
        else if ([theTag isEqualToString:@"i"] || [theTag isEqualToString:@"em"] || [theTag isEqualToString:@"cite"] || [theTag isEqualToString:@"var"])
            {
            [theStyles addObject:@"Italic"];
            }
        else if ([theTag isEqualToString:@"ins"])
            {
            [theAttributes setObject:[NSNumber numberWithInt:kCTUnderlineStyleSingle] forKey:(__bridge id)kCTUnderlineStyleAttributeName];
            }
        else if ([theTag isEqualToString:@"small"])
            {
            theSmallFlag = YES;
            }
        }
    
    UIFont *theFont = self.standardFont;
    
    if ([theStyles containsObject:@"Bold"] && [theStyles containsObject:@"Italic"])
        {
        theFont = [theFont boldItalicFont];
        }
    else if ([theStyles containsObject:@"Bold"])
        {
        theFont = [theFont boldFont];
        }
    else if ([theStyles containsObject:@"Italic"])
        {
        theFont = [theFont italicFont];
        }

    if (theSmallFlag == YES)
        {
        theFont = [theFont fontWithSize:theFont.pointSize - 3];
        }


    [theAttributes setObject:(__bridge_transfer id)theFont.CTFont forKey:(__bridge NSString *)kCTFontAttributeName];
    
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