//
//  CCoreTextRenderer.m
//  CoreText
//
//  Created by Jonathan Wight on 10/22/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CCoreTextRenderer.h"


#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

#import "UIFont_CoreTextExtensions.h"
#import "CMarkupValueTransformer.h"

static CGFloat MyCTRunDelegateGetAscentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon);

@interface CCoreTextRenderer ()
@property (readonly, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, retain) NSAttributedString *normalizedText;

//- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer;
@end

@implementation CCoreTextRenderer

@synthesize text;
@synthesize size;

@synthesize framesetter;
@synthesize normalizedText;

+ (CGSize)sizeForString:(NSAttributedString *)inString ThatFits:(CGSize)size
    {
    #warning TODO -- this doesn't support images or insets yet...
    CTFramesetterRef theFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)inString);
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(theFramesetter, (CFRange){ .length = inString.length }, NULL, size, NULL);
    CFRelease(theFramesetter);
    return(theSize);
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

- (CGSize)sizeThatFits:(CGSize)inSize
    {
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){ .length = self.normalizedText.length }, NULL, inSize, NULL);
    return(theSize);
    }

- (void)draw
    {
    if (self.framesetter == NULL)
        {
        return;
        }
        
    // ### Work out the inset bounds...

    // ### Get and set up the context...
    CGContextRef theContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(theContext);


    CGContextScaleCTM(theContext, 1.0, -1.0);
    CGContextTranslateCTM(theContext, 0, -self.size.height);

    // ### Create a frame...
    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:(CGRect){ .size = self.size }];
    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){ .length = [self.normalizedText length] }, thePath.CGPath, NULL);

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
            if (0)
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

- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint
    {
    inPoint.y *= -1;
    inPoint.y += self.size.height;

    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:(CGRect){ .size = self.size }];

    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){ .length = [self.normalizedText length] }, thePath.CGPath, NULL);

    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);

    __block CGPoint theLastLineOrigin = (CGPoint){ 0, CGFLOAT_MAX };
    __block NSDictionary *theAttributes = NULL;

    [theLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        CGPoint theLineOrigin;
        CTFrameGetLineOrigins(theFrame, CFRangeMake(idx, 1), &theLineOrigin);

        if (inPoint.y > theLineOrigin.y && inPoint.y < theLastLineOrigin.y)
            {
            CTLineRef theLine = (__bridge CTLineRef)obj;

            CFIndex theIndex = CTLineGetStringIndexForPosition(theLine, (CGPoint){ .x = inPoint.x - theLineOrigin.x, inPoint.y - theLineOrigin.y });
            if (theIndex != NSNotFound && (NSUInteger)theIndex < self.normalizedText.length)
                {
                theAttributes = [self.normalizedText attributesAtIndex:theIndex effectiveRange:NULL];
                *stop = YES;
                }
            }
        theLastLineOrigin = theLineOrigin;
        }];
        
    return(theAttributes);
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

