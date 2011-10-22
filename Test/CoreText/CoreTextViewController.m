//
//  CoreTextViewController.m
//  TouchCode
//
//  Created by Jonathan Wight on 07/12/11.
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

#import "CoreTextViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "CMarkupValueTransformer.h"
#import "CCoreTextLabel.h"

@interface CoreTextViewController () <UITextViewDelegate>
@end

#pragma mark -

@implementation CoreTextViewController

@synthesize editView;
@synthesize attributedView;
@synthesize previewView;

- (void)viewDidLoad
    {
    self.previewView.layer.borderWidth = 1.0;
    self.previewView.layer.borderColor = [UIColor blackColor].CGColor;
    self.previewView.insets = (UIEdgeInsets){
        .left = 8.0, .right = 8.0,
        .top = 8.0, .bottom = 0.0,
        };
    self.previewView.URLHandler = ^(NSURL *inURL) {
        UIAlertView *theAlertView = [[UIAlertView alloc] initWithTitle:@"URL" message:[NSString stringWithFormat:@"You tapped: %@", [inURL absoluteString]] delegate:NULL cancelButtonTitle:@"What's it to you?" otherButtonTitles:NULL];
        [theAlertView show];
        };

    [self textViewDidChange:NULL];
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

    self.attributedView.text = [theText description];
    self.previewView.text = theText;
    }

@end
