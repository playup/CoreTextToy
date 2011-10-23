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

@implementation CExampleCoreTextViewController

@synthesize label1;

- (void)viewDidLoad
    {
    [super viewDidLoad];
    
    NSString *theMarkup = @"<b>Craig Hockenberry</b> <img src=\"reply-badge.png\"> <small>to you</small><br><username>@schwa</username> RUBBERS";

    NSError *theError = NULL;
    CMarkupValueTransformer *theTransformer = [[CMarkupValueTransformer alloc] init];

    NSDictionary *theUsernameAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor colorWithRed:0.761 green:0.486 blue:0.165 alpha:1.000].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
        (__bridge id)[theTransformer.standardFont boldFont].CTFont, (__bridge NSString *)kCTFontAttributeName,
        NULL];
    [theTransformer addStyleAttributes:theUsernameAttributes forTagSet:[NSSet setWithObject:@"username"]];
    
    theTransformer.defaultTextColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    
    NSAttributedString *theAttributedString = [theTransformer transformedValue:theMarkup error:&theError];

    self.label1.text = theAttributedString;
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

@end
