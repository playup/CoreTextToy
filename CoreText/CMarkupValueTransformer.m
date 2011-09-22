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
@property (readwrite, nonatomic, retain) NSMutableArray *attributesForTagSets;

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

        theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)[UIColor purpleColor].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
            NULL];
        [attributesForTagSets addObject:
            [NSDictionary dictionaryWithObjectsAndKeys:
                theAttributes, @"attributes",
                [NSSet setWithObjects:@"purple", NULL], @"tags",
                NULL]
            ];
        
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
  
    __block NSMutableDictionary *theTextAttributes = NULL;  
    __block NSURL *theCurrentLink = NULL;
  
    CSimpleHTMLParser *theParser = [[CSimpleHTMLParser alloc] init];
    
    theParser.openTagHandler = ^(NSString *inTag, NSDictionary *inAttributes, NSArray *tagStack) {
    
        if ([inTag isEqualToString:@"a"] == YES)
            {
            NSString *theURLString = [inAttributes objectForKey:@"href"];
            theCurrentLink = [NSURL URLWithString:theURLString];
            }
    
        if ([inTag isEqualToString:@"br"])
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