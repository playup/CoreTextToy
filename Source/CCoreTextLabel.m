//
//  CCoreTextLabel.m
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

#import "CCoreTextLabel.h"

#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "CCoreTextRenderer.h"

@interface CCoreTextLabel ()
@property (readwrite, nonatomic, retain) CCoreTextRenderer *renderer;

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer;
@end

@implementation CCoreTextLabel

@synthesize insets;
@synthesize URLHandler;

@synthesize renderer;

+ (CGSize)sizeForString:(NSAttributedString *)inString ThatFits:(CGSize)size
    {
    return([CCoreTextRenderer sizeForString:inString ThatFits:size]);
    }

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
        }
    return(self);
    }

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
        }
    return(self);
    }

- (NSAttributedString *)text
    {
    return(self.renderer.text);
    }

- (void)setText:(NSAttributedString *)inText
    {
    self.renderer = [[CCoreTextRenderer alloc] initWithText:inText size:self.bounds.size];
    [self setNeedsDisplay];
    }
    
- (CGSize)sizeThatFits:(CGSize)size
    {
    return([self.renderer sizeThatFits:size]);
    }

- (void)drawRect:(CGRect)rect
    {
    // ### Work out the inset bounds...
    CGRect theBounds = self.bounds;
    theBounds = UIEdgeInsetsInsetRect(theBounds, self.insets);

    // ### Get and set up the context...
    CGContextRef theContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(theContext);
    CGContextTranslateCTM(theContext, theBounds.origin.x, theBounds.origin.y);
    
    [self.renderer draw];

    CGContextRestoreGState(theContext);    
    }

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer
    {
    CGPoint theLocation = [inGestureRecognizer locationInView:self];
    theLocation.x -= self.insets.left;
    theLocation.y -= self.insets.top;

    NSDictionary *theAttributes = [self.renderer attributesAtPoint:theLocation];
    NSURL *theLink = [theAttributes objectForKey:@"link"];
    if (theLink != NULL)
        {
        if (self.URLHandler != NULL)
            {
            self.URLHandler(theLink);
            }
        }
    }

@end
