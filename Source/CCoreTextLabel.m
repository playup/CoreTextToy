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

#import "UIFont_CoreTextExtensions.h"
#import "CMarkupValueTransformer.h"

@interface CCoreTextLabel ()
@property (readonly, nonatomic, assign) CTFramesetterRef framesetter;

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer;
@end

@implementation CCoreTextLabel

@synthesize text;
@synthesize URLHandler;

@synthesize framesetter;

+ (CGSize)sizeForString:(NSAttributedString *)inString ThatFits:(CGSize)size
    {
    CTFramesetterRef theFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)inString);
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(theFramesetter, (CFRange){ .length = inString.length }, NULL, size, NULL);
    CFRelease(theFramesetter);
    return(theSize);
    }

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
        }
    return(self);
    }

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
        }
    return(self);
    }

- (void)dealloc
    {
    if (framesetter)
        {
        CFRelease(framesetter);
        framesetter = NULL;
        }
    }

- (CTFramesetterRef)framesetter
    {
    if (framesetter == NULL)
        {
        if (self.text)
            {
            framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.text);
            }
        }
    return(framesetter);
    }

- (void)setText:(NSAttributedString *)inText
    {
    if (text != inText)
        {
        text = inText;

        if (framesetter)
            {
            CFRelease(framesetter);
            framesetter = NULL;
            }

        [self setNeedsDisplay];
        }
    }

- (CGSize)sizeThatFits:(CGSize)size
    {
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){ .length = self.text.length }, NULL, size, NULL);
    return(theSize);
    }

- (void)drawRect:(CGRect)rect
    {
    if (self.framesetter)
        {
        UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:self.bounds];

        CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){ .length = [self.text length] }, thePath.CGPath, NULL);

        CGContextRef theContext = UIGraphicsGetCurrentContext();

        CGContextSaveGState(theContext);

        CGContextScaleCTM(theContext, 1.0, -1.0);
        CGContextTranslateCTM(theContext, 0.0, -self.bounds.size.height);

        CTFrameDraw(theFrame, theContext);

        CGContextRestoreGState(theContext);

        CFRelease(theFrame);
        }
    }

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer
    {
    CGPoint theLocation = [inGestureRecognizer locationInView:self];

    theLocation.y *= -1;
    theLocation.y += self.bounds.size.height;

    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:self.bounds];

    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){ .length = [self.text length] }, thePath.CGPath, NULL);

    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);

    __block CGPoint theLastLineOrigin = (CGPoint){ 0, CGFLOAT_MAX };

    [theLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {


        CGPoint theLineOrigin;
        CTFrameGetLineOrigins(theFrame, CFRangeMake(idx, 1), &theLineOrigin);

        if (theLocation.y > theLineOrigin.y && theLocation.y < theLastLineOrigin.y)
            {
            CTLineRef theLine = (__bridge CTLineRef)obj;

            CFIndex theIndex = CTLineGetStringIndexForPosition(theLine, (CGPoint){ .x = theLocation.x - theLineOrigin.x, theLocation.y - theLineOrigin.y });
            if (theIndex != NSNotFound && (NSUInteger)theIndex < self.text.length)
                {
                NSDictionary *theAttributes = [self.text attributesAtIndex:theIndex effectiveRange:NULL];
                NSURL *theLink = [theAttributes objectForKey:@"link"];
                if (self.URLHandler)
                    {
                    self.URLHandler(theLink);
                    }
                }
            }
        theLastLineOrigin = theLineOrigin;
        }];
    }


@end

