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
static void MyCTRunDelegateDeallocCallback(void *refCon);

@interface CCoreTextRenderer ()
@property (readonly, nonatomic, assign) CTFramesetterRef framesetter;
@property (readwrite, nonatomic, retain) NSAttributedString *normalizedText;
@property (readwrite, nonatomic, retain) NSMutableDictionary *prerenderersForAttributes;
@property (readwrite, nonatomic, retain) NSMutableDictionary *postRenderersForAttributes;

- (void)enumerateRunsForLines:(CFArrayRef)inLines lineOrigins:(CGPoint *)inLineOrigins handler:(void (^)(CGContextRef, CTRunRef, CGRect))inHandler;
@end

@implementation CCoreTextRenderer

@synthesize text;
@synthesize size;
@synthesize prerenderersForAttributes;
@synthesize postRenderersForAttributes;

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
            .dealloc = MyCTRunDelegateDeallocCallback,
            };
        
        [theString enumerateAttribute:kMarkupImageAttributeName inRange:(NSRange){ .length = theString.length } options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (value)
                {
                UIImage *theImage = value;
                NSValue *theSizeValue = [NSValue valueWithCGSize:theImage.size];
                
                CTRunDelegateRef theImageDelegate = CTRunDelegateCreate(&theCallbacks, (void *)(__bridge_retained CFTypeRef)theSizeValue);
                CFAttributedStringSetAttribute((__bridge CFMutableAttributedStringRef)theString, (CFRange) { .location = range.location, .length = range.length }, kCTRunDelegateAttributeName, theImageDelegate);
                CFRelease(theImageDelegate);
                }
            }];
        
        normalizedText = [theString copy];
        }
    return(normalizedText);
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
    CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){ .length = self.normalizedText.length }, NULL, inSize, NULL);
    return(theSize);
    }

- (void)draw
    {
    if (self.normalizedText.length == 0)
        {
        return;
        }
    
    // ### Get and set up the context...
    CGContextRef theContext = UIGraphicsGetCurrentContext();
    CGContextSaveGState(theContext);

    #if CORE_TEXT_SHOW_RUNS == 1
        {
        CGSize theSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){ .length = self.normalizedText.length }, NULL, self.size, NULL);

        CGRect theFrame = { .size = theSize };
        
        CGContextSaveGState(theContext);
        CGContextSetStrokeColorWithColor(theContext, [[UIColor greenColor] colorWithAlphaComponent:0.5].CGColor);
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
        CGContextSetStrokeColorWithColor(theContext, [[UIColor redColor] colorWithAlphaComponent:0.5].CGColor);
        CGContextSetLineWidth(theContext, 0.5);
        [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins handler:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            CGRect theStrokeRect = inRect;
            CGContextStrokeRect(theContext, theStrokeRect);
            }];
        CGContextRestoreGState(theContext);
        }        
    #endif /* CORE_TEXT_SHOW_RUNS == 1 */

    // ### If we have any pre-render blocks we enumerate over the runs and fire the blocks if the attributes match...
    if (self.prerenderersForAttributes.count > 0)
        {
        [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins handler:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            [self.prerenderersForAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([theAttributes objectForKey:key])
                    {
                    void (^theBlock)(CGContextRef, CTRunRef, CGRect) = obj;
                    theBlock(theContext, inRun, inRect);
                    }
                }];
            }];
        }

    // ### Reset the text position (important!)
    CGContextSetTextPosition(theContext, 0, 0);

    // ### Render the text...
    CTFrameDraw(theFrame, theContext);

    // ### Reset the text position (important!)
    CGContextSetTextPosition(theContext, 0, 0);

    // ### If we have any pre-render blocks we enumerate over the runs and fire the blocks if the attributes match...
    if (self.postRenderersForAttributes.count > 0)
        {
        [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins handler:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            [self.postRenderersForAttributes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([theAttributes objectForKey:key])
                    {
                    void (^theBlock)(CGContextRef, CTRunRef, CGRect) = obj;
                    theBlock(theContext, inRun, inRect);
                    }
                }];
            }];
        }

    // ### Iterate through each line...
    [self enumerateRunsForLines:(__bridge CFArrayRef)theLines lineOrigins:theLineOrigins handler:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
        NSDictionary *theAttributes = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
        // ### If we have an image we draw it...
        UIImage *theImage = [theAttributes objectForKey:kMarkupImageAttributeName];
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

- (void)enumerateRunsForLines:(CFArrayRef)inLines lineOrigins:(CGPoint *)inLineOrigins handler:(void (^)(CGContextRef, CTRunRef, CGRect))inHandler
    {
    CGContextRef theContext = UIGraphicsGetCurrentContext();


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
            CGFloat theWidth = CTRunGetTypographicBounds(theRun, (CFRange){}, &theAscent, &theDescent, &theLeading);
            CGRect theRunRect = {
                .origin = { theLineOrigin.x + theXPosition, theLineOrigin.y },
                .size = { theWidth, theAscent + theDescent },
                };

            if (inHandler)
                {
                inHandler(theContext, theRun, theRunRect);
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
    NSValue *theValue = (__bridge NSValue *)refCon;
    CGSize theSize = [theValue CGSizeValue];
    return(theSize.height);
    }

static CGFloat MyCTRunDelegateGetDescentCallback(void *refCon)
    {
    return(0.0);
    }

static CGFloat MyCTRunDelegateGetWidthCallback(void *refCon)
    {
    NSValue *theValue = (__bridge NSValue *)refCon;
    CGSize theSize = [theValue CGSizeValue];
    return(theSize.width);
    }

static void MyCTRunDelegateDeallocCallback(void *refCon)
    {
    CFRelease(refCon);

    }

