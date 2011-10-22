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

static CGFloat MyCTRunDelegateGetAscentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon);

@interface CCoreTextLabel ()
@property (readonly, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, retain) NSAttributedString *normalizedText;

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer;
@end

@implementation CCoreTextLabel

@synthesize text;
@synthesize insets;
@synthesize URLHandler;

@synthesize framesetter;
@synthesize normalizedText;

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
        if (self.text != NULL)
            {
            framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.normalizedText);
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

        self.normalizedText = NULL;

        [self setNeedsDisplay];
        }
    }

- (NSAttributedString *)normalizedText
    {
    if (normalizedText == NULL)
        {
        NSMutableAttributedString *theString = [self.text mutableCopy];

        CTRunDelegateCallbacks theCallbacks = {
            .version = kCTRunDelegateVersion1,
            .getAscent = MyCTRunDelegateGetAscentCallback,
            .getDescent = MyCTRunDelegateGetDescentCallback,
            .getWidth = MyCTRunDelegateGetWidthCallback,
            };
        
        [theString enumerateAttribute:@"image" inRange:(NSRange){ .length = theString.length } options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value)
                {
                CTRunDelegateRef theImageDelegate = CTRunDelegateCreate(&theCallbacks, (__bridge void *)value);
                CFAttributedStringSetAttribute((__bridge CFMutableAttributedStringRef)theString, (CFRange) { .location = range.location, .length = range.length }, kCTRunDelegateAttributeName, theImageDelegate);
                CFRelease(theImageDelegate);
                }
            }];
        
        normalizedText = [theString copy];
        }
    return(normalizedText);
    }

- (CGSize)sizeThatFits:(CGSize)size
    {
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){ .length = self.text.length }, NULL, size, NULL);
    return(theSize);
    }

- (void)drawRect:(CGRect)rect
    {
    if (self.framesetter == NULL)
        {
        return;
        }
        
    // ### Work out the inset bounds...
    CGRect theBounds = self.bounds;
    theBounds = UIEdgeInsetsInsetRect(theBounds, self.insets);

    // ### Get and set up the context...
    CGContextRef theContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(theContext);
    CGContextScaleCTM(theContext, 1.0, -1.0);
    CGContextTranslateCTM(theContext, 0.0, -theBounds.size.height);

    // ### Create a frame...
    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:theBounds];
    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){ .length = [self.text length] }, thePath.CGPath, NULL);

    // ### Render the text...
    CTFrameDraw(theFrame, theContext);

    // ### Reset the text position (important!)
    CGContextSetTextPosition(theContext, 0, 0);
    
    // ### Get the lines and the line origin points...
    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);
    // TODO this could blow the stack...
    CGPoint theLineOrigins[theLines.count];
    CTFrameGetLineOrigins(theFrame, (CFRange){}, theLineOrigins); 

    // ### Iterate through each line...
    NSUInteger idx = 0;
    for (id obj in theLines)
        {
        CTLineRef theLine = (__bridge CTLineRef)obj;

        // ### Get the line rect offseting it by the line origin
        CGRect theLineRect = CTLineGetImageBounds(theLine, theContext);     
        theLineRect.origin.x += theLineOrigins[idx].x;
        theLineRect.origin.y += theLineOrigins[idx].y;
        
        // ### Iterate each run... Keeping track of our X position...
        CGFloat theXPosition = 0;
        NSArray *theRuns = (__bridge NSArray *)CTLineGetGlyphRuns(theLine);
        for (id oneRun in theRuns)
            {
            CTRunRef theRun = (__bridge CTRunRef)oneRun;
            
            // ### Get the ascent, descent, leading, width and produce a rect for the run...
            CGFloat theAscent, theDescent, theLeading;
            CGFloat theWidth = CTRunGetTypographicBounds(theRun, (CFRange){}, &theAscent, &theDescent, &theLeading);
            CGRect theRunRect = {
                .origin = { theLineRect.origin.x + theXPosition, theLineRect.origin.y },
                .size = { theWidth, theAscent + theDescent },
                };

            // ### Optionally stroke the run rect...
            if (1)
                {
                CGRect theStrokeRect = theRunRect;
                theStrokeRect.origin.x = floor(theStrokeRect.origin.x) + 0.5;
                theStrokeRect.origin.y = floor(theStrokeRect.origin.y) + 0.5;
                theStrokeRect.size.width = floor(theStrokeRect.size.width) - 1.0;
                theStrokeRect.size.height = floor(theStrokeRect.size.height) - 1.0;
                
                CGContextSaveGState(theContext);
                CGContextSetStrokeColorWithColor(theContext, [UIColor redColor].CGColor);
                CGContextSetLineWidth(theContext, 0.5);
                CGContextStrokeRect(theContext, theStrokeRect);
                CGContextRestoreGState(theContext);
                }

            // ### Get the attributes...
            NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(theRun);
            
            // ### If we have an image we draw it...
            UIImage *theImage = [theAttributes objectForKey:@"image"];
            if (theImage != NULL)
                {
                // We use CGContextDrawImage because it understands the CTM
                CGContextDrawImage(theContext, theRunRect, theImage.CGImage);
                }

            theXPosition += theWidth;
            }

        idx++;
        }

    CFRelease(theFrame);

    CGContextRestoreGState(theContext);
    }

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer
    {
    CGPoint theLocation = [inGestureRecognizer locationInView:self];

    // ### Work out the inset bounds...
    CGRect theBounds = self.bounds;
    theBounds = UIEdgeInsetsInsetRect(theBounds, self.insets);


    theLocation.y *= -1;
    theLocation.y += theBounds.size.height;

    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:theBounds];

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

static CGFloat MyCTRunDelegateGetAscentCallback(void *refCon)
    {
    UIImage *theImage = (__bridge UIImage *)refCon;
    return(theImage.size.height);
    }

static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon)
    {
    return(0.0);
    }

static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon)
    {
    UIImage *theImage = (__bridge UIImage *)refCon;
    return(theImage.size.width);
    }



