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

//#define CORE_TEXT_SHOW_RUNS 1

static CGFloat MyCTRunDelegateGetAscentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon);
static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon);

@interface CCoreTextRenderer ()
@property (readonly, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, retain) NSAttributedString *normalizedText;

- (void)enumerateRunsForLines:(CFArrayRef)inLines lineOrigins:(CGPoint *)inLineOrigins handler:(void (^)(CTRunRef, CGRect))inHandler;
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

- (id)initWithText:(NSAttributedString *)inText size:(CGSize)inSize
    {
    if ((self = [super init]) != NULL)
        {
        text = inText;
        size = inSize;
        }
    return self;
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
    // ### Get and set up the context...
    CGContextRef theContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(theContext);

    #if CORE_TEXT_SHOW_RUNS == 1
        {
        CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){ .length = self.normalizedText.length }, NULL, self.size, NULL);

        CGRect theFrame = { .size = theSize };
        theFrame.size.width = floor(theFrame.size.width);
        theFrame.size.height = floor(theFrame.size.height);
        
        CGContextSaveGState(theContext);
        CGContextSetStrokeColorWithColor(theContext, [UIColor greenColor].CGColor);
        CGContextSetLineWidth(theContext, 0.5);
        CGContextStrokeRect(theContext, theFrame);
        CGContextRestoreGState(theContext);
        }
    #endif /* CORE_TEXT_SHOW_RUNS == 1 */

    CGContextScaleCTM(theContext, 1.0, -1.0);
    CGContextTranslateCTM(theContext, 0, -self.size.height);

    // ### Create a frame...
    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:(CGRect){ .size = self.size }];
    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){ .length = [self.normalizedText length] }, thePath.CGPath, NULL);

    // ### Get the lines and the line origin points...
    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);
    CGPoint *theLineOrigins = malloc(sizeof(CGPoint) * theLines.count);
    CTFrameGetLineOrigins(theFrame, (CFRange){}, theLineOrigins); 

    #if CORE_TEXT_SHOW_RUNS == 1
        {
        CGContextSaveGState(theContext);
        CGContextSetStrokeColorWithColor(theContext, [UIColor redColor].CGColor);
        CGContextSetLineWidth(theContext, 0.5);
        [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins handler:^(CTRunRef inRun, CGRect inRect) {

            CGRect theStrokeRect = inRect;
            theStrokeRect.origin.x = floor(theStrokeRect.origin.x) + 0.5;
            theStrokeRect.origin.y = floor(theStrokeRect.origin.y) + 0.5;
            theStrokeRect.size.width = floor(theStrokeRect.size.width) - 1.0;
            theStrokeRect.size.height = floor(theStrokeRect.size.height) - 1.0;
            
            CGContextStrokeRect(theContext, theStrokeRect);

            }];
        CGContextRestoreGState(theContext);
        }        
    #endif /* CORE_TEXT_SHOW_RUNS == 1 */

    // ### Reset the text position (important!)
    CGContextSetTextPosition(theContext, 0, 0);

    // ### Render the text...
    CTFrameDraw(theFrame, theContext);

    // ### Reset the text position (important!)
    CGContextSetTextPosition(theContext, 0, 0);

    // ### Iterate through each line...
    [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins handler:^(CTRunRef inRun, CGRect inRect) {
        NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
        // ### If we have an image we draw it...
        UIImage *theImage = [theAttributes objectForKey:@"image"];
        if (theImage != NULL)
            {
            // We use CGContextDrawImage because it understands the CTM
            CGContextDrawImage(theContext, inRect, theImage.CGImage);
            }
        }];

    free(theLineOrigins);

    CFRelease(theFrame);

    CGContextRestoreGState(theContext);
    }

- (void)enumerateRunsForLines:(CFArrayRef)inLines lineOrigins:(CGPoint *)inLineOrigins handler:(void (^)(CTRunRef, CGRect))inHandler
    {
    CGContextRef theContext = UIGraphicsGetCurrentContext();


    // ### Iterate through each line...
    NSUInteger idx = 0;
    for (id obj in (__bridge NSArray *)inLines)
        {
        CTLineRef theLine = (__bridge CTLineRef)obj;

        // ### Get the line rect offseting it by the line origin
        CGRect theLineRect = CTLineGetImageBounds(theLine, theContext);     
        theLineRect.origin.x += inLineOrigins[idx].x;
        theLineRect.origin.y += inLineOrigins[idx].y;
        
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

            if (inHandler)
                {
                inHandler(theRun, theRunRect);
                }

            theXPosition += theWidth;
            }

        idx++;
        }
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

