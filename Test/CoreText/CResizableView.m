//
//  CResizableView.m
//  CoreText
//
//  Created by Jonathan Wight on 10/23/11.
//  Copyright (c) 2011 toxicsoftware.com. All rights reserved.
//

#import "CResizableView.h"

#import <QuartzCore/QuartzCore.h>

@interface CResizableView ()
@property (readwrite, nonatomic, assign) CGSize thumbSize;
@property (readwrite, nonatomic, assign) CGSize minimumSize;
@property (readwrite, nonatomic, assign) BOOL resizing;
@property (readwrite, nonatomic, assign) CGSize originalSize;
@property (readwrite, nonatomic, assign) CGPoint touchBeganLocation;
@end

@implementation CResizableView

@synthesize thumbSize;
@synthesize minimumSize;
@synthesize resizing;
@synthesize originalSize;
@synthesize touchBeganLocation;

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor purpleColor].CGColor;
                
        thumbSize = (CGSize){ 32, 32 };
        minimumSize = CGSizeZero;
        }
    return(self);
    }

- (CGRect)thumbRect
    {
    return(CGRect){
        .origin = {
            .x = CGRectGetMaxX(self.bounds) - self.thumbSize.width, 
            .y = CGRectGetMaxY(self.bounds) - self.thumbSize.height,
            },
        .size = self.thumbSize,
        };
    }

- (void)drawRect:(CGRect)rect
    {
    CGContextStrokeRect(UIGraphicsGetCurrentContext(), self.thumbRect);
    }

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
    {
    UITouch *theTouch = [touches anyObject];
    CGPoint theLocation = [theTouch locationInView:self];
    if (CGRectContainsPoint(self.thumbRect, theLocation))
        {
        self.resizing = YES;
        self.originalSize = self.frame.size;
        self.touchBeganLocation = theLocation;
        }
    }

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
    {
    if (self.resizing == NO)
        {
        return;
        }
        
    UITouch *theTouch = [touches anyObject];
    CGPoint theLocation = [theTouch locationInView:self];

    self.frame = (CGRect){
        .origin = self.frame.origin,
        .size = {
            .width = MAX(self.originalSize.width + (theLocation.x - self.touchBeganLocation.x), self.minimumSize.width),
            .height = MAX(self.originalSize.height + (theLocation.y - self.touchBeganLocation.y), self.minimumSize.height),
            },
        };
    
    }
    
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
    {
    self.resizing = NO;
    }
    
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
    {
    self.resizing = NO;
    }



@end
