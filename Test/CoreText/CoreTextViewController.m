//
//  CoreTextViewController.m
//  CoreText
//
//  Created by Jonathan Wight on 07/12/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CoreTextViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "CMarkupValueTransformer.h"
#import "CCoreTextLabel.h"

@interface CoreTextViewController () <UITextViewDelegate>
@end

#pragma mark -

@implementation CoreTextViewController

@synthesize editView;
@synthesize previewView;

- (void)viewDidLoad
    {
    self.previewView.text = [NSAttributedString attributedStringWithMarkup:self.editView.text error:NULL];
    
    self.previewView.layer.borderWidth = 1.0;
    self.previewView.layer.borderColor = [UIColor redColor].CGColor;
    self.previewView.URLHandler = ^(NSURL *inURL) {
        UIAlertView *theAlertView = [[UIAlertView alloc] initWithTitle:@"URL" message:[NSString stringWithFormat:@"You tapped: %@", [inURL absoluteString]] delegate:NULL cancelButtonTitle:@"What's it to you?" otherButtonTitles:NULL];
        [theAlertView show];
        };
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return YES;
    }

- (void)textViewDidChange:(UITextView *)textView;
    {
    NSError *theError = NULL;
    NSAttributedString *theText = [NSAttributedString attributedStringWithMarkup:self.editView.text error:&theError];
    if (theText == NULL)
        {
        theText = [[NSAttributedString alloc] initWithString:[theError description]];
        }
    
    self.previewView.text = theText;
    }

@end
