//
//  CExampleCoreTextViewController.m
//  CoreText
//
//  Created by Jonathan Wight on 10/23/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CExampleCoreTextViewController.h"

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "CCoreTextLabel.h"
#import "CCoreTextLabel_HTMLExtensions.h"
#import "CMarkupValueTransformer.h"
#import "UIFont_CoreTextExtensions.h"
#import "NSAttributedString_DebugExtensions.h"

@implementation CExampleCoreTextViewController

@synthesize label1;
@synthesize label2;
@synthesize label3;

- (void)viewDidLoad
    {
    [super viewDidLoad];
    
    // #########################################################################

    // ### 1st line...

    self.label1.lineBreakMode = UILineBreakModeTailTruncation;
    self.label1.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    self.label1.markup = @"<b>Craig Hockenberry</b> <img src=\"reply-badge.png\" baseline=\"-2\"> <small>to you</small>";

    // #########################################################################

    NSDictionary *theAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
        (__bridge id)[UIColor colorWithRed:0.761 green:0.486 blue:0.165 alpha:1.000].CGColor, (__bridge NSString *)kCTForegroundColorAttributeName,
        [NSNumber numberWithInt:1], @"BOLD",
        NULL];


    [self.label2.markupValueTransformer addStyleAttributes:theAttributes forTag:@"username"];
    self.label2.lineBreakMode = UILineBreakModeWordWrap;
    self.label2.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    self.label2.markup = @"<username>@schwa</username> RUBBERS";
    
    // #########################################################################
    
    [self.label3.markupValueTransformer removeStyleAttributesForTag:@"a"];

    self.label3.textColor = [UIColor whiteColor];
    self.label3.lineBreakMode = UILineBreakModeWordWrap;
    self.label3.markup = @"<a href=\"link1\">@LINK1</a> The quick brown fox jumped over the lazy dog 1234567890 <a href=\"link2\">@LINK2</a> times.";
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }
    
@end
