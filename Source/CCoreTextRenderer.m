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
#import "CCoreTextAttachment.h"

//#define CORE_TEXT_SHOW_RUNS 1

@interface CCoreTextRenderer ()
@property (readonly, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, retain) NSMutableDictionary *prerenderersForAttributes;
@property (readwrite, nonatomic, retain) NSMutableDictionary *postRenderersForAttributes;

- (void)enumerateRunsForLines:(CFArrayRef)inLines lineOrigins:(CGPoint *)inLineOrigins context:(CGContextRef)inContext handler:(void (^)(CGContextRef, CTRunRef, CGRect))inHandler;
@end

@implementation CCoreTextRenderer

@synthesize text;
@synthesize size;
@synthesize prerenderersForAttributes;
@synthesize postRenderersForAttributes;

@synthesize framesetter;

+ (CGSize)sizeForString:(NSAttributedString *)inString lineBreakMode:(UILineBreakMode)inLineBreakMode thatFits:(CGSize)size;
    {
    #warning TODO -- this doesn't support images or insets yet...
    CTFramesetterRef theFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)inString);
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(theFramesetter, (CFRange){}, NULL, size, NULL);
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
            framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.text);
            }
        }
    return(framesetter);
    }

- (void)addPrerendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;
    {
    if (self.prerenderersForAttributes == NULL)
        {
        self.prerenderersForAttributes = [NSMutableDictionary dictionary];
        }
        
    [self.prerenderersForAttributes setObject:[inBlock copy] forKey:inKey];
    }

- (void)addPostRendererBlock:(void (^)(CGContextRef, CTRunRef, CGRect))inBlock forAttributeKey:(NSString *)inKey;
    {
    if (self.postRenderersForAttributes == NULL)
        {
        self.postRenderersForAttributes = [NSMutableDictionary dictionary];
        }
        
    [self.postRenderersForAttributes setObject:[inBlock copy] forKey:inKey];
    }

- (CGSize)sizeThatFits:(CGSize)inSize
    {
    CFRange theFitRange;
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){}, NULL, inSize, &theFitRange);

    theSize.width = MIN(theSize.width, inSize.width);
    theSize.height = MIN(theSize.height, inSize.height);

    return(theSize);
    }

- (void)drawInContext:(CGContextRef)inContext
    {
    if (self.text.length == 0)
        {
        return;
        }
    
    // ### Get and set up the context...
    CGContextSaveGState(inContext);

    #if CORE_TEXT_SHOW_RUNS == 1
        {
        CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){}, NULL, self.size, NULL);

        CGRect theFrame = { .size = theSize };
        
        CGContextSaveGState(inContext);
        CGContextSetStrokeColorWithColor(inContext, [[UIColor greenColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextSetLineWidth(inContext, 0.5);
        CGContextStrokeRect(inContext, theFrame);
        CGContextRestoreGState(inContext);
        }
    #endif /* CORE_TEXT_SHOW_RUNS == 1 */

    CGContextScaleCTM(inContext, 1.0, -1.0);
    CGContextTranslateCTM(inContext, 0, -self.size.height);

    // ### Create a frame...
    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:(CGRect){ .size = self.size }];
    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){}, thePath.CGPath, NULL);

    // ### Get the lines and the line origin points...
    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);
    CGPoint *theLineOrigins = malloc(sizeof(CGPoint) * theLines.count);
    CTFrameGetLineOrigins(theFrame, (CFRange){}, theLineOrigins); 

    #if CORE_TEXT_SHOW_RUNS == 1
        {
        CGContextSaveGState(inContext);
        CGContextSetStrokeColorWithColor(inContext, [[UIColor redColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextSetLineWidth(inContext, 0.5);
        [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins context:inContext handler:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            CGRect theStrokeRect = inRect;
            CGContextStrokeRect(inContext, theStrokeRect);
            }];
        CGContextRestoreGState(inContext);
        }        
    #endif /* CORE_TEXT_SHOW_RUNS == 1 */

    // ### If we have any pre-render blocks we enumerate over the runs and fire the blocks if the attributes match...
    if (self.prerenderersForAttributes.count > 0)
        {
        [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins context:inContext handler:^(CGContextRef inContext2, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            [self.prerenderersForAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([theAttributes objectForKey:key])
                    {
                    void (^theBlock)(CGContextRef, CTRunRef, CGRect) = obj;
                    theBlock(inContext2, inRun, inRect);
                    }
                }];
            }];
        }

    // ### Reset the text position (important!)
    CGContextSetTextPosition(inContext, 0, 0);

    // ### Render the text...
    CTFrameDraw(theFrame, inContext);

    // ### Reset the text position (important!)
    CGContextSetTextPosition(inContext, 0, 0);

    // ### If we have any pre-render blocks we enumerate over the runs and fire the blocks if the attributes match...
    if (self.postRenderersForAttributes.count > 0)
        {
        [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins context:inContext handler:^(CGContextRef inContext2, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            [self.postRenderersForAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([theAttributes objectForKey:key])
                    {
                    void (^theBlock)(CGContextRef, CTRunRef, CGRect) = obj;
                    theBlock(inContext2, inRun, inRect);
                    }
                }];
            }];
        }

    CGContextRestoreGState(inContext);

    // ### Now that the CTM is restored. Iterate through each line and render any attachments.
    [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins context:inContext handler:^(CGContextRef inContext2, CTRunRef inRun, CGRect inRect) {
        NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
        // ### If we have an image we draw it...
        CCoreTextAttachment *theAttachment = [theAttributes objectForKey:kMarkupAttachmentAttributeName];
        if (theAttachment != NULL)
            {
            inRect.origin.y *= -1;
            inRect.origin.y += self.size.height - inRect.size.height;

            theAttachment.renderer(theAttachment, inContext2, inRect);
            }
        }];

    free(theLineOrigins);

    CFRelease(theFrame);
    }

- (void)enumerateRunsForLines:(CFArrayRef)inLines lineOrigins:(CGPoint *)inLineOrigins context:(CGContextRef)inContext handler:(void (^)(CGContextRef, CTRunRef, CGRect))inHandler
    {
    // ### Iterate through each line...
    NSUInteger idx = 0;
    for (id obj in (__bridge NSArray *)inLines)
        {
        CTLineRef theLine = (__bridge CTLineRef)obj;

        // ### Get the line rect offseting it by the line origin
        const CGPoint theLineOrigin = inLineOrigins[idx];
        
        // ### Iterate each run... Keeping track of our X position...
        CGFloat theXPosition = 0;
        NSArray *theRuns = (__bridge NSArray *)CTLineGetGlyphRuns(theLine);
        for (id oneRun in theRuns)
            {
            CTRunRef theRun = (__bridge CTRunRef)oneRun;
            
            // ### Get the ascent, descent, leading, width and produce a rect for the run...
            CGFloat theAscent, theDescent, theLeading;
            double theWidth = CTRunGetTypographicBounds(theRun, (CFRange){}, &theAscent, &theDescent, &theLeading);
            CGRect theRunRect = {
                .origin = { theLineOrigin.x + theXPosition, theLineOrigin.y },
                .size = { (CGFloat)theWidth, theAscent + theDescent },
                };

            if (inHandler)
                {
                inHandler(inContext, theRun, theRunRect);
                }

            theXPosition += theWidth;
            }

        idx++;
        }
    }

- (NSUInteger)indexAtPoint:(CGPoint)inPoint
    {
    inPoint.y *= -1;
    inPoint.y += self.size.height;

    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:(CGRect){ .size = self.size }];

    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){}, thePath.CGPath, NULL);

    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);

    __block CGPoint theLastLineOrigin = (CGPoint){ 0, CGFLOAT_MAX };
    __block CFIndex theIndex = NSNotFound;

    [theLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {

        CGPoint theLineOrigin;
        CTFrameGetLineOrigins(theFrame, CFRangeMake(idx, 1), &theLineOrigin);

        if (inPoint.y > theLineOrigin.y && inPoint.y < theLastLineOrigin.y)
            {
            CTLineRef theLine = (__bridge CTLineRef)obj;

            theIndex = CTLineGetStringIndexForPosition(theLine, (CGPoint){ .x = inPoint.x - theLineOrigin.x, inPoint.y - theLineOrigin.y });
            if (theIndex != NSNotFound && (NSUInteger)theIndex < self.text.length)
                {
                *stop = YES;
                }
            }
        theLastLineOrigin = theLineOrigin;
        }];
        
    return(theIndex);
    }

- (NSDictionary *)attributesAtPoint:(CGPoint)inPoint
    {
    NSUInteger theIndex = [self indexAtPoint:inPoint];
    NSDictionary *theAttributes = [self.text attributesAtIndex:theIndex effectiveRange:NULL];
    return(theAttributes);
    }
    
- (NSArray *)rectsForRange:(NSRange)inRange
    {
    NSMutableArray *theRects = [NSMutableArray array];
    
    // ### Create a frame...
    UIBezierPath *thePath = [UIBezierPath bezierPathWithRect:(CGRect){ .size = self.size }];
    CTFrameRef theFrame = CTFramesetterCreateFrame(self.framesetter, (CFRange){}, thePath.CGPath, NULL);

    // ### Get the lines and the line origin points...
    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);
    CGPoint *theLineOrigins = malloc(sizeof(CGPoint) * theLines.count);
    CTFrameGetLineOrigins(theFrame, (CFRange){}, theLineOrigins); 
    
    [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins context:NULL handler:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
    
        CFRange theRunRange = CTRunGetStringRange(inRun);
        if (theRunRange.location >= (CFIndex)inRange.location && theRunRange.location <= (CFIndex)inRange.location + (CFIndex)inRange.length)
            {
            inRect.origin.y *= -1;
            inRect.origin.y += self.size.height -  inRect.size.height;
            
            [theRects addObject:[NSValue valueWithCGRect:inRect]];
            }
        }];

    CFRelease(theFrame);
    free(theLineOrigins);

    // TODO: We need to coelesce ajacent rectangles here...
//    NSMutableArray *theCoelescedRects = [NSMutableArray array];
    
    return(theRects);
    }

@end
