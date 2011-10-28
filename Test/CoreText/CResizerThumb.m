//
//  CResizerThumb.m
//  CoreText
//
//  Created by Jonathan Wight on 10/28/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CResizerThumb.h"

#import <QuartzCore/QuartzCore.h>

@interface CResizerThumb()
@property (readwrite, nonatomic, assign) CGSize thumbSize;
@property (readwrite, nonatomic, assign) CGSize originalSize;
@property (readwrite, nonatomic, assign) CGPoint touchBeganLocation;
@end

#pragma mark -

@implementation CResizerThumb

@synthesize thumbSize;
@synthesize minimumSize;
@synthesize originalSize;
@synthesize touchBeganLocation;

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        CALayer *theLayer = [CALayer layer];
        theLayer.frame = self.bounds;
        theLayer.contents = (__bridge id)[UIImage imageNamed:@"Thumb.png"].CGImage;
        [self.layer addSublayer:theLayer];
        }
    return(self);
    }

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        CALayer *theLayer = [CALayer layer];
        theLayer.frame = self.bounds;
        theLayer.contents = (__bridge id)[UIImage imageNamed:@"Thumb.png"].CGImage;
        [self.layer addSublayer:theLayer];
        }
    return(self);
    }

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
    {
    self.originalSize = self.superview.frame.size;

    UITouch *theTouch = [touches anyObject];
    CGPoint theLocation = [theTouch locationInView:self];
    self.touchBeganLocation = [self convertPoint:theLocation toView:self.superview];
    }

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
    {
    UITouch *theTouch = [touches anyObject];
    CGPoint theLocation = [self convertPoint:[theTouch locationInView:self] toView:self.superview];

    self.superview.frame = (CGRect){
        .origin = self.superview.frame.origin,
        .size = {
            .width = MAX(self.originalSize.width + (theLocation.x - self.touchBeganLocation.x), self.minimumSize.width),
            .height = MAX(self.originalSize.height + (theLocation.y - self.touchBeganLocation.y), self.minimumSize.height),
            },
        };
    
    }
    
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
    {
    }
    
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
    {
    }

@end
