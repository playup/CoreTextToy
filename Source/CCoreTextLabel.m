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

#import "CMarkupValueTransformer.h"
#import "CCoreTextRenderer.h"
#import "UIFont_CoreTextExtensions.h"
#import "UIColor+Hex.h"

@interface CCoreTextLabel ()
@property (readwrite, nonatomic, retain) CCoreTextRenderer *renderer;
@property (readwrite, nonatomic, retain) UITapGestureRecognizer *tapRecognizer;

+ (CTParagraphStyleRef)createParagraphStyleForAttributes:(NSDictionary *)inAttributes alignment:(CTTextAlignment)inTextAlignment lineBreakMode:(CTLineBreakMode)inLineBreakMode;
+ (NSAttributedString *)normalizeString:(NSAttributedString *)inString font:(UIFont *)inBaseFont textColor:(UIColor *)inTextColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset shadowBlurRadius:(CGFloat)inShadowBlurRadius alignment:(UITextAlignment)inTextAlignment lineBreakMode:(UILineBreakMode)inLineBreakMode;
- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer;
@end

@implementation CCoreTextLabel

@synthesize text;
@synthesize insets;
@synthesize URLHandler;
@synthesize font;
@synthesize textColor;
@synthesize shadowColor;
@synthesize shadowOffset;
@synthesize shadowBlurRadius;
@synthesize textAlignment;
@synthesize lineBreakMode;

@synthesize renderer;
@synthesize tapRecognizer;

+ (CGSize)sizeForString:(NSAttributedString *)inString font:(UIFont *)inBaseFont alignment:(UITextAlignment)inTextAlignment lineBreakMode:(UILineBreakMode)inLineBreakMode contentInsets:(UIEdgeInsets)inContentInsets thatFits:(CGSize)inSize 
    {
    NSAttributedString *theNormalizedText = [self normalizeString:inString font:inBaseFont textColor:[UIColor blackColor] shadowColor:NULL shadowOffset:(CGSize){ 0, -1 } shadowBlurRadius:0.0 alignment:inTextAlignment lineBreakMode:inLineBreakMode];
    
    CGRect theRect = (CGRect){ .size = inSize };
    theRect = UIEdgeInsetsInsetRect(theRect, inContentInsets);
    inSize = theRect.size; 
    
    CGSize theSize = [CCoreTextRenderer sizeForString:theNormalizedText thatFits:inSize];
    return(theSize);
    }

#pragma mark -

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;
        self.backgroundColor = [UIColor whiteColor];

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
        self.accessibilityLabel = @"";

        font = [UIFont systemFontOfSize:17];
        textColor = [UIColor blackColor];
        shadowColor = NULL;
        shadowOffset = (CGSize){ 0.0, -1.0 };
        shadowBlurRadius = 0.0;
        textAlignment = UITextAlignmentLeft;
        lineBreakMode = UILineBreakModeTailTruncation;
        }
    return(self);
    }

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;

        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitStaticText;
        self.accessibilityLabel = @"";

        font = [UIFont systemFontOfSize:17];
        textColor = [UIColor blackColor];
        shadowColor = NULL;
        shadowOffset = (CGSize){ 0.0, -1.0 };
        shadowBlurRadius = 0.0;
        textAlignment = UITextAlignmentLeft;
        lineBreakMode = UILineBreakModeTailTruncation;
        }
    return(self);
    }

#pragma mark -

- (void)setFrame:(CGRect)inFrame
    {
    [super setFrame:inFrame];

    self.renderer = NULL;
    [self setNeedsDisplay];
    }

#pragma mark -

- (void)setTextAlignment:(UITextAlignment)inTextAlignment
    {
    if (textAlignment != inTextAlignment)
        {
        textAlignment = inTextAlignment;
        
        self.renderer = NULL;
        [self setNeedsDisplay];
        }
    }
    
- (void)setLineBreakMode:(UILineBreakMode)inLineBreakMode
    {
    if (lineBreakMode != inLineBreakMode)
        {
        lineBreakMode = inLineBreakMode;
        
        self.renderer = NULL;
        [self setNeedsDisplay];
        }
    }

- (void)setText:(NSAttributedString *)inText
    {
    if (text != inText)
        {
        text = inText;
        
        self.accessibilityLabel = inText.string;
        
        self.renderer = NULL;
        [self setNeedsDisplay];
        }
    }

- (void)setInsets:(UIEdgeInsets)inInsets
    {
    insets = inInsets;

    self.renderer = NULL;
    [self setNeedsDisplay];
    }

- (void)setURLHandler:(void (^)(NSURL *))inURLHandler
    {
    if (URLHandler != inURLHandler)
        {
        URLHandler = [inURLHandler copy];
        //
        if (URLHandler != NULL)
            {
            self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
            [self addGestureRecognizer:self.tapRecognizer];
            }
        else
            {
            [self removeGestureRecognizer:self.tapRecognizer];
            self.tapRecognizer = NULL;
            }
        }
    }

#pragma mark -

- (CCoreTextRenderer *)renderer
    {
    if (renderer == NULL)
        {
        NSAttributedString *theNormalizedText = [[self class] normalizeString:self.text font:self.font textColor:self.textColor shadowColor:self.shadowColor shadowOffset:self.shadowOffset shadowBlurRadius:self.shadowBlurRadius alignment:self.textAlignment lineBreakMode:self.lineBreakMode];

        CGRect theBounds = self.bounds;
        theBounds = UIEdgeInsetsInsetRect(theBounds, self.insets);
        
        renderer = [[CCoreTextRenderer alloc] initWithText:theNormalizedText size:theBounds.size];

        [renderer addPrerendererBlock:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes2 = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            CGColorRef theColor2 = (__bridge CGColorRef)[theAttributes2 objectForKey:kMarkupBackgroundColorAttributeName];
            CGContextSetFillColorWithColor(inContext, theColor2);
            CGContextFillRect(inContext, inRect);
            } forAttributeKey:kMarkupBackgroundColorAttributeName];

        [renderer addPostRendererBlock:^(CGContextRef inContext, CTRunRef inRun, CGRect inRect) {
            NSDictionary *theAttributes2 = (__bridge NSDictionary *)CTRunGetAttributes(inRun);
            
            CTFontRef theFont = (__bridge CTFontRef)[theAttributes2 objectForKey:(__bridge NSString *)kCTFontAttributeName];
            
            CGFloat theXHeight = CTFontGetXHeight(theFont);
            
            CGColorRef theColor2 = (__bridge CGColorRef)[theAttributes2 objectForKey:kMarkupStrikeColorAttributeName];
            CGContextSetStrokeColorWithColor(inContext, theColor2);
            const CGFloat Y = CGRectGetMidY(inRect) - theXHeight * 0.5f;
            
            CGContextMoveToPoint(inContext, CGRectGetMinX(inRect), Y);
            CGContextAddLineToPoint(inContext, CGRectGetMaxX(inRect), Y);
            CGContextStrokePath(inContext);
            } forAttributeKey:kMarkupStrikeColorAttributeName];
        }
    return(renderer);
    }

#pragma mark -

- (CGSize)sizeThatFits:(CGSize)size
    {
    CGSize theSize = size;
    theSize.width -= self.insets.left + self.insets.right;
    theSize.height -= self.insets.top + self.insets.bottom;
    
    theSize = [self.renderer sizeThatFits:theSize];
    theSize.width += self.insets.left + self.insets.right;
    theSize.height += self.insets.top + self.insets.bottom;
    
    return(theSize);
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
    
    [self.renderer drawInContext:theContext];

    CGContextRestoreGState(theContext);    

// If you wanted to dump the rendered images to disk so you can make sure it is rendering correctly here's how you could do it...
//    #if 1
//    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
//    theContext = UIGraphicsGetCurrentContext();
//    [self.renderer drawInContext:theContext];
//    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    [UIImagePNGRepresentation(theImage) writeToFile:[NSString stringWithFormat:@"/Users/schwa/Desktop/%d.png", [theImage hash]] atomically:NO];
//    #endif
    }

#pragma mark -

+ (CTParagraphStyleRef)createParagraphStyleForAttributes:(NSDictionary *)inAttributes alignment:(CTTextAlignment)inTextAlignment lineBreakMode:(CTLineBreakMode)inLineBreakMode
    {
    CGFloat theFirstLineHeadIndent;
    CGFloat theHeadIndent;
    CGFloat theTailIndent;
    CFArrayRef theTabStops;
    CGFloat theDefaultTabInterval;
    CGFloat theLineHeightMultiple;
    CGFloat theMaximumLineHeight;
    CGFloat theMinimumLineHeight;
    CGFloat theLineSpacing;
    CGFloat theParagraphSpacing;
    CGFloat theParagraphSpacingBefore;
    CTWritingDirection theBaseWritingDirection; 

    BOOL createdCurrentStyle = NO;
    CTParagraphStyleRef currentParagraphStyle = (__bridge CTParagraphStyleRef)[inAttributes objectForKey:(__bridge NSString *)kCTParagraphStyleAttributeName];
    if (currentParagraphStyle == NULL)
        {
        // Create default style
        currentParagraphStyle = CTParagraphStyleCreate(NULL, 0);
        createdCurrentStyle = YES;
        }
    
    // Grab all but the alignment and line break mode
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(theFirstLineHeadIndent), &theFirstLineHeadIndent);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierHeadIndent, sizeof(theHeadIndent), &theHeadIndent);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierTailIndent, sizeof(theTailIndent), &theTailIndent);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierTabStops, sizeof(theTabStops), &theTabStops);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierDefaultTabInterval, sizeof(theDefaultTabInterval), &theDefaultTabInterval);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(theLineHeightMultiple), &theLineHeightMultiple);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(theMaximumLineHeight), &theMaximumLineHeight);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(theMinimumLineHeight), &theMinimumLineHeight);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierLineSpacing, sizeof(theLineSpacing), &theLineSpacing);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacing, sizeof(theParagraphSpacing), &theParagraphSpacing);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(theParagraphSpacingBefore), &theParagraphSpacingBefore);
    CTParagraphStyleGetValueForSpecifier(currentParagraphStyle, kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(theBaseWritingDirection), &theBaseWritingDirection);
    
    if (createdCurrentStyle)
        {
        CFRelease(currentParagraphStyle);
        }
    
    CTParagraphStyleSetting newSettings[] = {
        { .spec = kCTParagraphStyleSpecifierAlignment, .valueSize = sizeof(inTextAlignment), .value = &inTextAlignment, },
        { .spec = kCTParagraphStyleSpecifierFirstLineHeadIndent, .valueSize = sizeof(theFirstLineHeadIndent), .value = &theFirstLineHeadIndent, },
        { .spec = kCTParagraphStyleSpecifierHeadIndent, .valueSize = sizeof(theHeadIndent), .value = &theHeadIndent, },
        { .spec = kCTParagraphStyleSpecifierTailIndent, .valueSize = sizeof(theTailIndent), .value = &theTailIndent, },
        { .spec = kCTParagraphStyleSpecifierTabStops, .valueSize = sizeof(theTabStops), .value = &theTabStops, },
        { .spec = kCTParagraphStyleSpecifierDefaultTabInterval, .valueSize = sizeof(theDefaultTabInterval), .value = &theDefaultTabInterval, },
        { .spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(inLineBreakMode), .value = &inLineBreakMode, },
        { .spec = kCTParagraphStyleSpecifierLineHeightMultiple, .valueSize = sizeof(theLineHeightMultiple), .value = &theLineHeightMultiple, },
        { .spec = kCTParagraphStyleSpecifierMaximumLineHeight, .valueSize = sizeof(theMaximumLineHeight), .value = &theMaximumLineHeight, },
        { .spec = kCTParagraphStyleSpecifierMinimumLineHeight, .valueSize = sizeof(theMinimumLineHeight), .value = &theMinimumLineHeight, },
        { .spec = kCTParagraphStyleSpecifierLineSpacing, .valueSize = sizeof(theLineSpacing), .value = &theLineSpacing, },
        { .spec = kCTParagraphStyleSpecifierParagraphSpacing, .valueSize = sizeof(theParagraphSpacing), .value = &theParagraphSpacing, },
        { .spec = kCTParagraphStyleSpecifierParagraphSpacingBefore, .valueSize = sizeof(theParagraphSpacingBefore), .value = &theParagraphSpacingBefore, },
        { .spec = kCTParagraphStyleSpecifierBaseWritingDirection, .valueSize = sizeof(theBaseWritingDirection), .value = &theBaseWritingDirection, },
        };
    return CTParagraphStyleCreate( newSettings, sizeof(newSettings)/sizeof(CTParagraphStyleSetting) );
    }

+ (NSAttributedString *)normalizeString:(NSAttributedString *)inString font:(UIFont *)inBaseFont textColor:(UIColor *)inTextColor shadowColor:(UIColor *)inShadowColor shadowOffset:(CGSize)inShadowOffset shadowBlurRadius:(CGFloat)inShadowBlurRadius alignment:(UITextAlignment)inTextAlignment lineBreakMode:(UILineBreakMode)inLineBreakMode
    {
    NSMutableAttributedString *theMutableText = [[CMarkupValueTransformer normalizedAttributedStringForAttributedString:inString baseFont:inBaseFont] mutableCopy];

    UIFont *theFont = inBaseFont ?: [UIFont systemFontOfSize:17.0];
    UIColor *theColor = inTextColor ?: [UIColor blackColor];
    
    
    [theMutableText enumerateAttributesInRange:(NSRange){ .length = theMutableText.length } options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        if ([attrs objectForKey:(__bridge NSString *)kCTFontAttributeName] == NULL)
            {
            [theMutableText addAttribute:(__bridge NSString *)kCTFontAttributeName value:(__bridge id)theFont.CTFont range:range];
            }
        if ([attrs objectForKey:(__bridge NSString *)kCTForegroundColorAttributeName] == NULL)
            {
            [theMutableText addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName value:(__bridge id)theColor.CGColor range:range];
            }

        // [DW]
        if ([attrs objectForKey:kMarkupTextColorAttributeName] != NULL)
            {
            NSString *theColorStr = [attrs objectForKey:kMarkupTextColorAttributeName];
            if(theColorStr)
                [theMutableText addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName value:(__bridge id)[UIColor colorWithHexString:theColorStr].CGColor range:range];
            }
        }];

    if (inShadowColor != NULL)
        {
        NSMutableDictionary *theShadowAttributes = [NSMutableDictionary dictionary];
        [theShadowAttributes setObject:(__bridge id)inShadowColor.CGColor forKey:kShadowColorAttributeName];
        [theShadowAttributes setObject:[NSValue valueWithCGSize:inShadowOffset] forKey:kShadowOffsetAttributeName];
        [theShadowAttributes setObject:[NSNumber numberWithFloat:inShadowBlurRadius] forKey:kShadowBlurRadiusAttributeName];

        [theMutableText addAttributes:theShadowAttributes range:(NSRange){ .length = [theMutableText length] }];
        }
    
    CTTextAlignment theTextAlignment;
    switch (inTextAlignment)
        {
        case UITextAlignmentLeft:
            theTextAlignment = kCTLeftTextAlignment;
            break;
        case UITextAlignmentCenter:
            theTextAlignment = kCTCenterTextAlignment;
            break;
        case UITextAlignmentRight:
            theTextAlignment = kCTRightTextAlignment;
            break;
        }
    
    // UILineBreakMode maps 1:1 to CTLineBreakMode
    CTLineBreakMode theLineBreakMode = inLineBreakMode;

    [theMutableText enumerateAttributesInRange:(NSRange){ .length = theMutableText.length } options:0 usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        CTParagraphStyleRef newParagraphStyle = [self createParagraphStyleForAttributes:attrs alignment:theTextAlignment lineBreakMode:theLineBreakMode];
        [theMutableText addAttribute:(__bridge NSString *)kCTParagraphStyleAttributeName value:(__bridge id)newParagraphStyle range:range];
        CFRelease(newParagraphStyle);
        }];

    return(theMutableText);
    }

#pragma mark -

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer
    {
    CGPoint theLocation = [inGestureRecognizer locationInView:self];
    theLocation.x -= self.insets.left;
    theLocation.y -= self.insets.top;

    NSDictionary *theAttributes = [self.renderer attributesAtPoint:theLocation];
    NSURL *theLink = [theAttributes objectForKey:kMarkupLinkAttributeName];
    if (theLink != NULL)
        {
        if (self.URLHandler != NULL)
            {
            self.URLHandler(theLink);
            }
        }
    }
    
#pragma mark -

- (NSArray *)rectsForRange:(NSRange)inRange;
    {
    return([self.renderer rectsForRange:inRange]);
    }

@end
