//
//  CCoreTextLabel.m
//  CoreText
//
//  Created by Jonathan Wight on 07/12/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

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

//    NSLog(@"###################");

    NSArray *theLines = (__bridge NSArray *)CTFrameGetLines(theFrame);
    
    __block CGPoint theLastLineOrigin = (CGPoint){ 0, CGFLOAT_MAX };
    
    [theLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {


        CGPoint theLineOrigin;
        CTFrameGetLineOrigins(theFrame, CFRangeMake(idx, 1), &theLineOrigin);

//        NSLog(@"%d %g %g %g", idx, theLocation.y, theLineOrigin.y, theLastLineOrigin.y);

        
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

