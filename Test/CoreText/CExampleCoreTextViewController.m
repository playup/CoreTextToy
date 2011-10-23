//
//  CExampleCoreTextViewController.m
//  CoreText
//
//  Created by Jonathan Wight on 10/23/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CExampleCoreTextViewController.h"

#import <CoreText/CoreText.h>

#import "CCoreTextLabel.h"
#import "CMarkupValueTransformer.h"
#import "UIFont_CoreTextExtensions.h"
#import "NSAttributedString_DebugExtensions.h"

@implementation CExampleCoreTextViewController

@synthesize label1;
@synthesize label2;

- (void)viewDidLoad
    {
    [super viewDidLoad];
    

    NSError *theError = NULL;
    CMarkupValueTransformer *theTransformer = [[CMarkupValueTransformer alloc] init];
    NSDictionary *theAttributes = NULL;

    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor colorWithRed:0.761 green:0.486 blue:0.165 alpha:1.000].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
        (__bridge id)[theTransformer.standardFont boldFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
        NULL];
    [theTransformer addStyleAttributes:theAttributes forTagSet:[NSSet setWithObject:@"username"]];
    theTransformer.defaultTextColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    
    NSString *theMarkup = NULL;
    id theAttributedString = NULL;
    
    // ### 1st line...

    theMarkup = @"<b>Craig Hockenberry</b> <img src=\"reply-badge.png\"> <small>to you</small>";
    theAttributedString = [theTransformer transformedValue:theMarkup error:&theError];
    NSLog(@"%@", [theAttributedString betterDescription]);

    // We make a copy of the string, and tell it to use truncating tail line break mode...
    theAttributedString = [theAttributedString mutableCopy];
    CTLineBreakMode theLineBreakMode = kCTLineBreakByTruncatingTail;
    CTParagraphStyleSetting theSetting = { 
        .spec = kCTParagraphStyleSpecifierLineBreakMode,
        .valueSize = sizeof(theLineBreakMode),
        .value = &theLineBreakMode,
        };
    CTParagraphStyleRef theParagraphStyle = CTParagraphStyleCreate( &theSetting, 1 );
    theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)theParagraphStyle, (__bridge id)kCTParagraphStyleAttributeName,
        NULL];
    [theAttributedString addAttributes:theAttributes range:(NSRange){ .length = [theAttributedString length] }];

    self.label1.text = theAttributedString;

    // ### 2nd line...

    theMarkup = @"<username>@schwa</username> RUBBERS";
    theAttributedString = [theTransformer transformedValue:theMarkup error:&theError];
    self.label2.text = theAttributedString;









    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

@end
